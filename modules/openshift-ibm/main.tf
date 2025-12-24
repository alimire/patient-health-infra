terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~> 1.86.0"
    }
  }
}

resource "ibm_resource_instance" "cos" {
  name              = "${var.cluster_name}-cos"
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
  resource_group_id = var.resource_group_id
  tags              = [for k, v in var.tags : "${k}:${v}"]
}

resource "ibm_container_vpc_cluster" "this" {
  name              = var.cluster_name
  resource_group_id = var.resource_group_id
  vpc_id            = var.vpc_id
  flavor            = var.worker_flavor
  kube_version      = var.openshift_version
  cos_instance_crn  = ibm_resource_instance.cos.id
  tags              = [for k, v in var.tags : "${k}:${v}"]

  dynamic "zones" {
    for_each = range(length(var.zones))
    content {
      name      = var.zones[zones.value]
      subnet_id = var.private_subnet_ids[zones.value]
    }
  }

  # Configure default worker count (creates a default worker pool)
  worker_count = var.worker_count

  # Wait for the Ingress Controller to be ready before finishing.
  # This ensures the Console URL is available when Terraform completes.
  wait_till = "IngressReady"

  timeouts {
    create = "3h"
    delete = "2h"
  }
}
