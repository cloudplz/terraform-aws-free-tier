# VPC — terraform-aws-modules/vpc
# Free tier: VPCs themselves are free. The NAT gateway is the #1 surprise bill
# for free-tier users (~$32/month). We explicitly disable it here.
# ⚠️ enable_nat_gateway = true would add ~$32/month per gateway
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  # NO NAT gateway — enabling this is the #1 surprise bill for free tier users
  enable_nat_gateway = false # ⚠️ setting true adds ~$32/month per gateway

  # DNS settings required for RDS and other services
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}
