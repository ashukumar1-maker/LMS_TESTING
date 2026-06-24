
#---------- REQUIRED CONFIGURATION ----------

variable "gcp_project_id" {
  description = "The ID of the Google Cloud project."
  type        = string
}

variable "region" {
  description = "The region for the database instance."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)."
  type        = string
}

variable "vpc_network_id" {
  description = "The ID of the VPC network for the Cloud SQL instance."
  type        = string
}

variable "private_ip_address_name" {
  description = "The name of the private IP address range for the Cloud SQL instance."
  type        = string
}

variable "vpc_peering_connection_id" {
  description = "The ID of the VPC peering connection for the Cloud SQL instance."
  type        = string
}

variable "is_dev" {
  description = "Whether the environment is development."
  type        = bool
}

#---------- OPTIONAL CONFIGURATION ----------

variable "database_version" {
  description = "The version of the database (e.g., MYSQL_8_0, POSTGRES_17)."
  type        = string
  default     = "POSTGRES_17"
}

variable "database_edition" {
  description = "The edition of the database (either, ENTERPRISE, or ENTERPRISE_PLUS)."
  type        = string
  default     = "ENTERPRISE"
}

variable "tier" {
  description = "The machine type for the Cloud SQL instance (e.g., db-f1-micro). For dev enviornments, this will be ignored and db-f1-micro will be used."
  type        = string
  # db-custom-1-4096 translates to 1 vCPU and 4096 MiB (4 GB) RAM
  default = "db-custom-1-4096"
}

variable "backup_enabled" {
  description = "Whether automated backups are enabled for the Cloud SQL instance."
  type        = bool
  default     = true
}

variable "backup_start_time" {
  description = "Daily backup start time in UTC using HH:MM format. If null, a region-aware default is used."
  type        = string
  default     = null

  validation {
    condition     = var.backup_start_time == null || can(regex("^([01][0-9]|2[0-3]):[0-5][0-9]$", var.backup_start_time))
    error_message = "backup_start_time must be in HH:MM 24-hour format."
  }
}

variable "point_in_time_recovery_enabled" {
  description = "Whether point-in-time recovery (PITR) is enabled."
  type        = bool
  default     = true
}

variable "transaction_log_retention_days" {
  description = "Number of days to retain transaction logs for PITR (Cloud SQL Enterprise edition: 1-7 days)."
  type        = number
  default     = 7

  # Cloud SQL PostgreSQL PITR log retention for Enterprise edition is capped at 7 days:
  # https://cloud.google.com/sql/docs/postgres/backup-recovery/backup-options
  validation {
    condition     = var.transaction_log_retention_days >= 1 && var.transaction_log_retention_days <= 7
    error_message = "transaction_log_retention_days must be between 1 and 7 for Cloud SQL Enterprise edition."
  }
}

variable "retained_backups" {
  description = "Number of automated backups to retain."
  type        = number
  default     = 7

  validation {
    condition     = var.retained_backups >= 1
    error_message = "retained_backups must be at least 1."
  }
}

variable "db_name" {
  description = "The name of the database to create."
  type        = string
  default     = "default-db"
}

variable "db_user_name" {
  description = "The name for the default database user."
  type        = string
  default     = "default_user"
}

variable "db_user_password" {
  description = "The password for the database user. If not provided, a random one will be generated."
  type        = string
  sensitive   = true
  default     = null
}
