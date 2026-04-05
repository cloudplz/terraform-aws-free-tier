# Secrets Manager — stores connection credentials as JSON secrets.
# Uses AWS-managed KMS key only — no customer-managed key (adds $1.00/month).
# Cost after credits: $0.40 × 3 secrets = $1.20/month (NOT free-tier).
# Each secret is gated behind the same for_each toggle as its source resource.
# secret_string_wo keeps the password out of Terraform state entirely.

# Auto-generated database password — ephemeral, never stored in Terraform state.
# Retrieve after deploy: aws secretsmanager get-secret-value --secret-id /<name>/rds
ephemeral "random_password" "db" {
  length  = 32
  special = false # RDS/Aurora special character support is limited
}

# ─── RDS PostgreSQL secret ────────────────────────────────────────────────────

resource "aws_secretsmanager_secret" "rds" {
  for_each = var.features.rds ? { this = {} } : {}

  name        = "/${var.name}/rds"
  description = "RDS PostgreSQL connection credentials for ${var.name}"

  tags = merge(var.tags, {
    Name = "${var.name}-rds-secret"
  })
}

resource "aws_secretsmanager_secret_version" "rds" {
  for_each = var.features.rds ? { this = {} } : {}

  secret_id = aws_secretsmanager_secret.rds["this"].id
  secret_string_wo = jsonencode({
    endpoint = aws_db_instance.postgres["this"].address
    port     = aws_db_instance.postgres["this"].port
    db_name  = aws_db_instance.postgres["this"].db_name
    username = var.db_username
    password = ephemeral.random_password.db.result
  })
  secret_string_wo_version = 1
}

# ─── Aurora PostgreSQL secret ─────────────────────────────────────────────────

resource "aws_secretsmanager_secret" "aurora" {
  for_each = var.features.aurora ? { this = {} } : {}

  name        = "/${var.name}/aurora"
  description = "Aurora PostgreSQL connection credentials for ${var.name}"

  tags = merge(var.tags, {
    Name = "${var.name}-aurora-secret"
  })
}

resource "aws_secretsmanager_secret_version" "aurora" {
  for_each = var.features.aurora ? { this = {} } : {}

  secret_id = aws_secretsmanager_secret.aurora["this"].id
  secret_string_wo = jsonencode({
    endpoint        = aws_rds_cluster.aurora["this"].endpoint
    reader_endpoint = aws_rds_cluster.aurora["this"].reader_endpoint
    port            = aws_rds_cluster.aurora["this"].port
    db_name         = aws_rds_cluster.aurora["this"].database_name
    username        = var.db_username
    password        = ephemeral.random_password.db.result
  })
  secret_string_wo_version = 1
}

# ─── ElastiCache Valkey secret ────────────────────────────────────────────────

resource "aws_secretsmanager_secret" "elasticache" {
  for_each = var.features.elasticache ? { this = {} } : {}

  name        = "/${var.name}/elasticache"
  description = "ElastiCache Valkey connection details for ${var.name}"

  tags = merge(var.tags, {
    Name = "${var.name}-elasticache-secret"
  })
}

resource "aws_secretsmanager_secret_version" "elasticache" {
  for_each = var.features.elasticache ? { this = {} } : {}

  secret_id = aws_secretsmanager_secret.elasticache["this"].id
  secret_string_wo = jsonencode({
    endpoint = aws_elasticache_replication_group.valkey["this"].primary_endpoint_address
    port     = aws_elasticache_replication_group.valkey["this"].port
    engine   = "valkey"
  })
  secret_string_wo_version = 1
}
