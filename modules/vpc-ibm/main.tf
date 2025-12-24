# Production-Ready VPC Module for IBM Cloud

terraform {
  required_version = ">= 1.0"
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}

locals {
  common_tags_map = merge(
    var.tags,
    {
      module       = "vpc-ibm"
      environment  = var.environment
      "managed-by" = "terraform"
    }
  )

  common_tags = [for k, v in local.common_tags_map : "${k}:${v}"]
}

data "ibm_is_zones" "available" {
  region = var.region
}

# -----------------------------------------------
# VPC
# -----------------------------------------------
resource "ibm_is_vpc" "main" {
  name           = "${var.name_prefix}-vpc"
  resource_group = var.resource_group_id
  tags           = local.common_tags
}

# -----------------------------------------------
# Public Gateways (one per zone)
# -----------------------------------------------
resource "ibm_is_public_gateway" "main" {
  count = var.create_public_subnets ? var.availability_zone_count : 0

  name           = "${var.name_prefix}-pgw-${count.index + 1}"
  vpc            = ibm_is_vpc.main.id
  zone           = data.ibm_is_zones.available.zones[count.index]
  resource_group = var.resource_group_id
  tags           = local.common_tags
}

# -----------------------------------------------
# Public Subnets (one per zone)
# -----------------------------------------------
resource "ibm_is_subnet" "public" {
  count = var.create_public_subnets ? var.availability_zone_count : 0

  name                     = "${var.name_prefix}-public-subnet-${count.index + 1}"
  vpc                      = ibm_is_vpc.main.id
  zone                     = data.ibm_is_zones.available.zones[count.index]
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.main[count.index].id
  resource_group           = var.resource_group_id
  tags                     = local.common_tags
}

# -----------------------------------------------
# Private Subnets (still one per zone)
# -----------------------------------------------
resource "ibm_is_subnet" "private" {
  count = var.create_private_subnets ? var.availability_zone_count : 0

  name                     = "${var.name_prefix}-private-subnet-${count.index + 1}"
  vpc                      = ibm_is_vpc.main.id
  zone                     = data.ibm_is_zones.available.zones[count.index]
  total_ipv4_address_count = 256
  public_gateway           = var.create_nat_gateway ? ibm_is_public_gateway.main[count.index].id : null
  resource_group           = var.resource_group_id
  tags                     = local.common_tags
}
