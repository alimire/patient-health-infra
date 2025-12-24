# Staging Environment Stack
# This file defines the resources for the 'staging' environment.

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
provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
}

# Use our opinionated vpc-ibm module
module "vpc_ibm" {
  source = "../../modules/vpc-ibm"

  name_prefix             = var.project_name
  environment             = var.environment
  region                  = var.region
  resource_group_id       = var.resource_group_id
  availability_zone_count = var.availability_zone_count
  
  # Ensure Public Gateways are created for staging as well
  create_nat_gateway      = true 
  tags                    = {}
}

# Use our opinionated openshift-ibm module
module "openshift_ibm" {
  source = "../../modules/openshift-ibm"

  vpc_id             = module.vpc_ibm.vpc_id
  private_subnet_ids = module.vpc_ibm.private_subnet_ids
  zones              = module.vpc_ibm.private_subnet_zones
  resource_group_id  = var.resource_group_id
  cluster_name       = "${var.project_name}-ocp"
  openshift_version  = "4.19"
  worker_flavor      = "bx2.4x16"
  worker_count       = 1 # You might want 2 or 3 for staging/prod
  tags               = {}
}