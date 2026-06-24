locals {
  is_deploying_cloud_sql_canary = !var.is_dev

  canary_db_instance_name = "${var.environment}-cross-project-db"
  canary_db_name          = "cross_project_db"
  canary_db_user_name     = "cross_project_db_user"
  canary_db_public_ip     = local.is_deploying_cloud_sql_canary ? google_sql_database_instance.sensitive_canary[0].public_ip_address : null
  sensitive_db_url        = local.is_deploying_cloud_sql_canary ? "postgresql://${google_sql_user.sensitive_canary[0].name}:${random_password.sensitive_canary_db_password[0].result}@${local.canary_db_public_ip}:5432/${google_sql_database.sensitive_canary[0].name}?sslmode=require" : null
}

resource "google_project_service" "sql_api" {
  count = local.is_deploying_cloud_sql_canary ? 1 : 0

  project                    = var.gcp_project_id
  service                    = "sqladmin.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "random_password" "sensitive_canary_db_password" {
  count = local.is_deploying_cloud_sql_canary ? 1 : 0

  length  = 30
  special = false
}

resource "google_sql_database_instance" "sensitive_canary" {
  count = local.is_deploying_cloud_sql_canary ? 1 : 0

  project          = var.gcp_project_id
  name             = local.canary_db_instance_name
  region           = var.region
  database_version = "POSTGRES_17"

  settings {
    edition   = "ENTERPRISE"
    tier      = "db-f1-micro"
    disk_size = 10
    disk_type = "PD_HDD"

    ip_configuration {
      ipv4_enabled = true
      ssl_mode     = "ENCRYPTED_ONLY"

      authorized_networks {
        name  = "canary-open"
        value = "0.0.0.0/0"
      }
    }

    backup_configuration {
      enabled = false
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    database_flags {
      name  = "log_hostname"
      value = "off"
    }

    database_flags {
      name  = "log_line_prefix"
      value = "%m [%p]: user=%u,db=%d,app=%a,client=%h "
    }
  }

  deletion_protection = false

  depends_on = [google_project_service.sql_api]
}

resource "google_sql_database" "sensitive_canary" {
  count = local.is_deploying_cloud_sql_canary ? 1 : 0

  project  = var.gcp_project_id
  instance = google_sql_database_instance.sensitive_canary[0].name
  name     = local.canary_db_name
}

resource "google_sql_user" "sensitive_canary" {
  count = local.is_deploying_cloud_sql_canary ? 1 : 0

  project  = var.gcp_project_id
  instance = google_sql_database_instance.sensitive_canary[0].name
  name     = local.canary_db_user_name
  password = random_password.sensitive_canary_db_password[0].result
}
