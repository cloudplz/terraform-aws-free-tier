# AWS Free Tier Terraform

Provisions all major AWS free-tier services using direct `resource` blocks (no module wrappers).
Targets the AWS Free Plan (post-July 2025) in `us-east-1` — $200 in credits + 30+ Always Free services.
Covers all 5 credit-earning activities ($20 each = $100 bonus).

## Quick Start

```bash
terraform init
terraform apply -var='name=freetier'
```
