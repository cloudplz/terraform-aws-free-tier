locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region

  azs = [for index, az in data.aws_availability_zones.available.names : az if index < var.az_count]

  db_enabled = var.features.rds || var.features.aurora

  common_tags = {
    Project   = var.name
    ManagedBy = "terraform"
    Tier      = "free"
  }
}
