output "template" {
  description = "Argo Template object for the Azure frontend static website upload step."
  value       = local.upload_frontend_assets_step_template
}
