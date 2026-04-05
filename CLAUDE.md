# AWS Free Tier Terraform Project

Provisions all major AWS free-tier services using direct `resource` blocks (no terraform-aws-modules wrappers).
Target: AWS legacy free tier (12-month + always-free services) in `us-east-1`.
Covers all 5 credit-earning activities for new accounts (+$100 in credits).

## Architecture

```
                    ┌──────────────────────── AWS Account (us-east-1) ───────────────────────────┐
                    │                                                                              │
                    │  ┌──────────────────────── VPC 10.0.0.0/16 ──────────────────────────────┐  │
                    │  │                                                                        │  │
                    │  │  ┌── Public Subnet ─┐  ┌── Public Subnet ─┐                          │  │
                    │  │  │  10.0.1.0/24     │  │  10.0.2.0/24     │                          │  │
                    │  │  │  AZ-a            │  │  AZ-b            │                          │  │
  SSH ────────────► │  │  │ ┌─────────────┐  │  │                  │                          │  │
  HTTP ───────────► │  │  │ │ EC2 t4g     │  │  │                  │                          │  │
  HTTPS ──────────► │  │  │ │ nginx/psql  │  │  │                  │                          │  │
                    │  │  │ │ 30GB gp3    │  │  │                  │                          │  │
                    │  │  │ └──────┬──────┘  │  │                  │                          │  │
                    │  │  └────────┼─────────┘  └──────────────────┘                          │  │
                    │  │          │ :5432 + :6379                                              │  │
                    │  │  ┌── Private Subnet ┐  ┌── Private Subnet ─┐                         │  │
                    │  │  │  10.0.101.0/24   │  │  10.0.102.0/24    │                         │  │
                    │  │  │ ┌─────────────┐  │  │                   │                         │  │
                    │  │  │ │ RDS Postgres│  │  │                   │                         │  │
                    │  │  │ │ db.t4g.micro│  │  │                   │                         │  │
                    │  │  │ │ 20GB gp2    │  │  │                   │                         │  │
                    │  │  │ ├─────────────┤  │  │                   │                         │  │
                    │  │  │ │ ElastiCache │  │  │                   │                         │  │
                    │  │  │ │ Redis 7.1   │  │  │                   │                         │  │
                    │  │  │ │ t3.micro    │  │  │                   │                         │  │
                    │  │  │ └─────────────┘  │  │                   │                         │  │
                    │  │  └──────────────────┘  └───────────────────┘                         │  │
                    │  │              NO NAT GATEWAY (saves ~$32/month)                       │  │
                    │  └────────────────────────────────────────────────────────────────────── ┘  │
                    │                                                                              │
                    │  ┌──────────┐  ┌──────────────────┐  ┌───────────────────────────────────┐ │
                    │  │ S3 Bucket│  │ CloudFront (OAC) │  │ DynamoDB                          │ │
                    │  │ 5GB free │  │ 1TB + 10M req/mo │  │ 25 RCU/WCU PROVISIONED            │ │
                    │  │ AES256   │  │ PriceClass_100   │  │ pk(S) + sk(S) + TTL               │ │
                    │  └──────────┘  └──────────────────┘  └───────────────────────────────────┘ │
                    │                                                                              │
                    │  ┌──────────────────────────────────────────────────────────────────────┐   │
                    │  │ Lambda (Node 22.x, 128MB)                                            │   │
                    │  │  ├── Function URL (public HTTPS — credit activity)                  │   │
                    │  │  ├── API Gateway HTTP API → Lambda                                  │   │
                    │  │  ├── EventBridge Scheduler → Lambda (rate: 5min)                    │   │
                    │  │  └── Step Functions Standard Workflow → Lambda → Succeed            │   │
                    │  └──────────────────────────────────────────────────────────────────────┘   │
                    │                                                                              │
                    │  ┌────────────────────┐  ┌─────────────────────────────────────────────┐   │
                    │  │ SQS Queue + DLQ    │  │ SNS Topic + email subscription              │   │
                    │  │ 1M req/mo          │  │ ← CloudWatch alarms wire here               │   │
                    │  │ maxReceive = 3     │  │ ← Budgets alerts wire here                  │   │
                    │  └────────────────────┘  └─────────────────────────────────────────────┘   │
                    │                                                                              │
                    │  ┌─────────────────────────┐  ┌──────────────────────────────────────────┐ │
                    │  │ Cognito User Pool        │  │ CloudWatch                               │ │
                    │  │ 10K MAUs (always free)   │  │  Log groups: app, lambda, bedrock (7d)  │ │
                    │  │ + hosted domain          │  │  Alarms: EC2 CPU + RDS storage → SNS    │ │
                    │  └─────────────────────────┘  └──────────────────────────────────────────┘ │
                    │                                                                              │
                    │  ┌──────────────────┐  ┌─────────────────────────────────────────────────┐ │
                    │  │ Budgets (free)   │  │ Bedrock logging config                          │ │
                    │  │ zero-spend alert │  │  (inference NOT free — enable in console)       │ │
                    │  └──────────────────┘  └─────────────────────────────────────────────────┘ │
                    │                                                                              │
                    │  ┌──────────────────────────────────────────────────────────────────────┐   │
                    │  │ IAM: EC2 role + Lambda role + Scheduler role + SFN role              │   │
                    │  │      Bedrock logging role + S3 access policy + instance profile      │   │
                    │  └──────────────────────────────────────────────────────────────────────┘   │
                    └──────────────────────────────────────────────────────────────────────────────┘
```

