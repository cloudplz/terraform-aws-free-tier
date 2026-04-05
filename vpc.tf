# VPC — VPCs are free.
# ⚠️ NAT gateways are NOT created here — they cost ~$32/month each.
# Private subnets intentionally have no outbound internet access.

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true  # Required for RDS endpoint resolution
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
  })
}

# Internet Gateway — allows public subnets to reach the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name    = "${var.project_name}-igw"
    Project = var.project_name
  })
}

# Public subnets — EC2 lives here, has direct internet access via IGW
resource "aws_subnet" "public" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name    = "${var.project_name}-public-${count.index + 1}"
    Project = var.project_name
  })
}

# Private subnets — RDS, Aurora, and ElastiCache live here, no internet access
# ⚠️ Without a NAT gateway, resources in private subnets cannot reach the internet
resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 101}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name    = "${var.project_name}-private-${count.index + 1}"
    Project = var.project_name
  })
}

# Route table for public subnets — routes 0.0.0.0/0 to the IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name    = "${var.project_name}-public-rt"
    Project = var.project_name
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
