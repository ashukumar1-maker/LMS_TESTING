// VPC network outputs
output "vpc_network_id" {
  description = "ID of the created VPC network."
  value       = google_compute_network.vpc_network.id
}

output "network_name" {
  description = "Name of the created VPC network."
  value       = google_compute_network.vpc_network.name
}

output "network_self_link" {
  description = "Self link of the created VPC network."
  value       = google_compute_network.vpc_network.self_link
}

output "private_ip_address_name" {
  description = "The name of the private IP address range for the Cloud SQL instance."
  value       = google_compute_global_address.private_ip_address.name
}

// Subnetwork outputs
output "subnetwork_id" {
  description = "ID of the created subnetwork."
  value       = google_compute_subnetwork.subnet.id
}

output "subnetwork_name" {
  description = "The name of the created subnetwork."
  value       = google_compute_subnetwork.subnet.name
}

output "subnetwork_ip_cidr_range" {
  description = "The IP CIDR range for the subnetwork."
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}

output "subnetwork_self_link" {
  description = "Self link of the created subnetwork."
  value       = google_compute_subnetwork.subnet.self_link
}

output "backend_connector_subnetwork_name" {
  description = "Name of the reserved static backend egress subnetwork."
  value       = google_compute_subnetwork.backend_connector.name
}

output "backend_connector_subnetwork_self_link" {
  description = "Self link of the reserved static backend egress subnetwork."
  value       = google_compute_subnetwork.backend_connector.self_link
}

output "gke_subnetwork_id" {
  description = "ID of the GKE subnetwork."
  value       = google_compute_subnetwork.gke_subnet.id
}

output "gke_subnetwork_name" {
  description = "The name of the GKE subnetwork."
  value       = google_compute_subnetwork.gke_subnet.name
}

output "gke_subnetwork_self_link" {
  description = "Self link of the GKE subnetwork."
  value       = google_compute_subnetwork.gke_subnet.self_link
}

output "gke_subnetwork_ip_cidr_range" {
  description = "The primary IP CIDR range for the GKE subnetwork."
  value       = google_compute_subnetwork.gke_subnet.ip_cidr_range
}

output "gke_pods_secondary_range_name" {
  description = "Name of the secondary range used for GKE pods."
  value       = var.gke_pods_secondary_range_name
}

output "gke_services_secondary_range_name" {
  description = "Name of the secondary range used for GKE services."
  value       = var.gke_services_secondary_range_name
}

output "peering_connection_id" {
  description = "ID of the created peering connection."
  value       = google_service_networking_connection.private_vpc_connection.id
}
