output "instance_connection_name" {
  description = "The connection name of the Cloud SQL instance."
  value       = google_sql_database_instance.default.connection_name
}

output "public_ip_address" {
  description = "The public IP address of the Cloud SQL instance."
  value       = google_sql_database_instance.default.public_ip_address
  # Note: May be empty if ipv4_enabled is false or instance hasn't finished provisioning
}

output "private_ip_address" {
  description = "The private IP address of the Cloud SQL instance."
  value       = google_sql_database_instance.default.private_ip_address
  # Note: May be empty if private IP is not configured
}

output "db_name" {
  description = "The name of the database created."
  value       = google_sql_database.default.name
}

output "db_user_name" {
  description = "The name of the default database user."
  value       = google_sql_user.default.name
}

output "db_user_password" {
  description = "The password of the default database user."
  value       = google_sql_user.default.password
  sensitive   = true
}

output "db_host" {
  description = "The host of the created resource."
  value       = google_sql_database_instance.default.ip_address[0].ip_address
}

output "db_port" {
  description = "The port of the created resource."
  value       = 5432 // Default port for PostgreSQL
}

output "database_uri" {
  description = "The URI of the created resource."
  value       = google_sql_database_instance.default.self_link
}
