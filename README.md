# terraform-aws-free-tier

Provisions all major AWS services covered by the AWS Free Plan using direct `resource`
blocks (no terraform-aws-modules wrappers). Designed for new AWS accounts to maximise
the $200 credit window and then transition to always-free tiers.

## AWS Free Plan — July 2025 model

New accounts receive:

| Credit | Amount | Validity |
|---|---|---|
| Sign-up credits | $100 | 6 months (Free Plan) or 12 months (Paid Plan) |
| Onboarding bonus | Up to $100 more (5 × $20) | Same window as sign-up credits |
| **Total** | **Up to $200** | — |

Always-free services (Lambda, DynamoDB, SQS, SNS, Cognito, CloudWatch basic) remain
free indefinitely regardless of credit expiry.

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
                    │  │  │ │ Aurora PG   │  │  │                   │                         │  │
                    │  │  │ │ Serverless  │  │  │                   │                         │  │
                    │  │  │ │ v2 (0.5–4   │  │  │                   │                         │  │
                    │  │  │ │ ACUs)       │  │  │                   │                         │  │
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
                    │  │ Secrets Manager: /rds  /aurora  /elasticache  (JSON secrets)         │   │
                    │  └──────────────────────────────────────────────────────────────────────┘   │
                    │                                                                              │
                    │  ┌──────────────────────────────────────────────────────────────────────┐   │
                    │  │ IAM: EC2 role + Lambda role + Scheduler role + SFN role              │   │
                    │  │      Bedrock logging role + S3 access policy + instance profile      │   │
                    │  └──────────────────────────────────────────────────────────────────────┘   │
                    └──────────────────────────────────────────────────────────────────────────────┘
```

## Usage

```hcl
module "free_tier" {
  source  = "cloudplz/aws-free-tier/aws"
  version = "~> 1.0"

  # Required
  db_password        = var.db_password        # ephemeral — not stored in state
  my_ip_cidr         = "203.0.113.42/32"
  notification_email = "you@example.com"
}
```

After apply, confirm the SNS email subscription (check your inbox).

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set db_password, my_ip_cidr, notification_email
terraform init
terraform plan
terraform apply
```

## Feature Toggles

Core services (VPC, EC2, Lambda, S3, DynamoDB, SQS, SNS, IAM, CloudWatch, Budgets)
are always provisioned. Optional services can be disabled:

```hcl
module "free_tier" {
  source  = "cloudplz/aws-free-tier/aws"
  version = "~> 1.0"

  db_password        = var.db_password
  my_ip_cidr         = "203.0.113.42/32"
  notification_email = "you@example.com"

  # Disable optional services not needed for this deployment
  features = {
    rds             = true
    aurora          = false   # Skip Aurora Serverless v2
    elasticache     = false   # Skip Valkey cache (requires rds or aurora when true)
    cloudfront      = true
    cognito         = false   # Skip auth
    step_functions  = true
    bedrock_logging = false   # Skip Bedrock logging infra
  }
}
```

**Constraint:** `features.elasticache = true` requires either `features.rds = true` or
`features.aurora = true` (the DB subnet group is shared). A validation error will be
raised if this constraint is violated.

## Secrets

When a data tier is enabled, connection credentials are written to Secrets Manager
as JSON objects. All secrets use the AWS-managed KMS key (no customer-managed key).

| Path | Enabled when | JSON fields |
|---|---|---|
| `/${project_name}/rds` | `features.rds = true` | `endpoint`, `port`, `db_name`, `username`, `password` |
| `/${project_name}/aurora` | `features.aurora = true` | `endpoint`, `reader_endpoint`, `port`, `db_name`, `username`, `password` |
| `/${project_name}/elasticache` | `features.elasticache = true` | `endpoint`, `port`, `engine` |

**Cost after credits:** $0.40 per secret per month × 3 secrets = **$1.20/month**.

Retrieve a secret at runtime:

```bash
aws secretsmanager get-secret-value \
  --secret-id /freetier/rds \
  --query SecretString \
  --output text | jq .
```

## Free Tier Cost Guard Rails

| Resource | Setting | Free Plan Coverage | What triggers charges |
|---|---|---|---|
| VPC | No NAT gateway | VPCs are free | NAT gateway ≈ $32/month |
| EC2 | `t4g.micro` | 750 hrs/month (credits window) | Larger instance type |
| EC2 | `volume_size = 30` | 30 GB EBS | Larger volume |
| RDS | `db.t4g.micro` | 750 hrs/month (credits window) | Larger instance class |
| RDS | `allocated_storage = 20` | 20 GB GP2 | More storage |
| RDS | `max_allocated_storage = 20` | — | Higher value enables auto-scaling |
| RDS | `multi_az = false` | Single-AZ only | Multi-AZ doubles cost |
| Aurora | Serverless v2, 0.5–4 ACUs | 4 ACUs / 1 GiB (credits window) | `aurora_max_capacity > 4.0` |
| Aurora | `database_insights_mode = "standard"` | Free, 7-day retention | `"advanced"` costs $0.003125/ACU-hr |
| RDS | `database_insights_mode = "standard"` | Free, 7-day retention | `"advanced"` costs $0.0125/vCPU-hr |
| ElastiCache | Valkey 8.0, `cache.t3.micro`, 1 node | 750 hrs/month (credits window) | `cache.t4g.micro` is NOT free-plan eligible |
| S3 | Versioning disabled | 5 GB storage (credits window) | Each version counts toward 5 GB |
| S3 | SSE = AES256 (SSE-S3) | SSE-S3 is free | KMS encryption incurs KMS charges |
| CloudFront | `PriceClass_100`, no WAF | 1 TB + 10M req/mo (always) | WAF is not free |
| Lambda | `memory_size = 128` | 400K GB-sec/month (always) | Higher memory reduces free seconds |
| DynamoDB | `PROVISIONED`, 25 RCU/WCU | 25 RCU + 25 WCU (always) | On-demand or > 25 incurs charges |
| SQS | Standard queue (not FIFO) | 1M requests/month (always) | FIFO burns faster |
| CloudWatch | 2 alarms, `log_retention_days = 7` | 10 alarms, 5 GB (always) | > 10 alarms or long retention |
| Budgets | 2 notifications (no actions) | 2 action budgets (always) | > 2 action-enabled budgets |
| Secrets Manager | 3 secrets, AWS-managed KMS | — | $0.40/secret/month = $1.20/month after credits |

