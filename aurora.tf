# Aurora PostgreSQL Serverless v2 — AWS Free Plan (announced March 2026):
# up to 4 ACUs and 1 GiB of storage per cluster at no cost within the credits window.
# Aurora Serverless v2 uses engine_mode = "provisioned" (not "serverless") — v2 is
# always provisioned with a serverlessv2_scaling_configuration block.
# ⚠️ aurora_max_capacity > 4.0 exceeds the free plan ACU cap
# ⚠️ database_insights_mode = "advanced" costs $0.003125/ACU-hr — do not enable

resource "aws_rds_cluster" "aurora" {
  for_each = var.features.aurora ? { this = {} } : {}

  cluster_identifier         = "${var.name}-aurora"
  engine                     = "aurora-postgresql"
  engine_mode                = "provisioned" # Required for Serverless v2 (not "serverless")
  engine_version             = "16.6"
  database_name              = "app"
  master_username            = var.db_username
  master_password_wo         = ephemeral.random_password.db.result
  master_password_wo_version = 1

  db_subnet_group_name   = aws_db_subnet_group.main["this"].name
  vpc_security_group_ids = [aws_security_group.rds["this"].id]
  storage_encrypted      = true # AWS-managed KMS key — free
  database_insights_mode = "standard"

  enable_http_endpoint                = true # RDS Data API — free
  iam_database_authentication_enabled = true # IAM auth — free

  backup_retention_period = 1 # Minimum — free
  skip_final_snapshot     = true
  deletion_protection     = false

  serverlessv2_scaling_configuration {
    min_capacity = var.aurora_min_capacity
    max_capacity = var.aurora_max_capacity # ⚠️ Free plan cap is 4 ACUs
  }

  tags = merge(var.tags, {
    Name = "${var.name}-aurora"
  })
}

resource "aws_rds_cluster_instance" "aurora" {
  for_each = var.features.aurora ? { this = {} } : {}

  identifier          = "${var.name}-aurora-instance"
  cluster_identifier  = aws_rds_cluster.aurora["this"].id
  instance_class      = "db.serverless"
  engine              = aws_rds_cluster.aurora["this"].engine
  engine_version      = aws_rds_cluster.aurora["this"].engine_version
  publicly_accessible = false

  # Database Insights Standard mode — free, 7-day retention.
  # Aurora cluster instances in aws provider v6 expose Performance Insights
  # settings here, but not database_insights_mode.
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  # Enhanced Monitoring incurs CloudWatch Logs cost — disabled for free plan
  monitoring_interval = 0

  tags = merge(var.tags, {
    Name = "${var.name}-aurora-instance"
  })
}
