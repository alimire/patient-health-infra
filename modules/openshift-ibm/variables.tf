variable "vpc_id" {
  description = "The ID of the VPC to deploy the cluster into"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs to attach worker pools to (one per zone)"
  type        = list(string)
}

variable "zones" {
  description = "List of zones to place worker pools in"
  type        = list(string)
}

variable "resource_group_id" {
  description = "The IBM Cloud Resource Group ID"
  type        = string
}

variable "cluster_name" {
  description = "The name of the OpenShift (ROKS) cluster to create"
  type        = string
}

variable "openshift_version" {
  description = "OpenShift version to use for the cluster"
  type        = string
}

variable "worker_flavor" {
  description = "Instance flavor for worker nodes"
  type        = string
}

variable "worker_count" {
  description = "Number of worker nodes per zone"
  type        = number
}

variable "tags" {
  description = "Tags to apply to the cluster"
  type        = map(string)
  default     = {}
}
