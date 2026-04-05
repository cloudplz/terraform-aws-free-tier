# AWS Free Tier Terraform

Provisions all major AWS free-tier services using direct `resource` blocks (no module wrappers).
Targets the AWS legacy free tier (12-month + always-free services) in `us-east-1` and covers all
5 credit-earning activities for new accounts (+$100 in credits).

## Quick Start

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set db_password, my_ip_cidr, notification_email
terraform init
terraform plan
terraform apply
```

After apply, confirm the SNS email subscription (check your inbox).
