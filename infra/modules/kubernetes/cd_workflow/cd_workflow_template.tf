resource "kubernetes_manifest" "cd_workflow_template" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "WorkflowTemplate"
    metadata = {
      name      = var.workflow_template_name
      namespace = var.namespace
      labels    = local.labels
    }
    spec = {
      serviceAccountName = kubernetes_service_account_v1.workflow_orchestrator.metadata[0].name
      entrypoint         = "deployment"
      onExit             = "delete-source-auth-secret"
      parallelism        = 4
      ttlStrategy = {
        secondsAfterSuccess = 86400
        secondsAfterFailure = 604800
      }
      volumeClaimGC = {
        strategy = "OnWorkflowCompletion"
      }
      volumeClaimTemplates = [
        {
          metadata = {
            name = "workspace"
          }
          spec = {
            accessModes = ["ReadWriteOnce"]
            resources = {
              requests = {
                storage = "10Gi"
              }
            }
          }
        }
      ]
      arguments = {
        parameters = local.workflow_parameters
      }
      templates = local.all_workflow_step_templates
    }
  }

  depends_on = [
    kubernetes_role_binding_v1.workflow_executor,
    kubernetes_role_binding_v1.workflow_state_editor,
    kubernetes_role_binding_v1.workflow_submitter,
    kubernetes_cluster_role_binding_v1.terraform_apply_cluster_admin,
    kubernetes_role_binding_v1.source_inspector,
    kubernetes_role_binding_v1.backend_rollout,
    kubernetes_role_binding_v1.backend_cd_task_runner,
  ]
}
