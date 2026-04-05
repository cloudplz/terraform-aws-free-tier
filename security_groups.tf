# Security groups — free. No cost concern.

# EC2 — SSH restricted to operator IP, HTTP/HTTPS open to the world
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Allow SSH from admin IP, HTTP/HTTPS from anywhere"
  vpc_id      = aws_vpc.main.id

  # SSH — restricted to operator's IP only
  ingress {
    description = "SSH from admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # HTTP — open to the world for web serving
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS — open to the world for web serving
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
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

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

# RDS — PostgreSQL from EC2 SG only
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow PostgreSQL from EC2 security group only"
  vpc_id      = aws_vpc.main.id

  # PostgreSQL — only from the EC2 security group
  ingress {
    description     = "PostgreSQL from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# ElastiCache — Redis from EC2 SG only
resource "aws_security_group" "elasticache" {
  name        = "${var.project_name}-cache-sg"
  description = "Allow Redis from EC2 security group only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Redis from EC2"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-cache-sg"
  }
}
