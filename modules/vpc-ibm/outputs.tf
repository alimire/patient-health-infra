output "vpc_id" {
  description = "ID of the created VPC"
  value       = ibm_is_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = ibm_is_subnet.private[*].id
}

output "private_subnet_zones" {
  description = "Zones for the private subnets"
  value       = ibm_is_subnet.private[*].zone
}
