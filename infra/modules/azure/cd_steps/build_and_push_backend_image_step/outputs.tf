output "template" {
  description = "Argo Template object for the Azure backend image build and ACR push step."
  value       = local.build_and_push_backend_image_step_template
}
