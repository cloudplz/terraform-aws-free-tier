variable "aws_region" {
  description = "AWS region to deploy all resources into. us-east-1 has the broadest free tier coverage."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix applied to every resource and used in default_tags. Keep it short (≤20 chars)."
  type        = string
  default     = "freetier"
}

variable "db_username" {
  description = "Master username for the RDS PostgreSQL instance. Avoid reserved words like 'admin' or 'postgres'."
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Master password for the RDS PostgreSQL instance. Must be ≥8 characters. Never commit to version control."
  type        = string
  sensitive   = true
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR notation (e.g., '203.0.113.42/32') for SSH access to the EC2 instance."
  type        = string
}
