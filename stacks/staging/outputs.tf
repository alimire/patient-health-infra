# Staging Environment Outputs

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc_ibm.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc_ibm.private_subnet_ids
}

output "cluster_name" {
  description = "Name of the OpenShift cluster"
  value       = "${var.project_name}-ocp"
}