output "template" {
  description = "Argo Template object for the GCP backend image build and Artifact Registry push step."
  value       = local.build_and_push_backend_image_step_template
}
