terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.47"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.47"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

locals {
  api_url = "https://api.${var.domain_name}"
}

resource "google_project_service" "compute_api" {
  project                    = var.gcp_project_id
  service                    = "compute.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_compute_address" "backend_egress_ips" {
  count = var.backend_egress_static_ip_count

  project      = var.gcp_project_id
  name         = "${var.environment}-backend-egress-${count.index + 1}"
  address_type = "EXTERNAL"
  region       = var.region
  depends_on   = [google_project_service.compute_api]

  lifecycle {
    prevent_destroy = true
  }
}

module "vpc" {
  source = "../vpc"

  gcp_project_id                    = var.gcp_project_id
  region                            = var.region
  environment                       = var.environment
  backend_connector_subnetwork_cidr = var.backend_connector_subnetwork_cidr
  backend_egress_nat_ips            = google_compute_address.backend_egress_ips[*].self_link
}

module "gke" {
  source = "../gke"

  gcp_project_id = var.gcp_project_id
  region         = var.region
  environment    = var.environment
  is_dev         = var.is_dev

  network_self_link             = module.vpc.network_self_link
  subnetwork_self_link          = module.vpc.gke_subnetwork_self_link
  pods_secondary_range_name     = module.vpc.gke_pods_secondary_range_name
  services_secondary_range_name = module.vpc.gke_services_secondary_range_name
  cluster_deletion_protection   = !var.is_dev

  master_authorized_networks = [
    {
      cidr_block   = module.vpc.gke_subnetwork_ip_cidr_range
      display_name = "gke-nodes"
    },
    {
      cidr_block   = module.vpc.subnetwork_ip_cidr_range
      display_name = "app-subnet"
    },
  ]

  providers = {
    google      = google
    google-beta = google-beta
  }
}

module "database" {
  source = "../database"

  gcp_project_id            = var.gcp_project_id
  region                    = var.region
  environment               = var.environment
  vpc_network_id            = module.vpc.vpc_network_id
  vpc_peering_connection_id = module.vpc.peering_connection_id
  private_ip_address_name   = module.vpc.private_ip_address_name

  is_dev = var.is_dev

  depends_on = [
    module.vpc,
  ]
}

module "storage" {
  source = "../storage"

  gcp_project_id = var.gcp_project_id
  project_id     = var.project_id
  region         = var.region
  environment    = var.environment

  is_dev       = var.is_dev
  frontend_url = var.domain_name
}

module "access_canaries" {
  source = "../access_canaries"

  gcp_project_id = var.gcp_project_id
  project_id     = var.project_id
  region         = var.region
  environment    = var.environment
  is_dev         = var.is_dev
}

module "backend_service" {
  source = "../backend"

  gcp_project_id           = var.gcp_project_id
  project_id               = var.project_id
  region                   = var.region
  environment              = var.environment
  database_connection_name = module.database.instance_connection_name
  is_dev                   = var.is_dev

  db_name          = module.database.db_name
  db_user_name     = module.database.db_user_name
  db_user_password = module.database.db_user_password

  storage_bucket_name = module.storage.bucket_name

  workload_identity_pool                  = module.gke.workload_identity_pool
  backend_kubernetes_namespace            = module.gke.backend_kubernetes_namespace
  backend_kubernetes_service_account_name = module.gke.backend_kubernetes_service_account_name
  external_secrets_service_account_email  = module.gke.external_secrets_service_account_email
  auth_service_backend_url                = var.auth_service_backend_url
  domain_name                             = var.domain_name

  env_vars = merge(
    var.backend_env_vars,
    {
      SENSITIVE_CANARY_BUCKET_NAME = module.access_canaries.canary_bucket_name
    }
  )
  backend_secret_env_vars = merge(
    var.backend_secret_env_vars,
    module.access_canaries.sensitive_db_enabled ? {
      CROSS_PROJECT_DB_URL = module.access_canaries.sensitive_db_url
    } : {}
  )
}

module "frontend" {
  source         = "../frontend"
  gcp_project_id = var.gcp_project_id
  project_id     = var.project_id
  region         = var.region
  environment    = var.environment
  domain_name    = var.domain_name
}

module "bucket_for_tf_state" {
  source = "../bucket_for_tf_state"

  gcp_project_id = var.gcp_project_id
  project_id     = var.project_id
  region         = var.region
  environment    = var.environment
  is_dev         = var.is_dev
}

module "ci_cd" {
  source = "../ci_cd"

  frontend_bucket_name  = module.frontend.bucket_name
  frontend_url_map_name = module.frontend.url_map_name

  gcp_project_id         = var.gcp_project_id
  project_id             = var.project_id
  environment            = var.environment
  region                 = var.region
  tf_state_bucket_name   = module.bucket_for_tf_state.bucket_name
  workload_identity_pool = module.gke.workload_identity_pool
  sentry_org             = var.sentry_org
  sentry_project         = var.sentry_project
}


module "dns" {
  source = "../dns"

  gcp_project_id      = var.gcp_project_id
  environment         = var.environment
  domain_name         = var.domain_name
  frontend_ip_address = module.frontend.load_balancer_ip_address
  backend_ip_address  = module.backend_service.ingress_nginx_ip_address

  depends_on = [
    module.frontend,
    module.backend_service
  ]
}
