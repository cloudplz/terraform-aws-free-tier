# AWS Free Tier Terraform

Provisions all major AWS free-tier services using direct `resource` blocks (no module wrappers).
Targets the AWS Free Plan (post-July 2025) in `us-east-1` — $200 in credits + 30+ Always Free
services. Covers all 5 credit-earning activities ($20 each = $100 bonus).

## Prerequisites

### AWS account plan

This module requires the **AWS Paid Plan** (not the Free Plan). On the Free Plan, AWS blocks
`CreateDBCluster` for Aurora with a `FreeTierRestrictionError` unless `WithExpressConfiguration`
is used — a parameter the Terraform AWS provider does not yet support
([hashicorp/terraform-provider-aws#47117](https://github.com/hashicorp/terraform-provider-aws/issues/47117)).

Switching to the Paid Plan preserves the full $200 in credits and removes all service
restrictions. If you are on the Free Plan and do not want to switch, disable Aurora:

```hcl
features = { aurora = false }
```

### IAM user permissions

The IAM user running Terraform must have IAM permissions (`iam:CreateRole`, `iam:CreatePolicy`,
etc.). The simplest fix is to attach `IAMFullAccess`. For a tighter policy, see the minimum
actions list in the [complete example](examples/complete/main.tf).

## Quick Start

```hcl
module "free_tier" {
  source  = "cloudplz/free-tier/aws"
  version = "~> 1.0"

  name = "myproject"
}
```

See [examples/](examples/) for complete and minimal configurations.

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
                    │  │  │ │ Valkey 8.0  │  │  │                   │                         │  │
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

## Cost Guard Rails

### Always Free Services (no credits consumed)

| Resource       | Setting                           | Always Free Limit                    | What triggers charges                 |
|----------------|-----------------------------------|--------------------------------------|---------------------------------------|
| VPC            | No NAT gateway created            | VPCs are free                        | NAT gateway = ~$32/month              |
| Lambda         | `memory_size = 128`               | 1M requests + 400K GB-sec/mo         | Higher memory reduces free seconds    |
| DynamoDB       | `PROVISIONED`, 25 RCU/WCU         | 25 RCU + 25 WCU + 25 GB             | On-demand or > 25 incurs charges      |
| Aurora         | Serverless v2, <= 4 ACUs          | 4 ACUs + 1 GiB storage (March 2026) | > 4 ACUs or > 1 GiB storage          |
| SQS            | Standard queue (not FIFO)         | 1M requests/month                    | FIFO burns requests faster            |
| SNS            | Standard topic                    | 1M publishes + 1K email/mo           | High-volume publishing                |
| CloudFront     | `PriceClass_100`, no WAF          | 1 TB out + 10M requests/mo           | WAF = not free                        |
| CloudWatch     | 2 alarms, 7d log retention        | 10 alarms + 5 GB logs               | > 10 alarms or long retention         |
| Step Functions | `STANDARD` type                   | 4,000 state transitions/mo           | EXPRESS type or complex workflows     |
| EventBridge    | Scheduler, rate(5 min)            | 14M Scheduler invocations/mo         | Rules are a different service         |
| Cognito        | User Pool, no advanced security   | 10K MAUs (direct/social)             | SAML/OIDC = 50 MAU limit             |
| Budgets        | 2 notifications (no actions)      | 2 action budgets                     | > 2 action-enabled budgets            |
| S3             | SSE = AES256 (SSE-S3)             | SSE-S3 is free                       | KMS encryption incurs KMS charges     |

### Credit-Consuming Services (~$39.79/month with defaults)

| Resource       | Setting                           | Rate                                 | Monthly Cost | What increases burn                   |
|----------------|-----------------------------------|--------------------------------------|-------------|---------------------------------------|
| EC2            | `t4g.micro`                       | $0.0084/hr                           | ~$6.13      | Larger instance type                  |
| EBS            | `gp3`, 30 GB                      | $0.08/GB-mo                          | ~$2.40      | Larger volume                         |
| Public IPv4    | 1 address on EC2                  | $0.005/hr                            | ~$3.65      | Additional public IPs                 |
| RDS            | `db.t4g.micro`, 20 GB gp2         | $0.016/hr + $0.115/GB-mo            | ~$13.98     | Larger class, more storage            |
| RDS            | `max_allocated_storage = 20`      | ---                                  | ---         | Higher value enables auto-scaling     |
| RDS            | `multi_az = false`                | ---                                  | ---         | Multi-AZ doubles cost                 |
| ElastiCache    | `cache.t3.micro`, 1 node          | $0.017/hr                            | ~$12.41     | Larger type or > 1 node              |
| Secrets Manager| Up to 3 secrets (NOT free tier)   | $0.40/secret/mo                      | ~$1.20      | More secrets or API calls             |

### Credit Budget at a Glance

| Scenario                             | Monthly Burn | $200 Lasts | $100 Lasts |
|--------------------------------------|-------------|------------|------------|
| All defaults (RDS + Aurora)          | ~$39.79     | ~5.0 mo    | ~2.5 mo    |
| Disable RDS after earning $20 credit | ~$25.41     | ~7.9 mo    | ~3.9 mo    |
| Disable RDS + ElastiCache            | ~$12.60     | ~15.9 mo   | ~7.9 mo    |
