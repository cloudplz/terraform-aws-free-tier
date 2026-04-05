# Resolve the latest Amazon Linux 2023 AMI via SSM parameter.
# Using SSM parameter instead of aws_ami data source filters ensures
# a single, deterministic AMI ID from the official AWS parameter store.
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.18-x86_64"
}

# Current AWS region and available AZs for subnet placement.
data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}
