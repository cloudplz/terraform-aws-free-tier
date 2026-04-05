# DB subnet group — shared by RDS PostgreSQL and Aurora.
# Created whenever features.rds or features.aurora is enabled.
# ⚠️ Disabling both features.rds and features.aurora also removes this resource.

resource "aws_db_subnet_group" "main" {
  for_each = (var.features.rds || var.features.aurora) ? { this = {} } : {}

  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [for s in aws_subnet.private : s.id]

  tags = merge(var.tags, {
    Name    = "${var.project_name}-db-subnet-group"
    Project = var.project_name
  })
}

# RDS PostgreSQL
# ⚠️ multi_az = true doubles cost
# ⚠️ allocated_storage > 20 exceeds free plan storage
# ⚠️ max_allocated_storage > 20 enables auto-scaling past the free plan limit
# ⚠️ Changing instance_class to anything larger incurs charges

resource "aws_db_instance" "postgres" {
  for_each = var.features.rds ? { this = {} } : {}

  identifier     = "${var.project_name}-postgres"
  engine         = "postgres"
  engine_version = "17"
  instance_class = var.rds_instance_class

  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_allocated_storage  # ⚠️ Prevents auto-scaling past free plan limit
  storage_type          = "gp2"
  storage_encrypted     = true  # Free with default AWS-managed key

  db_name         = "${var.project_name}db"
  username        = var.db_username
  password_wo     = var.db_password  # Write-only — password is never written to Terraform state
  port            = 5432

  db_subnet_group_name   = aws_db_subnet_group.main["this"].name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = "default.postgres17"

  backup_retention_period = 1
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  multi_az            = false  # ⚠️ true doubles cost
  publicly_accessible = false
  deletion_protection = false
  skip_final_snapshot = true

  # Database Insights Standard mode — free, 7-day retention.
  # Successor to Performance Insights after its console EOL on June 30, 2026.
  # ⚠️ Do NOT set database_insights_mode = "advanced" — costs $0.0125/vCPU-hr
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  database_insights_mode                = "standard"

  tags = merge(var.tags, {
    Name    = "${var.project_name}-postgres"
    Project = var.project_name
  })
}
