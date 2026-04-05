# Tagging convention:
#   default_tags in provider.tf supplies: Project, ManagedBy, Tier
#   Each resource merges var.tags with a unique Name tag via:
#     tags = merge(var.tags, { Name = "${var.project_name}-<suffix>" })

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region

  azs = [for index, az in data.aws_availability_zones.available.names : az if index < var.az_count]

  db_enabled = var.features.rds || var.features.aurora
}
