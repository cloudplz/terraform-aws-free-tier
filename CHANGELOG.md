# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.3] - 2026-04-11

### Fixed

- EC2 instance no longer replaced on every plan when AWS publishes a new Amazon Linux 2023 AMI — added `lifecycle { ignore_changes = [ami] }` so the instance is stable after initial creation; use `terraform apply -replace="module.free_tier.aws_instance.web"` to intentionally update the AMI

## [1.0.2] - 2026-04-05

### Changed

- Replace Mermaid diagram with Python-generated PNG using the `diagrams` library (`docs/generate_diagram.py`)
- Update README to reference `docs/architecture.png` instead of SVG

## [1.0.1] - 2026-04-05

### Changed

- Replace ASCII architecture diagram with Mermaid-sourced SVG (`docs/architecture.mmd`)
- Add Terraform Registry badge to README

### Added

- `examples/complete/README.md` and `examples/minimal/README.md` for Terraform Registry display
- Disclaimer section in README about monitoring AWS charges
- `Makefile` with `make diagram` target for local SVG rendering
- GitHub repository topics and homepage URL

## [1.0.0] - 2026-04-05

### Added

- VPC with public/private subnets across configurable availability zones (`az_count`)
- EC2 t4g.micro instance (Amazon Linux 2023 ARM64) with IMDSv2 enforcement and optional SSH access
- RDS PostgreSQL db.t4g.micro with Secrets Manager secret (ephemeral write-only password, never stored in state) (feature toggle)
- Aurora Serverless v2 PostgreSQL (0.5–4.0 ACUs) with Secrets Manager (feature toggle)
- ElastiCache Valkey replication group cache.t3.micro with Secrets Manager (feature toggle)
- S3 bucket with SSE-S3 encryption, public access block, and versioning
- CloudFront distribution with S3 origin and Origin Access Control (feature toggle)
- Lambda function (Node.js 22.x, 128 MB) with public Function URL
- API Gateway HTTP API (v2) with Lambda proxy integration
- DynamoDB table with PROVISIONED 25 RCU/25 WCU (Always Free tier)
- SQS standard queue with dead-letter queue and SSE-SQS encryption
- SNS topic with optional email subscription
- EventBridge Scheduler pinging Lambda every 5 minutes (keeps function warm)
- CloudWatch log groups, metric alarms (EC2 CPU, RDS storage), and configurable retention
- Step Functions STANDARD state machine with Lambda integration (feature toggle)
- Bedrock model invocation logging to CloudWatch (feature toggle)
- Secrets Manager secret with ephemeral random password (never stored in state)
- IAM roles and least-privilege policies for EC2, Lambda, EventBridge Scheduler, Step Functions, and Bedrock
- Security groups with configurable SSH CIDR and HTTP open ingress
- Budget alert at $0.01 threshold with actual and forecasted notifications
- `features` variable for toggling optional services (rds, aurora, elasticache, cloudfront, cognito, step_functions, bedrock_logging)
- Validation rules enforcing free-tier-compliant instance types, sizes, and capacities
- `examples/complete` — all features enabled
- `examples/minimal` — core resources only, disables RDS and ElastiCache (~$12.60/month)
- 42 plan-mode unit tests across 4 test files (defaults, variables, features, security)
- Pre-commit hooks: terraform_fmt, terraform_validate, terraform_docs, terraform_tflint, terraform_trivy

[1.0.3]: https://github.com/cloudplz/terraform-aws-free-tier/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/cloudplz/terraform-aws-free-tier/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/cloudplz/terraform-aws-free-tier/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/cloudplz/terraform-aws-free-tier/releases/tag/v1.0.0
