resource "google_container_cluster" "default" {
  provider = google-beta
  project  = var.gcp_project_id
  name     = local.cluster_name
  location = var.region

  network    = var.network_self_link
  subnetwork = var.subnetwork_self_link

  deletion_protection = var.cluster_deletion_protection
  node_locations      = local.node_locations

  remove_default_node_pool = true
  initial_node_count       = 1
  networking_mode          = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes    = true
  }

  master_authorized_networks_config {
    private_endpoint_enforcement_enabled = true

    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks

      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  workload_identity_config {
    workload_pool = local.workload_identity_pool
  }

  release_channel {
    channel = var.release_channel
  }

  addons_config {
    gcs_fuse_csi_driver_config {
      enabled = true
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [
    google_project_service.container_api,
  ]
}

resource "google_gke_hub_membership" "default" {
  project       = var.gcp_project_id
  location      = "global"
  membership_id = local.cluster_name

  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${google_container_cluster.default.id}"
    }
  }

  authority {
    issuer = "https://container.googleapis.com/v1/${google_container_cluster.default.id}"
  }

  depends_on = [
    google_project_service.gkehub_api,
    google_project_service.gkeconnect_api,
    google_project_service.connectgateway_api,
    google_container_node_pool.default,
  ]
}
