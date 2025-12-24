# Production-Ready VPC Module
# Based on opinionated Terraform best practices

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  # Calculate subnet CIDRs automatically
  public_subnet_cidrs  = [for i in range(var.availability_zone_count) : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnet_cidrs = [for i in range(var.availability_zone_count) : cidrsubnet(var.vpc_cidr, 8, i + 10)]
  db_subnet_cidrs      = [for i in range(var.availability_zone_count) : cidrsubnet(var.vpc_cidr, 8, i + 20)]

  # Common tags
  common_tags = merge(
    var.tags,
    {
      Module      = "vpc"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  count = var.create_igw ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-igw"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = var.create_public_subnets ? var.availability_zone_count : 0

  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-public-subnet-${count.index + 1}"
    Type = "public"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count = var.create_private_subnets ? var.availability_zone_count : 0

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-private-subnet-${count.index + 1}"
    Type = "private"
  })
}

# Database Subnets
resource "aws_subnet" "database" {
  count = var.create_database_subnets ? var.availability_zone_count : 0

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.db_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-db-subnet-${count.index + 1}"
    Type = "database"
  })
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = var.create_nat_gateways ? var.nat_gateway_count : 0

  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-nat-eip-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count = var.create_nat_gateways ? var.nat_gateway_count : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-nat-gateway-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  count = var.create_public_subnets ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

resource "aws_route_table" "private" {
  count = var.create_private_subnets ? var.nat_gateway_count : 0

  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-private-rt-${count.index + 1}"
  })
}

resource "aws_route_table" "database" {
  count = var.create_database_subnets ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-db-rt"
  })
}

# Routes
resource "aws_route" "public_internet_gateway" {
  count = var.create_public_subnets && var.create_igw ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main[0].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "private_nat_gateway" {
  count = var.create_private_subnets && var.create_nat_gateways ? var.nat_gateway_count : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id

  timeouts {
    create = "5m"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = var.create_public_subnets ? var.availability_zone_count : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "private" {
  count = var.create_private_subnets ? var.availability_zone_count : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index % var.nat_gateway_count].id
}

resource "aws_route_table_association" "database" {
  count = var.create_database_subnets ? var.availability_zone_count : 0

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[0].id
}

# VPC Flow Logs (Security Best Practice)
resource "aws_flow_log" "vpc" {
  count = var.enable_flow_logs ? 1 : 0

  iam_role_arn    = var.flow_logs_iam_role_arn
  log_destination = var.flow_logs_destination_arn
  traffic_type    = var.flow_logs_traffic_type
  vpc_id          = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-flow-logs"
  })
}
