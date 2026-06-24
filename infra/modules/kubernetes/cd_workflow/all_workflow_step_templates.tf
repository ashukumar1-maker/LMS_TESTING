locals {
  # These locals mirror Argo CRD object shapes used by kubernetes_manifest.
  # See README.md for the WorkflowTemplate, Template, and DAGTask schema links.

  workspace_anchor_label_key = "workspace-anchor"
  workspace_anchor_affinity = {
    podAffinity = {
      requiredDuringSchedulingIgnoredDuringExecution = [
        {
          labelSelector = {
            matchExpressions = [
              {
                key      = "workflows.argoproj.io/workflow"
                operator = "In"
                values   = ["{{workflow.name}}"]
              },
              {
                key      = local.workspace_anchor_label_key
                operator = "In"
                values   = ["true"]
              },
            ]
          }
          topologyKey = "kubernetes.io/hostname"
        },
      ]
    }
  }

  source_step_instances = [
    {
      name     = "workspace-anchor"
      template = "workspace-anchor"
    },
    {
      name     = "clone-source"
      depends  = "workspace-anchor"
      template = "clone-source"
    },
  ]

  source_inspection_step_instances = [
    {
      name     = "inspect-source"
      depends  = local.terraform_output_ready_dependency
      template = "inspect-source"
      when     = "(${local.backend_mode_when}) || (${local.frontend_mode_when})"
    },
  ]

  final_step_instances = [
    {
      name = "record-final-backend-cd-state"
      depends = join(" && ", [
        local.terraform_converged_dependency,
        "(backend-build.Succeeded || backend-build.Skipped || backend-build.Omitted)",
        local.backend_cd_step_instances_complete_dependency,
        "(backend-rollout.Succeeded || backend-rollout.Skipped || backend-rollout.Omitted)",
        "inspect-source.Succeeded",
      ])
      template = "record-final-backend-cd-state"
      when     = "(${local.backend_mode_when})"
      arguments = {
        parameters = [
          {
            name  = "backend-hash"
            value = "{{tasks.inspect-source.outputs.parameters.backend-hash}}"
          },
          {
            name  = "desired-image"
            value = "{{tasks.inspect-source.outputs.parameters.desired-image}}"
          },
        ]
      }
    },
    {
      name = "record-final-frontend-cd-state"
      depends = join(" && ", [
        local.terraform_converged_dependency,
        "(frontend-build.Succeeded || frontend-build.Skipped || frontend-build.Omitted)",
        "(frontend-upload.Succeeded || frontend-upload.Skipped || frontend-upload.Omitted)",
        "(cdn-invalidate.Succeeded || cdn-invalidate.Skipped || cdn-invalidate.Omitted)",
        "inspect-source.Succeeded",
      ])
      template = "record-final-frontend-cd-state"
      when     = "(${local.frontend_mode_when})"
      arguments = {
        parameters = [
          {
            name  = "frontend-hash"
            value = "{{tasks.inspect-source.outputs.parameters.frontend-hash}}"
          },
          {
            name  = "frontend-env-hash"
            value = "{{tasks.inspect-source.outputs.parameters.frontend-env-hash}}"
          },
        ]
      }
    },
  ]

  workflow_dag_step_instances = concat(
    local.source_step_instances,
    local.infra_step_instances,
    local.source_inspection_step_instances,
    local.backend_step_instances,
    local.frontend_step_instances,
    local.final_step_instances,
  )

  placeholder_deployment_start_step_template = {
    name = "deployment"
    dag = {
      tasks = local.workflow_dag_step_instances
    }
  }

  entrypoint_and_anchor_step_templates = [
    local.placeholder_deployment_start_step_template,
    local.placeholder_pod_affinity_step_template,
  ]

  source_step_templates_with_workspace_affinity = [
    local.clone_source_code_step_template,
    local.inspect_source_to_gauge_necessary_steps_step_template,
  ]

  build_upload_step_templates_with_workspace_affinity = [
    local.build_and_push_backend_image_step_template,
    local.build_frontend_assets_step_template,
    local.upload_frontend_assets_step_template,
  ]

  step_templates_without_workspace_affinity = concat(
    [
      local.rollout_backend_deployment_step_template,
    ],
    local.backend_cd_task_step_templates,
    [
      local.invalidate_frontend_cache_step_template,
      local.record_backend_deployment_state_step_template,
      local.record_frontend_deployment_state_step_template,
      local.delete_temporary_source_auth_secret_step_template,
    ],
  )

  all_workflow_step_templates = concat(
    local.entrypoint_and_anchor_step_templates,
    # These templates mount the shared ReadWriteOnce workspace PVC, so they must
    # run on the same node as the live workspace-anchor pod to avoid multi-node
    # volume attach failures when the workflow runs on larger clusters.
    [
      for template in concat(
        local.source_step_templates_with_workspace_affinity,
        local.terraform_step_templates,
        local.build_upload_step_templates_with_workspace_affinity,
        ) : merge(template, {
          affinity = local.workspace_anchor_affinity
      })
    ],
    local.step_templates_without_workspace_affinity,
  )
}
