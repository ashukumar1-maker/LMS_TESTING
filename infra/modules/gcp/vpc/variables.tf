# ---------- REQUIRED CONFIGURATION ----------

variable "gcp_project_id" {
  description = "The GCP project ID where resources will be created."
  type        = string
}

variable "region" {
  description = "The GCP region where subnetwork will be created."
  type        = string
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
}

# ---------- OPTIONAL CONFIGURATION ----------

variable "subnetwork_cidr" {
  description = "CIDR range for the subnetwork."
  type        = string
  default     = "10.0.0.0/24"
}

variable "backend_connector_subnetwork_cidr" {
  description = "CIDR range reserved for the future static backend egress subnet. Must be a /28."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.backend_connector_subnetwork_cidr)) && can(regex("/28$", var.backend_connector_subnetwork_cidr))
    error_message = "backend_connector_subnetwork_cidr must be a valid /28 CIDR range."
  }
}

variable "gke_subnetwork_cidr" {
  description = "Primary CIDR range for GKE nodes."
  type        = string
  default     = "10.2.0.0/24"
}

variable "gke_pods_secondary_range_name" {
  description = "Name of the secondary range used for GKE pods."
  type        = string
  default     = "gke-pods"
}

variable "gke_pods_secondary_cidr" {
  description = "Secondary CIDR range used for GKE pods."
  type        = string
  default     = "10.4.0.0/14"
}

variable "gke_services_secondary_range_name" {
  description = "Name of the secondary range used for GKE services."
  type        = string
  default     = "gke-services"
}

variable "gke_services_secondary_cidr" {
  description = "Secondary CIDR range used for GKE services."
  type        = string
  default     = "10.9.0.0/20"
}

variable "backend_egress_nat_ips" {
  description = "Reserved static external IP resources to use for backend Cloud NAT egress."
  type        = list(string)

  validation {
    condition     = length(var.backend_egress_nat_ips) >= 1
    error_message = "backend_egress_nat_ips must include at least one reserved static IP resource."
  }
}
