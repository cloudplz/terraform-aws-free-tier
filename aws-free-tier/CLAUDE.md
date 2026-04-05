# AWS Free Tier Terraform Project

Provisions all major AWS free tier services using official `terraform-aws-modules`.
Target: AWS legacy free tier (12-month + always-free services) in `us-east-1`.

## Architecture Diagram

```
                         ┌──────────────────────────────────────────────────────┐
                         │                  AWS Account (us-east-1)            │
                         │                                                      │
                         │  ┌──────────────── VPC 10.0.0.0/16 ───────────────┐ │
                         │  │                                                 │ │
                         │  │  ┌─── Public Subnet ───┐  ┌─── Public Subnet ──┐│ │
                         │  │  │   10.0.1.0/24       │  │   10.0.2.0/24      ││ │
                         │  │  │   AZ-a               │  │   AZ-b             ││ │
                         │  │  │  ┌──────────────┐   │  │                    ││ │
          SSH ──────────►│  │  │  │  EC2 (t4g)   │   │  │                    ││ │
         HTTP ──────────►│  │  │  │  nginx       │   │  │                    ││ │
        HTTPS ──────────►│  │  │  │  30GB gp3    │   │  │                    ││ │
                         │  │  │  └──────┬───────┘   │  │                    ││ │
                         │  │  └─────────┼───────────┘  └────────────────────┘│ │
                         │  │            │ port 5432                          │ │
                         │  │  ┌─── Private Subnet ──┐  ┌── Private Subnet ──┐│ │
                         │  │  │   10.0.101.0/24     │  │  10.0.102.0/24     ││ │
                         │  │  │   AZ-a               │  │  AZ-b             ││ │
                         │  │  │  ┌──────────────┐   │  │                    ││ │
                         │  │  │  │ RDS Postgres │   │  │                    ││ │
                         │  │  │  │ db.t4g.micro │   │  │                    ││ │
                         │  │  │  │ 20GB gp2     │   │  │                    ││ │
                         │  │  │  └──────────────┘   │  │                    ││ │
                         │  │  └─────────────────────┘  └────────────────────┘│ │
                         │  │          NO NAT GATEWAY (saves ~$32/month)      │ │
                         │  └─────────────────────────────────────────────────┘ │
                         │                                                      │
                         │  ┌──────────┐  ┌──────────┐  ┌───────────────────┐  │
                         │  │ S3 Bucket│  │ Lambda   │  │ DynamoDB Table    │  │
                         │  │ (assets) │  │ Node22.x │  │ 25 RCU / 25 WCU  │  │
                         │  │ 5GB free │  │ 128MB    │  │ pk(S) + sk(S)    │  │
                         │  │ SSE-S3   │  │ 1M req/mo│  │ TTL: expires_at  │  │
                         │  └──────────┘  └──────────┘  └───────────────────┘  │
                         │                                                      │
                         │  ┌──────────────────┐  ┌──────────────────────────┐  │
                         │  │ SQS Queue        │  │ CloudWatch               │  │
                         │  │ + Dead Letter Q  │  │  Log group (7d retention)│  │
                         │  │ 1M req/mo free   │  │  CPU alarm (>80%)        │  │
                         │  │ maxReceive = 3   │  │  Storage alarm (<2GB)    │  │
                         │  └──────────────────┘  └──────────────────────────┘  │
                         │                                                      │
                         │  ┌──────────────────────────────────────────────┐    │
                         │  │ IAM: EC2 role + S3 access policy             │    │
                         │  │      (instance profile attached to EC2)      │    │
                         │  └──────────────────────────────────────────────┘    │
                         └──────────────────────────────────────────────────────┘
```

## Input Variables

| Variable       | Type   | Default      | Description                                          |
|----------------|--------|--------------|------------------------------------------------------|
| `aws_region`   | string | `us-east-1`  | AWS region (us-east-1 has broadest free tier)        |
| `project_name` | string | `freetier`   | Prefix for all resource names and tags               |
| `db_username`  | string | `dbadmin`    | RDS PostgreSQL master username                       |
| `db_password`  | string | *(required)* | RDS PostgreSQL master password (**sensitive**)        |
| `my_ip_cidr`   | string | *(required)* | Your public IP in CIDR for SSH (e.g., `1.2.3.4/32`) |

## Outputs

| Output                | Description                           |
|-----------------------|---------------------------------------|
| `ec2_public_ip`       | Public IP of the EC2 instance         |
| `ec2_public_dns`      | Public DNS hostname of EC2            |
| `rds_endpoint`        | RDS endpoint (host:port)              |
| `rds_db_name`         | RDS database name                     |
| `s3_bucket_name`      | S3 assets bucket name                 |
| `lambda_function_name`| Lambda function name                  |
| `dynamodb_table_name` | DynamoDB table name                   |
| `sqs_queue_url`       | SQS main queue URL                    |

