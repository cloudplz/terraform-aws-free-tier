# VPC — VPCs are free.
# ⚠️ NAT gateways are NOT created here — they cost ~$32/month each.
# Private subnets intentionally have no outbound internet access.

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true # Required for RDS endpoint resolution
  enable_dns_support   = true

  lifecycle {
    precondition {
      condition     = length(local.azs) == var.az_count
      error_message = "az_count exceeds the number of available AZs in the configured AWS region/account."
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name}-vpc"
  })
}

# Internet Gateway — allows public subnets to reach the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

# Public subnets — EC2 lives here, has direct internet access via IGW
resource "aws_subnet" "public" {
  for_each = toset(local.azs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, index(local.azs, each.value) + 1)
  availability_zone = each.value

  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name}-public-${each.value}"
  })
}

# Private subnets — RDS, Aurora, and ElastiCache live here, no internet access
# ⚠️ Without a NAT gateway, resources in private subnets cannot reach the internet
resource "aws_subnet" "private" {
  for_each = toset(local.azs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, index(local.azs, each.value) + 101)
  availability_zone = each.value

  tags = merge(var.tags, {
    Name = "${var.name}-private-${each.value}"
  })
}

# Route table for public subnets — routes 0.0.0.0/0 to the IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
