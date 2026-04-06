# Minimal Example

Cost-optimised deployment — disables RDS and ElastiCache to stretch credits furthest.

Estimated credit burn: **~$12.60/month** ($200 lasts ~16 months).

Earns 4 of 5 bonus credits (EC2, Lambda, Bedrock, Budgets). To earn the 5th RDS credit ($20),
apply the [complete example](../complete) briefly, then destroy and switch to this config.

## Usage

```bash
cd examples/minimal
terraform init
terraform apply -var='name=myproject'
```

## What's different from complete

| Feature | Status | Savings |
|---------|--------|---------|
| RDS PostgreSQL | Disabled | ~$14/mo |
| ElastiCache Valkey | Disabled | ~$12.41/mo |
| Aurora Serverless v2 | Enabled (free under Paid Plan) | $0 |
| CloudFront | Enabled (Always Free) | $0 |
| Cognito | Enabled (Always Free) | $0 |
| Step Functions | Enabled (Always Free) | $0 |
| Bedrock Logging | Enabled (config is free) | $0 |

## Cleanup

```bash
terraform destroy -var='name=myproject'
```
