# IBM Cloud Development Environment Stack
# Using the opinionated vpc-ibm module

terraform {
  required_version = ">= 1.0"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~> 1.86.0"
    }
  }
}

# Configure the IBM Cloud Provider
# The API key should be provided via the IC_API_KEY environment variable for security.
provider "ibm" {
  region = var.region
}

# Use our opinionated vpc-ibm module
module "vpc_ibm" {
  source = "./modules/vpc-ibm"

  name_prefix             = var.project_name
  environment             = var.environment
  region                  = var.region
  resource_group_id       = var.resource_group_id
  availability_zone_count = var.availability_zone_count

  # Development-specific settings (can be toggled to save costs)
  create_nat_gateway = true

  tags = {
    Project     = var.project_name
    Team        = "DevOps"
    CostCenter  = "Engineering"
  }
}
# VPC and subnets are created by module.vpc_ibm; use module outputs


module "openshift_ibm" {
  source = "./modules/openshift-ibm"

  vpc_id           = module.vpc_ibm.vpc_id
  private_subnet_ids = module.vpc_ibm.private_subnet_ids
  zones            = module.vpc_ibm.private_subnet_zones
  resource_group_id = var.resource_group_id
  cluster_name     = "${var.project_name}-ocp"
  openshift_version = "4.12"
  worker_flavor    = "bx2.4x16"
  worker_count     = 1
  tags = {
    Project     = var.project_name
    Team        = "DevOps"
    CostCenter  = "Engineering"
  }
}
