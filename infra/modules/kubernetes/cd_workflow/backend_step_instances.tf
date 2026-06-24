locals {
  backend_after_build_dependency = join(" && ", [
    local.terraform_converged_dependency,
    "inspect-source.Succeeded",
    "(backend-build.Succeeded || backend-build.Skipped || backend-build.Omitted)",
  ])

  backend_cd_task_step_instances = [
    for index, task in var.backend_cd_tasks : {
      name     = "backend-cd-${task.name}"
      depends  = index == 0 ? local.backend_after_build_dependency : "(backend-cd-${var.backend_cd_tasks[index - 1].name}.Succeeded || backend-cd-${var.backend_cd_tasks[index - 1].name}.Skipped)"
      template = "backend-cd-task-${task.name}"
      when     = "(${local.backend_mode_when}) && {{tasks.inspect-source.outputs.parameters.backend-rollout-needed}} == true"
      arguments = {
        parameters = [
          {
            name  = "desired-image"
            value = "{{tasks.inspect-source.outputs.parameters.desired-image}}"
          },
        ]
      }
    }
  ]

  backend_cd_step_instances_complete_dependency = length(local.backend_cd_task_step_instances) > 0 ? join("", [
    "(",
    local.backend_cd_task_step_instances[length(local.backend_cd_task_step_instances) - 1].name,
    ".Succeeded || ",
    local.backend_cd_task_step_instances[length(local.backend_cd_task_step_instances) - 1].name,
    ".Skipped)",
  ]) : "(backend-build.Succeeded || backend-build.Skipped || backend-build.Omitted)"

  backend_step_instances = concat(
    [
      {
        name     = "backend-build"
        depends  = "${local.terraform_converged_dependency} && inspect-source.Succeeded"
        template = "backend-build"
        when     = "(${local.backend_mode_when}) && {{tasks.inspect-source.outputs.parameters.backend-build-needed}} == true"
        arguments = {
          parameters = [
            {
              name  = "desired-image"
              value = "{{tasks.inspect-source.outputs.parameters.desired-image}}"
            },
          ]
        }
      }
    ],
    local.backend_cd_task_step_instances,
    [
      {
        name     = "backend-rollout"
        depends  = "${local.backend_after_build_dependency} && ${local.backend_cd_step_instances_complete_dependency}"
        template = "backend-rollout"
        when     = "(${local.backend_mode_when}) && {{tasks.inspect-source.outputs.parameters.backend-rollout-needed}} == true"
        arguments = {
          parameters = [
            {
              name  = "desired-image"
              value = "{{tasks.inspect-source.outputs.parameters.desired-image}}"
            },
          ]
        }
      },
    ],
  )
}
