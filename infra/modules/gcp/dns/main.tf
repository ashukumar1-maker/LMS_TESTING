terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.47"
    }
  }
}

locals {
  description = var.description != "" ? var.description : "Cloud DNS for ${var.environment}"
  zone_name   = "${var.environment}-dns"
}

resource "google_project_service" "dns_api" {
  project                    = var.gcp_project_id
  service                    = "dns.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_dns_managed_zone" "primary" {
  project     = var.gcp_project_id
  name        = local.zone_name
  dns_name    = "${var.domain_name}."
  description = local.description

  # Prevent accidental deletion of DNS zone
  lifecycle {
    prevent_destroy = true
  }

  dynamic "dnssec_config" {
    for_each = var.enable_dnssec ? [1] : []
    content {
      state = "on"
      default_key_specs {
        algorithm  = "rsasha256"
        key_type   = "keySigning"
        key_length = 2048
      }
      default_key_specs {
        algorithm  = "rsasha256"
        key_type   = "zoneSigning"
        key_length = 1024
      }
    }
  }

  depends_on = [google_project_service.dns_api]
}

# A record for the root domain pointing to the frontend load balancer
resource "google_dns_record_set" "frontend" {
  project      = var.gcp_project_id
  managed_zone = google_dns_managed_zone.primary.name
  name         = google_dns_managed_zone.primary.dns_name
  type         = "A"
  ttl          = 300
  rrdatas      = [var.frontend_ip_address]
}

# CNAME record for www subdomain pointing to root domain
resource "google_dns_record_set" "www" {
  count        = var.enable_www_subdomain ? 1 : 0
  project      = var.gcp_project_id
  managed_zone = google_dns_managed_zone.primary.name
  name         = "www.${google_dns_managed_zone.primary.dns_name}"
  type         = "CNAME"
  ttl          = 300
  rrdatas      = [google_dns_managed_zone.primary.dns_name]
}

# A record for api subdomain pointing to the backend load balancer
resource "google_dns_record_set" "api" {
  count        = var.enable_api_subdomain ? 1 : 0
  project      = var.gcp_project_id
  managed_zone = google_dns_managed_zone.primary.name
  name         = "api.${google_dns_managed_zone.primary.dns_name}"
  type         = "A"
  ttl          = 300
  rrdatas      = [var.backend_ip_address]
}

# Data source to fetch DNSKEY records for DNSSEC
data "google_dns_keys" "dnssec_keys" {
  count        = var.enable_dnssec ? 1 : 0
  project      = var.gcp_project_id
  managed_zone = google_dns_managed_zone.primary.name

  depends_on = [google_dns_managed_zone.primary]
}
