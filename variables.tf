variable "aws_region" {
  description = "AWS region to deploy all resources into. us-east-1 has the broadest free plan coverage."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name prefix applied to every resource and used in default_tags. Keep it short (≤20 chars)."
  type        = string

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 20 && can(regex("^[a-z][a-z0-9-]*$", var.name))
    error_message = "name must be 1-20 lowercase alphanumeric characters or hyphens, starting with a letter."
  }
}

variable "db_username" {
  description = "Master username for RDS PostgreSQL and Aurora. Avoid reserved words like 'admin' or 'postgres'."
  type        = string
  default     = "dbadmin"
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR notation (e.g., '203.0.113.42/32') for SSH access to the EC2 instance. Only needed when key_name is set."
  type        = string
  default     = null

  validation {
    condition     = var.my_ip_cidr == null || can(cidrhost(var.my_ip_cidr, 0))
    error_message = "my_ip_cidr must be null or a valid CIDR block (e.g., '203.0.113.42/32')."
  }
}

variable "notification_email" {
  description = "Email for SNS alerts and Budgets notifications. Set to null to skip email notifications."
  type        = string
  default     = null

  validation {
    condition     = var.notification_email == null || can(regex("^[^@]+@[^@]+\\.[^@]+$", var.notification_email))
    error_message = "notification_email must be null or a valid email address."
  }
}

variable "key_name" {
  description = "EC2 key pair name for SSH access. Set to null to disable SSH (use SSM Session Manager instead)."
  type        = string
  default     = null
}

# ─── Networking ──────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Default /16 provides room for 256 /24 subnets."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition = (
      can(cidrhost(var.vpc_cidr, 0)) &&
      tonumber(split("/", var.vpc_cidr)[1]) <= 20
    )
    error_message = "vpc_cidr must be a valid IPv4 CIDR block with prefix <= /20 so Terraform can derive valid public and private subnets."
  }
}

variable "az_count" {
  description = "Number of availability zones for subnet placement (2 is sufficient for most free-tier workloads)."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 4
    error_message = "az_count must be between 2 and 4."
  }
}

# ─── Instance / size overrides ───────────────────────────────────────────────
# All defaults are at the free-plan maximum. Override only if you are willing
# to accept potential charges after your credits expire.

variable "ec2_instance_type" {
  description = "EC2 instance type. Must be a t-family type to stay within the free plan."
  type        = string
  default     = "t4g.micro"

  validation {
    condition     = can(regex("^t[0-9]+[a-z]*\\.", var.ec2_instance_type))
    error_message = "ec2_instance_type must be a t-family instance type (e.g., t4g.micro, t3.micro)."
  }
}

variable "ec2_volume_size_gb" {
  description = "Root EBS volume size in GB. Free plan covers up to 30 GB total EBS storage."
  type        = number
  default     = 30

  validation {
    condition     = var.ec2_volume_size_gb <= 30
    error_message = "ec2_volume_size_gb must be <= 30 to stay within the free plan EBS allowance."
  }
}

variable "rds_instance_class" {
  description = "RDS instance class. Must be db.t3.micro or db.t4g.micro for free plan eligibility."
  type        = string
  default     = "db.t4g.micro"

  validation {
    condition     = contains(["db.t3.micro", "db.t4g.micro"], var.rds_instance_class)
    error_message = "rds_instance_class must be db.t3.micro or db.t4g.micro."
  }
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB. Free plan covers up to 20 GB."
  type        = number
  default     = 20

  validation {
    condition     = var.rds_allocated_storage <= 20
    error_message = "rds_allocated_storage must be <= 20 to stay within the free plan storage allowance."
  }
}

variable "aurora_min_capacity" {
  description = "Aurora Serverless v2 minimum ACU capacity. Must be >= 0.5 (platform minimum)."
  type        = number
  default     = 0.5

  validation {
    condition     = var.aurora_min_capacity >= 0.5
    error_message = "aurora_min_capacity must be >= 0.5 (Aurora Serverless v2 minimum)."
  }
}

variable "aurora_max_capacity" {
  description = "Aurora Serverless v2 maximum ACU capacity. Free plan cap is 4 ACUs — do not exceed."
  type        = number
  default     = 4.0

  validation {
    condition     = var.aurora_max_capacity <= 4.0
    error_message = "aurora_max_capacity must be <= 4.0 to stay within the free plan cap."
  }
}

variable "lambda_memory_mb" {
  description = "Lambda function memory in MB. 128 MB maximizes free tier GB-seconds (400K GB-sec/month)."
  type        = number
  default     = 128

  validation {
    condition     = var.lambda_memory_mb <= 128
    error_message = "lambda_memory_mb must be <= 128 to maximize free tier GB-seconds."
  }
}

variable "elasticache_node_type" {
  description = "ElastiCache node type. Must be cache.t3.micro — the only free-plan eligible ElastiCache node type."
  type        = string
  default     = "cache.t3.micro"

  validation {
    condition     = var.elasticache_node_type == "cache.t3.micro"
    error_message = "elasticache_node_type must be cache.t3.micro (the only free-plan eligible ElastiCache node type; cache.t4g.micro is NOT free-plan eligible)."
  }
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days. Must be a valid CloudWatch retention period value."
  type        = number
  default     = 7

  validation {
    condition = contains(
      [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.log_retention_days
    )
    error_message = "log_retention_days must be a valid CloudWatch retention period value."
  }
}

variable "tags" {
  description = "Additional tags merged onto all resources."
  type        = map(string)
  default     = {}
}

# ─── Feature toggles ─────────────────────────────────────────────────────────
# Core services (VPC, EC2, Lambda, S3, DynamoDB, SQS, SNS, IAM, CloudWatch,
# Budgets) are always created and cannot be disabled.

variable "features" {
  description = <<-EOT
    Toggle optional AWS services on or off. Omit entirely to enable all defaults.
    Core services (VPC, EC2, Lambda, S3, DynamoDB, SQS, SNS, IAM, CloudWatch,
    Budgets) are always created and cannot be disabled.
  EOT
  type = object({
    rds             = optional(bool, true)
    aurora          = optional(bool, true)
    elasticache     = optional(bool, true)
    cloudfront      = optional(bool, true)
    cognito         = optional(bool, true)
    step_functions  = optional(bool, true)
    bedrock_logging = optional(bool, true)
  })
  default = {}

  validation {
    condition     = !var.features.elasticache || var.features.rds || var.features.aurora
    error_message = "ElastiCache requires a DB subnet group; enable features.rds or features.aurora."
  }
}
