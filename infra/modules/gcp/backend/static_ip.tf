resource "google_compute_address" "api_ip" {
  project = var.gcp_project_id
  name    = "${local.service_name}-ip"
  region  = var.region

  depends_on = [google_project_service.google_compute_engine_api]
}
