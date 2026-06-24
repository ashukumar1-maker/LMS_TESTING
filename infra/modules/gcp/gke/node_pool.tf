resource "google_container_node_pool" "default" {
  provider = google-beta
  project  = var.gcp_project_id
  name     = "${var.environment}-default"
  location = google_container_cluster.default.location
  cluster  = google_container_cluster.default.name

  node_locations     = local.node_locations
  initial_node_count = local.node_pool_initial_node_count

  autoscaling {
    min_node_count = local.node_pool_min_node_count
    max_node_count = local.node_pool_max_node_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type    = var.node_machine_type
    disk_size_gb    = var.node_disk_size_gb
    disk_type       = var.node_disk_type
    service_account = google_service_account.node.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = {
      environment = var.environment
    }

    tags = [
      "${var.environment}-gke-node",
    ]
  }

  depends_on = [
    google_project_iam_member.node_default_service_account,
    google_project_iam_member.node_log_writer,
    google_project_iam_member.node_metric_writer,
    google_project_iam_member.node_monitoring_viewer,
    google_project_iam_member.node_artifact_registry_reader,
  ]
}
