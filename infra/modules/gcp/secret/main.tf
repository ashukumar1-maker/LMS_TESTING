terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.47"
    }
  }
}

locals {
  # Create a sanitized secret ID from the secret name
  secret_id = var.secret_prefix != "" ? "${var.environment}-${var.secret_prefix}-${replace(lower(var.secret_name), "_", "-")}" : "${var.environment}-${replace(lower(var.secret_name), "_", "-")}"

  # Merge default labels with user-provided labels
  default_labels = {
    environment = var.environment
    managed-by  = "terraform"
  }

  all_labels = merge(local.default_labels, var.labels)

  # Create a set of service accounts for easier iteration
  service_accounts_set = toset(var.service_account_emails)
}

# Create the secret
resource "google_secret_manager_secret" "secret" {
  project   = var.gcp_project_id
  secret_id = local.secret_id

  labels = local.all_labels

  replication {
    auto {
      # Automatically manage replication
    }
  }
}

# Create secret version that ignores changes (default behavior)
resource "google_secret_manager_secret_version" "secret_version_static" {
  count = var.ignore_secret_changes ? 1 : 0

  secret      = google_secret_manager_secret.secret.name
  secret_data = var.initial_secret_value

  lifecycle {
    # Ignore changes to secret data after initial creation
    # This prevents Terraform from trying to update secrets that may have been
    # manually rotated
    ignore_changes = [
      secret_data,
      enabled
    ]
  }
}

# Create secret version that updates when value changes
resource "google_secret_manager_secret_version" "secret_version_dynamic" {
  count = var.ignore_secret_changes ? 0 : 1

  secret      = google_secret_manager_secret.secret.name
  secret_data = var.initial_secret_value
}

# Grant each service account access to read the secret
resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  count = length(var.service_account_emails)

  project   = var.gcp_project_id
  secret_id = google_secret_manager_secret.secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.service_account_emails[count.index]}"

  depends_on = [
    google_secret_manager_secret_version.secret_version_static,
    google_secret_manager_secret_version.secret_version_dynamic
  ]
}