## Credit-Earning Activities ($20 each = $100 extra)

| Service    | What Terraform Provisions                  | Console Step Required?                      |
|------------|--------------------------------------------|---------------------------------------------|
| EC2        | `aws_instance.web` (t4g.micro)             | None — just run `terraform apply`           |
| RDS        | `aws_db_instance.postgres` (db.t4g.micro)  | None — just run `terraform apply`           |
| Lambda     | `aws_lambda_function_url.handler`          | None — Function URL is the trigger          |
| Bedrock    | `aws_bedrock_model_invocation_logging_configuration` | Enable model access + submit 1 prompt in Playground |
| Budgets    | `aws_budgets_budget.zero_spend`            | None — just run `terraform apply`           |

## Input Variables

| Variable            | Default       | Description                                          |
|---------------------|---------------|------------------------------------------------------|
| `aws_region`        | `us-east-1`   | AWS region (us-east-1 has broadest free tier)        |
| `project_name`      | `freetier`    | Prefix for all resource names and tags               |
| `db_username`       | `dbadmin`     | RDS PostgreSQL master username                       |
| `db_password`       | *(required)*  | RDS PostgreSQL master password (**sensitive**)        |
| `my_ip_cidr`        | *(required)*  | Your public IP in CIDR for SSH (e.g., `1.2.3.4/32`) |
| `notification_email`| *(required)*  | Email for SNS alerts and Budgets notifications       |
| `vpc_cidr`          | `10.0.0.0/16` | VPC CIDR block                                       |
| `az_count`          | `2`           | Number of availability zones (2-4)                   |

## Quick Start

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set db_password, my_ip_cidr, notification_email
terraform init
terraform plan
terraform apply
```

After apply, confirm the SNS email subscription (check your inbox).

## Cost Guard Rails

| Resource       | Setting                           | Free Tier Limit           | ⚠️ What triggers charges              |
|----------------|-----------------------------------|---------------------------|---------------------------------------|
| VPC            | No NAT gateway created            | VPCs are free             | NAT gateway = ~$32/month              |
| EC2            | `t4g.micro`                       | 750 hrs/month (12-mo)     | Larger instance type                  |
| EC2            | `volume_size = 30`                | 30 GB EBS                 | Larger volume                         |
| RDS            | `db.t4g.micro`                    | 750 hrs/month (12-mo)     | Larger instance class                 |
| RDS            | `allocated_storage = 20`          | 20 GB GP2                 | More storage                          |
| RDS            | `max_allocated_storage = 20`      | —                         | Higher value enables auto-scaling     |
| RDS            | `multi_az = false`                | Single-AZ only            | Multi-AZ doubles cost                 |
| ElastiCache    | `cache.t3.micro`, 1 node          | 750 hrs/month (12-mo)     | Larger type or > 1 node               |
| S3             | Versioning disabled               | 5 GB storage (12-mo)      | Each version counts toward 5 GB       |
| S3             | SSE = AES256 (SSE-S3)             | SSE-S3 is free            | KMS encryption incurs KMS charges     |
| CloudFront     | `PriceClass_100`, no WAF          | 1 TB + 10M req/mo         | WAF = not free                        |
| Lambda         | `memory_size = 128`               | 400K GB-sec/month         | Higher memory reduces free seconds    |
| DynamoDB       | `PROVISIONED`, 25 RCU/WCU         | 25 RCU + 25 WCU (always)  | On-demand or > 25 incurs charges      |
| SQS            | Standard queue (not FIFO)         | 1M requests/month (always)| FIFO burns faster                     |
| CloudWatch     | 2 alarms, 7d log retention        | 10 alarms, 5 GB (always)  | > 10 alarms or long retention         |
| Secrets Manager| $0.40/secret/month                | NOT free tier              | Each enabled secret incurs charges    |
| Budgets        | 2 notifications (no actions)      | 2 action budgets (always) | > 2 action-enabled budgets            |
