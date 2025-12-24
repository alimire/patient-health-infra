# Staging Environment Variables

variable "ibmcloud_api_key" {
  description = "The IBM Cloud API key."
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "The name of the project, used as a prefix for resources."
  type        = string
  default     = "ibm-openshift-demo-staging"
}

variable "environment" {
  description = "The deployment environment."
  type        = string
  default     = "staging"
}

variable "region" {
  description = "The IBM Cloud region to deploy to."
  type        = string
  default     = "us-south"
}

variable "resource_group_id" {
  description = "The ID of the IBM Cloud Resource Group to deploy resources into."
  type        = string
}

variable "availability_zone_count" {
  description = "Number of availability zones to create subnets in."
  type        = number
  default     = 3
}