## Cost Guard Rails

Every setting below prevents charges. Changing any of them can trigger bills:

| Resource   | Setting                       | Free Tier Limit             | ⚠️ What triggers charges                    |
|------------|-------------------------------|-----------------------------|----------------------------------------------|
| VPC        | `enable_nat_gateway = false`  | VPCs are free               | NAT gateway = ~$32/month                     |
| EC2        | `instance_type = "t4g.micro"` | 750 hrs/month (12-mo)       | Larger instance type                         |
| EC2        | `volume_size = 30`            | 30 GB EBS                   | Larger volume                                |
| RDS        | `instance_class = "db.t4g.micro"` | 750 hrs/month (12-mo)   | Larger instance class                        |
| RDS        | `allocated_storage = 20`      | 20 GB GP2                   | More storage                                 |
| RDS        | `max_allocated_storage = 20`  | —                           | Higher value enables auto-scaling past limit |
| RDS        | `multi_az = false`            | Single-AZ only              | Multi-AZ doubles the cost                    |
| S3         | Versioning disabled           | 5 GB storage (12-mo)        | Each version counts toward 5 GB              |
| S3         | SSE = AES256 (SSE-S3)         | SSE-S3 is free              | KMS encryption incurs KMS charges            |
| Lambda     | `memory_size = 128`           | 400K GB-sec/month           | Higher memory reduces free seconds           |
| DynamoDB   | `billing_mode = "PROVISIONED"`| 25 RCU + 25 WCU (always)   | On-demand mode is NOT free tier              |
| DynamoDB   | `read/write_capacity = 25`    | 25 each (always free)       | Exceeding 25 incurs charges                  |
| SQS        | Standard queue (not FIFO)     | 1M requests/month (always)  | FIFO burns free tier faster                  |
| CloudWatch | 2 alarms                      | 10 alarms (always free)     | More than 10 alarms incur charges            |
| CloudWatch | `retention_in_days = 7`       | 5 GB log storage (always)   | Long retention + high volume exceeds limit   |

## How to Extend Safely

### Adding ElastiCache (Redis)

```hcl
# Free tier: 750 hours/month of cache.t2.micro or cache.t3.micro (12-month)
module "elasticache" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "~> 1.0"
  # Use node_type = "cache.t3.micro" and num_cache_nodes = 1
}
```

### Upgrading RDS to Multi-AZ

```hcl
# ⚠️ This DOUBLES your RDS cost — no longer free tier
# In rds.tf, change:
multi_az = true
```

### Adding a Second EC2 Instance

```hcl
# ⚠️ Free tier covers 750 hours TOTAL across all instances.
# Two t4g.micro instances = 2 × 730 hours = 1,460 hours → ~730 hours billed.
# Estimated cost: ~$6/month for the second instance.
module "ec2_worker" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"
  # Same config as the first instance but in a different subnet
  subnet_id = module.vpc.public_subnets[1]
}
```

### Adding SNS for Alarm Notifications

```hcl
# Free tier: 1M publishes + 100K HTTP deliveries/month (always free)
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "you@example.com"
}
# Then add alarm_actions = [aws_sns_topic.alerts.arn] to each alarm
```

### Adding an ALB (Application Load Balancer)

```hcl
# ⚠️ ALBs are NOT free tier — ~$16/month minimum.
# Only add if you need HTTPS termination or path-based routing.
```

## Quick Start

```bash
cd aws-free-tier
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set db_password and my_ip_cidr
terraform init
terraform plan
terraform apply
```

## Modules Used

| Module                              | Registry Source                          |
|-------------------------------------|------------------------------------------|
| VPC                                 | terraform-aws-modules/vpc/aws ~> 5.0     |
| EC2                                 | terraform-aws-modules/ec2-instance/aws ~> 5.0 |
| RDS                                 | terraform-aws-modules/rds/aws ~> 6.0     |
| S3                                  | terraform-aws-modules/s3-bucket/aws ~> 4.0 |
| IAM (assumable-role + policy)       | terraform-aws-modules/iam/aws ~> 5.0     |
| Lambda                              | terraform-aws-modules/lambda/aws ~> 7.0  |
| DynamoDB                            | terraform-aws-modules/dynamodb-table/aws ~> 4.0 |
| SQS                                 | terraform-aws-modules/sqs/aws ~> 4.0     |
