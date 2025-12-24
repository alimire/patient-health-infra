# VPC Module Variables for IBM Cloud

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

variable "region" {
  description = "The IBM Cloud region to deploy resources in."
  type        = string
  default     = "us-south" # Common IBM Cloud VPC region
  validation {
    # This is a basic validation. A more robust one would check against a list of valid regions.
    condition     = length(var.region) > 0
    error_message = "The IBM Cloud region cannot be empty."
  }
}

variable "resource_group_id" {
  description = "The ID of the IBM Cloud resource group to provision resources into."
  type        = string
  # You might want to add validation here to ensure it's a valid UUID or resource group name
  # For simplicity, we'll just ensure it's not empty.
  validation {
    condition     = length(var.resource_group_id) > 0
    error_message = "The IBM Cloud resource group ID cannot be empty."
  }
}

variable "availability_zone_count" {
  description = "Number of availability zones to use. IBM Cloud VPC typically supports 3 zones per region."
  type        = number
  default     = 3
  validation {
    condition     = var.availability_zone_count >= 1 && var.availability_zone_count <= 3
    error_message = "Availability zone count for IBM Cloud VPC is typically between 1 and 3."
  }
}

variable "create_public_subnets" {
  description = "Create public subnets with a public gateway for internet access."
  type        = bool
  default     = true
}

variable "create_private_subnets" {
  description = "Create private subnets, optionally with a NAT Gateway for outbound internet access."
  type        = bool
  default     = true
}

variable "create_nat_gateway" {
  description = "Create a NAT Gateway for private subnets to access the internet."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
