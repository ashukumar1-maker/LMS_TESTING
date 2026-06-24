terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.47"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

locals {
  instance_name     = "${var.environment}-db"
  effective_db_name = var.db_name == "default-db" ? "${var.environment}-db" : var.db_name
  effective_tier    = var.is_dev ? "db-f1-micro" : var.tier
  # Keep automated backups in overnight US hours, using region-aware defaults.
  region_default_backup_start_time = (
    startswith(var.region, "us-east") ? "08:00" :
    startswith(var.region, "us-") ? "09:00" :
    "03:00"
  )
  effective_backup_start_time = coalesce(var.backup_start_time, local.region_default_backup_start_time)
}

resource "google_project_service" "sql_api" {
  project                    = var.gcp_project_id
  service                    = "sqladmin.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "servicenetworking_api" {
  project                    = var.gcp_project_id
  service                    = "servicenetworking.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "random_password" "db_user_password" {
  count   = var.db_user_password == null ? 1 : 0
  length  = 26
  special = false
}

resource "google_sql_database_instance" "default" {
  project          = var.gcp_project_id
  name             = local.instance_name
  region           = var.region
  database_version = var.database_version

  settings {
    edition = var.database_edition
    tier    = local.effective_tier
    backup_configuration {
      enabled                        = var.backup_enabled
      start_time                     = local.effective_backup_start_time
      point_in_time_recovery_enabled = var.backup_enabled && var.point_in_time_recovery_enabled
      transaction_log_retention_days = var.backup_enabled && var.point_in_time_recovery_enabled ? var.transaction_log_retention_days : null

      backup_retention_settings {
        retained_backups = var.backup_enabled ? var.retained_backups : null
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled                                  = false # Disable public IP
      private_network                               = var.vpc_network_id
      allocated_ip_range                            = var.private_ip_address_name
      enable_private_path_for_google_cloud_services = true
      ssl_mode                                      = "ENCRYPTED_ONLY"
    }
  }

  deletion_protection = var.is_dev ? false : true

  depends_on = [
    google_project_service.sql_api,
    google_project_service.servicenetworking_api,
  ]
}

resource "google_sql_database" "default" {
  project  = var.gcp_project_id
  instance = google_sql_database_instance.default.name
  name     = local.effective_db_name # Use local variable for db name
}

resource "google_sql_user" "default" {
  project  = var.gcp_project_id
  instance = google_sql_database_instance.default.name
  name     = var.db_user_name
  password = coalesce(var.db_user_password, random_password.db_user_password[0].result)
}