## Credit-Earning Activities

Complete all 5 to earn an extra $100 in credits ($20 each).

| Service | What Terraform Provisions | Console Step Required? |
|---|---|---|
| EC2 | `aws_instance.web` (t4g.micro) | None — just run `terraform apply` |
| RDS | `aws_db_instance.postgres` (db.t4g.micro) | None — just run `terraform apply` |
| Lambda | `aws_lambda_function_url.handler` | None — Function URL is the trigger |
| Bedrock | `aws_bedrock_model_invocation_logging_configuration` | Enable model access + submit 1 prompt in Playground |
| Budgets | `aws_budgets_budget.zero_spend` | None — just run `terraform apply` |

## Requirements

| Name | Version |
|---|---|
| terraform | `~> 1.11` |
| aws | `~> 6.0` |
| random | `~> 3.0` |
| archive | `~> 2.4` |

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `db_password` | Master password for RDS and Aurora. ≥8 chars. Ephemeral — not stored in state. | `string` | — | yes |
| `my_ip_cidr` | Your public IP in CIDR for SSH (e.g., `1.2.3.4/32`). | `string` | — | yes |
| `notification_email` | Email for SNS, Budgets, and CloudWatch alerts. | `string` | — | yes |
| `aws_region` | AWS region. | `string` | `"us-east-1"` | no |
| `project_name` | Name prefix for all resources (≤20 chars). | `string` | `"freetier"` | no |
| `db_username` | Master username for RDS and Aurora. | `string` | `"dbadmin"` | no |
| `key_name` | EC2 key pair name for SSH. `null` = use SSM. | `string` | `null` | no |
| `ec2_instance_type` | EC2 instance type (t-family only). | `string` | `"t4g.micro"` | no |
| `ec2_volume_size_gb` | Root EBS volume size in GB (`<= 30`). | `number` | `30` | no |
| `rds_instance_class` | RDS instance class (`db.t3.micro` or `db.t4g.micro`). | `string` | `"db.t4g.micro"` | no |
| `rds_allocated_storage` | RDS storage in GB (`<= 20`). | `number` | `20` | no |
| `aurora_min_capacity` | Aurora Serverless v2 min ACUs (`>= 0.5`). | `number` | `0.5` | no |
| `aurora_max_capacity` | Aurora Serverless v2 max ACUs (`<= 4.0`). | `number` | `4.0` | no |
| `lambda_memory_mb` | Lambda memory in MB (`<= 128`). | `number` | `128` | no |
| `elasticache_node_type` | ElastiCache node type (must be `cache.t3.micro`). | `string` | `"cache.t3.micro"` | no |
| `log_retention_days` | CloudWatch log retention in days (valid CW value). | `number` | `7` | no |
| `tags` | Additional tags merged onto all resources. | `map(string)` | `{}` | no |
| `features` | Feature toggles for optional services (see Feature Toggles section). | `object` | all `true` | no |

## Outputs

| Name | Description |
|---|---|
| `ec2_public_ip` | Public IP address of the EC2 instance |
| `ec2_public_dns` | Public DNS hostname of the EC2 instance |
| `rds_endpoint` | RDS PostgreSQL endpoint (host:port), or `null` |
| `rds_db_name` | RDS database name, or `null` |
| `rds_secret_arn` | ARN of `/${project_name}/rds` secret, or `null` |
| `aurora_endpoint` | Aurora cluster writer endpoint, or `null` |
| `aurora_reader_endpoint` | Aurora cluster reader endpoint, or `null` |
| `aurora_secret_arn` | ARN of `/${project_name}/aurora` secret, or `null` |
| `elasticache_endpoint` | ElastiCache Valkey endpoint (host:port), or `null` |
| `elasticache_secret_arn` | ARN of `/${project_name}/elasticache` secret, or `null` |
| `valkey_engine_version` | Valkey engine version deployed, or `null` |
| `s3_bucket_name` | Name of the S3 assets bucket |
| `cloudfront_domain` | CloudFront distribution domain name, or `null` |
| `dynamodb_table_name` | Name of the DynamoDB table |
| `lambda_function_name` | Name of the Lambda function |
| `lambda_function_url` | Lambda Function URL (public HTTPS endpoint) |
| `api_gateway_url` | API Gateway HTTP API invoke URL |
| `sqs_queue_url` | URL of the SQS main queue |
| `sns_topic_arn` | ARN of the SNS alerts topic |
| `step_functions_arn` | ARN of the Step Functions state machine, or `null` |
| `cognito_user_pool_id` | ID of the Cognito User Pool, or `null` |
| `cognito_client_id` | ID of the Cognito App Client, or `null` |
| `cognito_domain` | Cognito hosted domain URL, or `null` |
