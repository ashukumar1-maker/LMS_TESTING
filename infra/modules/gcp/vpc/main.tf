terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.47"
    }
  }
}

resource "google_project_service" "compute_api" {
  project                    = var.gcp_project_id
  service                    = "compute.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_compute_network" "vpc_network" {
  project = var.gcp_project_id

  # The random name here helps avoid transient errors
  name                    = "${var.environment}-vpc-${substr(uuid(), 0, 4)}"
  auto_create_subnetworks = false

  lifecycle {
    ignore_changes = [name]
  }

  depends_on = [
    google_project_service.compute_api,
  ]

}

resource "google_compute_subnetwork" "subnet" {
  project                  = var.gcp_project_id
  name                     = "${var.environment}-subnet"
  ip_cidr_range            = var.subnetwork_cidr
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "backend_connector" {
  project                  = var.gcp_project_id
  name                     = "${var.environment}-backend-connector-subnet"
  ip_cidr_range            = var.backend_connector_subnetwork_cidr
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "gke_subnet" {
  project                  = var.gcp_project_id
  name                     = "${var.environment}-gke-subnet"
  ip_cidr_range            = var.gke_subnetwork_cidr
  region                   = var.region
  network                  = google_compute_network.vpc_network.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = var.gke_pods_secondary_range_name
    ip_cidr_range = var.gke_pods_secondary_cidr
  }

  secondary_ip_range {
    range_name    = var.gke_services_secondary_range_name
    ip_cidr_range = var.gke_services_secondary_cidr
  }
}

resource "google_compute_router" "backend_egress_nat" {
  project = var.gcp_project_id
  name    = "${var.environment}-backend-egress-router"
  network = google_compute_network.vpc_network.id
  region  = var.region
}

resource "google_compute_router_nat" "backend_egress" {
  project = var.gcp_project_id
  name    = "${var.environment}-backend-egress-nat"
  router  = google_compute_router.backend_egress_nat.name
  region  = var.region

  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = var.backend_egress_nat_ips
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  # Only backend Cloud Run connector egress is NATed through the reserved static IPs.
  subnetwork {
    name                    = google_compute_subnetwork.backend_connector.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_compute_router" "gke_egress_nat" {
  project = var.gcp_project_id
  name    = "${var.environment}-gke-egress-router"
  network = google_compute_network.vpc_network.id
  region  = var.region
}

resource "google_compute_router_nat" "gke_egress" {
  project = var.gcp_project_id
  name    = "${var.environment}-gke-egress-nat"
  router  = google_compute_router.gke_egress_nat.name
  region  = var.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  # Private GKE nodes need outbound internet for public chart/controller images.
  # Backend allowlisted static egress should use a later workload-specific path.
  subnetwork {
    name                    = google_compute_subnetwork.gke_subnet.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

# Reserve IP range for private service access for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  project       = var.gcp_project_id
  name          = "${var.environment}-sql-private-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}

# Enable Service Networking API for private service connections
resource "google_project_service" "servicenetworking" {
  project = var.gcp_project_id
  service = "servicenetworking.googleapis.com"
}

# Create VPC peering connection for Cloud SQL
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
  depends_on = [
    google_project_service.servicenetworking,
    # The service networking connection may conflict with hardcoded subnet CIDR
    # ranges if it happens to provision first.
    google_compute_subnetwork.subnet,
    google_compute_subnetwork.gke_subnet
  ]
}

# Allow PostgreSQL traffic to the Cloud SQL private IP range from the subnetwork
resource "google_compute_firewall" "allow_postgres" {
  project = var.gcp_project_id
  name    = "${var.environment}-allow-postgres"
  network = google_compute_network.vpc_network.id

  direction = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges      = ["0.0.0.0/0"] # Allows any IP address
  destination_ranges = ["${google_compute_global_address.private_ip_address.address}/${google_compute_global_address.private_ip_address.prefix_length}"]
  depends_on         = [google_compute_global_address.private_ip_address]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}
