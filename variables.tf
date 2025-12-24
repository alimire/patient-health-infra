# Input variables for the IBM Cloud Development Stack

variable "project_name" {
  description = "The name of the project, used as a prefix for resources."
  type        = string
  default     = "ibm-openshift-demo"
}

variable "environment" {
  description = "The deployment environment."
  type        = string
  default     = "dev"
}

variable "region" {
  description = "The IBM Cloud region to deploy to."
  type        = string
  default     = "us-south"
}

variable "resource_group_id" {
  description = "The ID of the IBM Cloud Resource Group to deploy resources into. This must be provided."
  type        = string
  # No default value, forcing the user to provide it.
}

variable "availability_zone_count" {
  description = "Number of availability zones to create subnets in."
  type        = number
  default     = 3
}