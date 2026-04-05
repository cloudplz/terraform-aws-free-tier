# Minimal example — core services + Aurora only. Stretches credits furthest.
# Estimated credit burn: ~$12.60/month ($200 lasts well past the 6-month Free Plan).
#
# Still earns 4 of 5 bonus credits: EC2 ($20), Lambda ($20), Bedrock ($20), Budgets ($20).
# RDS is disabled — apply the complete example briefly to earn the 5th $20 credit,
# then destroy it and switch to this minimal config.
#
# Usage:
#   cd examples/minimal
#   terraform init
#   terraform apply -var='name=myproject'
#   terraform destroy -var='name=myproject'

module "free_tier" {
  source = "../.."

  name = var.name

  features = {
    rds             = false # ~$14/mo saved — use Aurora (free) instead
    aurora          = true  # FREE under Free Plan (up to 4 ACUs + 1 GiB)
    elasticache     = false # ~$12.41/mo saved
    cloudfront      = true  # Always Free (1 TB + 10M req/mo)
    cognito         = true  # Always Free (10K MAUs)
    step_functions  = true  # Always Free (4K transitions/mo)
    bedrock_logging = true  # Logging config is free; inference is not
  }
}
