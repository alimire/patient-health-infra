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
