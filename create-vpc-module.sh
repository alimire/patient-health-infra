#!/bin/bash
# Create Production-Ready VPC Module

set -e

echo "🌐 Creating Production-Ready VPC Module"

# Ensure we're in the right directory
if [ ! -f "setup-opinionated-terraform.sh" ]; then
    echo "❌ Please run this from the exercise-3-opinionated-terraform directory"
    exit 1
fi

# Create VPC module structure
echo "📁 Creating VPC module structure..."
mkdir -p modules/vpc/{examples,test}

# Create main VPC module
echo "📝 Creating VPC module main.tf..."
cat > modules/vpc/main.tf << 'EOF'
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
EOF

echo "📝 Creating VPC module variables.tf..."
cat > modules/vpc/variables.tf << 'EOF'
# VPC Module Variables

variable "name_prefix" {
  description = "Name prefix for all resources"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.name_prefix))
    error_message = "Name prefix must contain only alphanumeric characters and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod", "local"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, local."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zone_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
  validation {
    condition     = var.availability_zone_count >= 2 && var.availability_zone_count <= 6
    error_message = "Availability zone count must be between 2 and 6."
  }
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "create_igw" {
  description = "Create Internet Gateway"
  type        = bool
  default     = true
}

variable "create_public_subnets" {
  description = "Create public subnets"
  type        = bool
  default     = true
}

variable "create_private_subnets" {
  description = "Create private subnets"
  type        = bool
  default     = true
}

variable "create_database_subnets" {
  description = "Create database subnets"
  type        = bool
  default     = false
}

variable "map_public_ip_on_launch" {
  description = "Map public IP on launch for public subnets"
  type        = bool
  default     = true
}

variable "create_nat_gateways" {
  description = "Create NAT Gateways"
  type        = bool
  default     = true
}

variable "nat_gateway_count" {
  description = "Number of NAT Gateways to create"
  type        = number
  default     = 2
  validation {
    condition     = var.nat_gateway_count >= 1 && var.nat_gateway_count <= 6
    error_message = "NAT Gateway count must be between 1 and 6."
  }
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "flow_logs_iam_role_arn" {
  description = "IAM role ARN for VPC Flow Logs"
  type        = string
  default     = ""
}

variable "flow_logs_destination_arn" {
  description = "Destination ARN for VPC Flow Logs"
  type        = string
  default     = ""
}

variable "flow_logs_traffic_type" {
  description = "Traffic type for VPC Flow Logs"
  type        = string
  default     = "ALL"
  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_logs_traffic_type)
    error_message = "Flow logs traffic type must be one of: ACCEPT, REJECT, ALL."
  }
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
EOF

echo "📝 Creating VPC module outputs.tf..."
cat > modules/vpc/outputs.tf << 'EOF'
# VPC Module Outputs

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = var.create_igw ? aws_internet_gateway.main[0].id : null
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = aws_subnet.database[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "database_subnet_cidrs" {
  description = "CIDR blocks of the database subnets"
  value       = aws_subnet.database[*].cidr_block
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_public_ips" {
  description = "Public IPs of the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = var.create_public_subnets ? aws_route_table.public[0].id : null
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = aws_route_table.private[*].id
}

output "database_route_table_id" {
  description = "ID of the database route table"
  value       = var.create_database_subnets ? aws_route_table.database[0].id : null
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = data.aws_availability_zones.available.names
}

output "region" {
  description = "AWS region"
  value       = data.aws_region.current.name
}
EOF

echo "✅ VPC module created successfully!"
echo ""
echo "📋 Next steps:"
echo "  1. Review the module: ls -la modules/vpc/"
echo "  2. Create an example: ./create-vpc-example.sh"
echo "  3. Run tests: make test-unit"
echo "  4. Generate docs: make docs"