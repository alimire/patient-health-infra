output "cluster_id" {
  description = "The ID of the created OpenShift cluster"
  value       = ibm_container_vpc_cluster.this.id
}

output "name" {
  description = "The cluster name"
  value       = try(ibm_container_vpc_cluster.this.name, "")
}

output "crn" {
  description = "The CRN of the cluster"
  value       = try(ibm_container_vpc_cluster.this.crn, "")
}

output "api_endpoint" {
  description = "The API endpoint for the cluster"
  value       = try(ibm_container_vpc_cluster.this.master_url, "")
}
