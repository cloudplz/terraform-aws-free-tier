# Complete example — all features enabled, earns all $100 in bonus credits.
# Estimated credit burn: ~$39.79/month (see CLAUDE.md for breakdown).
#
# Usage:
#   cd examples/complete
#   terraform init
#   terraform apply -var='name=myproject'
#   terraform destroy -var='name=myproject'

module "free_tier" {
  source = "../.."

  name = var.name

  # Optional — uncomment to receive email alerts:
  # notification_email = "you@example.com"

  # Optional — uncomment to enable SSH access:
  # key_name   = "your-key-pair"
  # my_ip_cidr = "203.0.113.42/32"
}
