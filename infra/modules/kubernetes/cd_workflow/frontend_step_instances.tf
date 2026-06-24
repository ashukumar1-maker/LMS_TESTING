locals {
  frontend_step_instances = [
    {
      name     = "frontend-build"
      depends  = "${local.terraform_converged_dependency} && inspect-source.Succeeded"
      template = "frontend-build"
      when     = "(${local.frontend_mode_when}) && {{tasks.inspect-source.outputs.parameters.frontend-deploy-needed}} == true"
    },
    {
      name     = "frontend-upload"
      depends  = "frontend-build.Succeeded"
      template = "frontend-upload"
      when     = "(${local.frontend_mode_when}) && {{tasks.inspect-source.outputs.parameters.frontend-deploy-needed}} == true"
    },
    {
      name     = "cdn-invalidate"
      depends  = "frontend-upload.Succeeded"
      template = "cdn-invalidate"
      when     = "(${local.frontend_mode_when}) && {{tasks.inspect-source.outputs.parameters.frontend-deploy-needed}} == true"
    },
  ]
}
