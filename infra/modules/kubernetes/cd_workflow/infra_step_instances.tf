locals {
  terraform_target_step_instances = flatten([
    for index, target in local.terraform_targets : [
      {
        name = "terraform-converge-${target.key}"
        depends = (
          index == 0
          ? "terraform-prepare.Succeeded"
          : "terraform-converge-${local.terraform_targets[index - 1].key}.Succeeded"
        )
        template = "terraform-converge-target"
        when     = local.infra_mode_when
        arguments = {
          parameters = [
            {
              name  = "target-name"
              value = target.key
            },
            {
              name  = "target-args"
              value = target.target_args
            },
          ]
        }
      },
    ]
  ])

  infra_step_instances = concat([
    {
      name     = "terraform-prepare"
      depends  = "clone-source.Succeeded"
      template = "terraform-prepare"
    },
    ], local.terraform_target_step_instances, [
    {
      name     = "terraform-output"
      depends  = "terraform-prepare.Succeeded && (${local.terraform_full_converge_complete_dependency} || terraform-converge-deployment.Omitted || terraform-converge-deployment.Skipped)"
      template = "terraform-output"
    },
    {
      name     = "terraform-push-state"
      depends  = "terraform-prepare.Succeeded && ${local.terraform_step_instance_terminal_dependencies}"
      template = "terraform-push-state"
      when     = local.infra_mode_when
    },
  ])
}
