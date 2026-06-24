resource "google_compute_backend_bucket" "frontend" {
  name        = "${var.environment}-frontend-backend"
  bucket_name = google_storage_bucket.frontend.name
  enable_cdn  = true

  depends_on = [
    google_project_service.compute_api,
  ]
}

resource "google_compute_url_map" "frontend" {
  name            = "${var.environment}-frontend-url-map"
  default_service = google_compute_backend_bucket.frontend.self_link

  host_rule {
    hosts        = ["*"]
    path_matcher = "all-paths"
  }

  path_matcher {
    name            = "all-paths"
    default_service = google_compute_backend_bucket.frontend.self_link

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_bucket.frontend.self_link
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_target_http_proxy" "frontend" {
  name    = "${var.environment}-frontend-http-proxy"
  url_map = google_compute_url_map.frontend.self_link
}

resource "google_compute_global_forwarding_rule" "frontend" {
  name                  = "${var.environment}-frontend-forwarding-rule"
  target                = google_compute_target_http_proxy.frontend.self_link
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.frontend_ip.address
}

resource "google_compute_managed_ssl_certificate" "frontend" {
  name = "${var.environment}-frontend-ssl-cert"
  managed {
    domains = [var.domain_name]
  }

  depends_on = [
    google_project_service.compute_api,
  ]
}

resource "google_compute_target_https_proxy" "frontend" {
  name             = "${var.environment}-frontend-https-proxy"
  url_map          = google_compute_url_map.frontend.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.frontend.self_link]
}

resource "google_compute_global_forwarding_rule" "frontend_https" {
  name                  = "${var.environment}-frontend-forwarding-rule-https"
  target                = google_compute_target_https_proxy.frontend.self_link
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.frontend_ip.address
}

resource "google_compute_global_address" "frontend_ip" {
  name = "${var.environment}-frontend-static-ip"

  depends_on = [
    google_project_service.compute_api,
  ]
}
