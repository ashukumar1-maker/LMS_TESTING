output "namespace" {
  description = "Namespace where deployment workflows run."
  value       = var.namespace
}

output "workflow_template_name" {
  description = "Name of the deployment WorkflowTemplate."
  value       = var.workflow_template_name
}

output "workflow_state_config_map_name" {
  description = "ConfigMap used to store workflow skip-state hashes and image gates."
  value       = kubernetes_config_map_v1.workflow_state.metadata[0].name
}
