# RDS PostgreSQL — terraform-aws-modules/rds
# Free tier: 750 hours/month of db.t2.micro, db.t3.micro, or db.t4g.micro (12-month).
# 20 GB of General Purpose (SSD) storage. 20 GB of backup storage.
# ⚠️ multi_az = true doubles the cost (runs a standby in another AZ)
# ⚠️ allocated_storage > 20 exceeds free tier
# ⚠️ max_allocated_storage > 20 allows auto-scaling past the free tier limit
# ⚠️ Changing instance_class to anything larger incurs charges
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "${var.project_name}-postgres"

  engine               = "postgres"
  engine_version       = "17"
  family               = "postgres17"
  major_engine_version = "17"
  instance_class       = "db.t4g.micro" # Graviton2 — free tier eligible

  allocated_storage     = 20 # Free tier: up to 20 GB of GP2 storage
  max_allocated_storage = 20 # ⚠️ Raising this allows auto-scaling past free tier limit

  storage_type = "gp2" # Free tier covers gp2; gp3 also works but gp2 is specified

  db_name  = "${var.project_name}db"
  username = var.db_username
  port     = 5432

  manage_master_user_password = false
  password                    = var.db_password

  multi_az            = false # ⚠️ multi_az = true doubles RDS cost
  publicly_accessible = false # Keep in private subnets for security

  subnet_ids                = module.vpc.private_subnets
  vpc_security_group_ids    = [aws_security_group.rds.id]
  create_db_subnet_group    = true
  create_db_option_group    = false # Not needed for PostgreSQL
  create_db_parameter_group = false # Use default parameter group

  backup_retention_period = 7              # 7 days of automated backups (free within 20 GB)
  backup_window           = "03:00-04:00"  # UTC — low-traffic window
  maintenance_window      = "Mon:04:00-Mon:05:00"

  deletion_protection = false # Allow easy teardown of free tier playground
  skip_final_snapshot = true  # No final snapshot needed for playground

  tags = {
    Name = "${var.project_name}-postgres"
  }
}
