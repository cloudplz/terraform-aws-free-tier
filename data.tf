# Resolve the latest Amazon Linux 2023 ARM64 AMI via SSM parameter.
# arm64 path matches t4g.micro (Graviton2 ARM) used in ec2.tf.
# Using kernel-default avoids pinning to a specific kernel version.
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

# Current AWS region and available AZs for subnet placement.
data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}
