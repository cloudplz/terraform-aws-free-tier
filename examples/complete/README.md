# Complete Example

Deploys **all features enabled** — earns all 5 credit-earning activities ($100 bonus).

Estimated credit burn: **~$39.79/month** ($200 lasts ~5 months).

## Usage

```bash
cd examples/complete
terraform init
terraform apply -var='name=myproject'
```

## What gets created

| Service | Detail |
|---------|--------|
| EC2 | t4g.micro with 30 GB gp3 |
| RDS | PostgreSQL db.t4g.micro, 20 GB |
| Aurora | Serverless v2, 0.5–4 ACUs |
| ElastiCache | Valkey cache.t3.micro |
| Lambda | Node 22.x, 128 MB + Function URL |
| API Gateway | HTTP API with Lambda integration |
| S3 | Encrypted bucket with versioning |
| CloudFront | OAC distribution over S3 |
| DynamoDB | 25 RCU/WCU provisioned |
| SQS | Standard queue + DLQ |
| SNS | Topic with optional email |
| EventBridge | Scheduler pinging Lambda every 5 min |
| Step Functions | Standard workflow |
| Cognito | User Pool with hosted domain |
| CloudWatch | Log groups + metric alarms |
| Budgets | Zero-spend alert |
| Bedrock | Invocation logging to CloudWatch |

## Cleanup

```bash
terraform destroy -var='name=myproject'
```
