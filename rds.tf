# RDS PostgreSQL — free tier: 750 hrs/month db.t4g.micro, 20 GB gp2 (12-month)
# ⚠️ multi_az = true doubles cost
# ⚠️ allocated_storage > 20 exceeds free tier
# ⚠️ max_allocated_storage > 20 enables auto-scaling past the free tier limit
# ⚠️ Changing instance_class to anything larger incurs charges

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [for s in aws_subnet.private : s.id]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier     = "${var.project_name}-postgres"
  engine         = "postgres"
  engine_version = "17"
  instance_class = "db.t4g.micro"  # Graviton2 — free tier eligible

  allocated_storage     = 20  # Free tier max: 20 GB
  max_allocated_storage = 20  # ⚠️ Prevents auto-scaling past free tier limit
  storage_type          = "gp2"
  storage_encrypted     = true   # Free with default AWS-managed key

  db_name  = "${var.project_name}db"
  username = var.db_username
  password = var.db_password
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = "default.postgres17"

  backup_retention_period = 1     # Minimizes backup storage (free up to DB size)
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  multi_az            = false  # ⚠️ true doubles cost
  publicly_accessible = false
  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Name = "${var.project_name}-postgres"
  }
}
