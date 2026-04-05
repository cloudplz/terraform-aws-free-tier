# Security groups — free. No cost concern.

# EC2 — SSH restricted to operator IP, HTTP open to the world
resource "aws_security_group" "ec2" {
  name        = "${var.name}-ec2-sg"
  description = "Allow SSH from admin IP, HTTP from anywhere"
  vpc_id      = aws_vpc.main.id

  # SSH — restricted to operator's IP, only when both key pair and IP are configured
  dynamic "ingress" {
    for_each = var.key_name != null && var.my_ip_cidr != null ? [1] : []
    content {
      description = "SSH from admin IP"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.my_ip_cidr]
    }
  }

  # HTTP — open to the world for web serving
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-ec2-sg"
  })
}

# RDS / Aurora — PostgreSQL from EC2 SG only (shared by both RDS and Aurora)
resource "aws_security_group" "rds" {
  for_each = local.db_enabled ? { this = {} } : {}

  name        = "${var.name}-rds-sg"
  description = "Allow PostgreSQL from EC2 security group only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-rds-sg"
  })
}

# ElastiCache — Valkey from EC2 SG only
resource "aws_security_group" "elasticache" {
  for_each = var.features.elasticache ? { this = {} } : {}

  name        = "${var.name}-cache-sg"
  description = "Allow Valkey from EC2 security group only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Valkey from EC2"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-cache-sg"
  })
}
