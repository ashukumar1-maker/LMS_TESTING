locals {
  terraform_workdir = "/workspace/repo/infra/environments/${var.environment}"
  terraform_state_backend_args = (
    local.cloud == "gcp" ? " \\\n          --gcp-project-id \"${var.gcp_project_id}\"" :
    local.cloud == "azure" ? " \\\n          --azure-subscription-id \"${var.azure_subscription_id}\"" :
    ""
  )
  terraform_container_image = local.cloud == "azure" ? "mcr.microsoft.com/azure-cli:2.77.0" : "gcr.io/google.com/cloudsdktool/cloud-sdk:slim"
  terraform_step_template_metadata = local.cloud == "azure" ? {
    metadata = {
      labels = {
        "azure.workload.identity/use" = "true"
      }
    }
  } : {}
  terraform_azure_env_exports = local.cloud == "azure" ? join("\n", [
    "export ARM_USE_OIDC=true",
    "export ARM_SUBSCRIPTION_ID=\"${var.azure_subscription_id}\"",
    "export ARM_TENANT_ID=\"${var.azure_tenant_id}\"",
    "export ARM_CLIENT_ID=\"$${AZURE_CLIENT_ID}\"",
    "export ARM_OIDC_TOKEN_FILE_PATH=\"$${AZURE_FEDERATED_TOKEN_FILE}\"",
    "export TF_VAR_use_in_cluster_kubernetes_config=true",
  ]) : ""
  terraform_azure_login_command = local.cloud == "azure" ? join("\n", [
    "az login --service-principal --username \"$${AZURE_CLIENT_ID}\" --tenant \"$${AZURE_TENANT_ID}\" --federated-token \"$(cat \"$${AZURE_FEDERATED_TOKEN_FILE}\")\" --output none",
    "az account set --subscription \"${var.azure_subscription_id}\"",
  ]) : ""

  terraform_output_ready_dependency = "terraform-output.Succeeded"
  terraform_converged_dependency    = "terraform-output.Succeeded && (terraform-push-state.Succeeded || terraform-push-state.Omitted || terraform-push-state.Skipped)"

  terraform_full_converge_complete_dependency = "terraform-converge-full.Succeeded"

  terraform_terminal_statuses = [
    "Succeeded",
    "Failed",
    "Errored",
    "Skipped",
    "Omitted",
  ]

  terraform_targets = [
    {
      key         = "deployment"
      target_args = "-target=module.deployment"
    },
    {
      key         = "kubernetes-crds"
      target_args = "-target=module.kubernetes_crds"
    },
    {
      key         = "full"
      target_args = ""
    },
  ]

  terraform_step_instance_terminal_dependencies = join(" && ", [
    for step_instance_name in concat(
      ["terraform-prepare"],
      [for target in local.terraform_targets : "terraform-converge-${target.key}"],
      ["terraform-output"]
    ) : "(${join(" || ", [for status in local.terraform_terminal_statuses : "${step_instance_name}.${status}"])})"
  ])

  prepare_terraform_workspace_step_template = merge(
    {
      name               = "terraform-prepare"
      serviceAccountName = kubernetes_service_account_v1.step_instances["terraform_apply"].metadata[0].name
      container = {
        image   = local.terraform_container_image
        command = ["bash", "-c"]
        args = [
          <<-EOT
        set -euo pipefail

        mkdir -p /workspace/bin
        terraform_zip="terraform_${var.terraform_version}_linux_amd64.zip"
        if [ "${local.cloud}" = "gcp" ]; then
          apt-get update && apt-get install -y git jq kubectl google-cloud-sdk-gke-gcloud-auth-plugin wget unzip
          wget "https://releases.hashicorp.com/terraform/${var.terraform_version}/$terraform_zip"
          unzip "$terraform_zip"
          mv terraform /workspace/bin/terraform
          cp "$(command -v gke-gcloud-auth-plugin)" /workspace/bin/gke-gcloud-auth-plugin
          chmod +x /workspace/bin/gke-gcloud-auth-plugin
        else
          python3 - "$terraform_zip" <<'PY'
        import sys
        import urllib.request
        import zipfile

        terraform_zip = sys.argv[1]
        url = "https://releases.hashicorp.com/terraform/${var.terraform_version}/" + terraform_zip
        urllib.request.urlretrieve(url, terraform_zip)
        with zipfile.ZipFile(terraform_zip) as archive:
            archive.extract("terraform", "/workspace/bin")
        PY
        fi
        chmod +x /workspace/bin/terraform
        export PATH="/workspace/bin:$PATH"
        ${local.terraform_azure_env_exports}
        ${local.terraform_azure_login_command}

        cd ${local.terraform_workdir}
        python3 ../../scripts/pullstate.py -e "${var.environment}" -f \
          --cloud "${local.cloud}" \
          --project-id "${var.project_id}"${local.terraform_state_backend_args}

        terraform init
        EOT
        ]
        volumeMounts = [
          {
            name      = "workspace"
            mountPath = "/workspace"
          }
        ]
      }
    },
    local.terraform_step_template_metadata,
  )

  apply_terraform_target_step_template = merge(
    {
      name               = "terraform-converge-target"
      serviceAccountName = kubernetes_service_account_v1.step_instances["terraform_apply"].metadata[0].name
      inputs = {
        parameters = [
          { name = "target-name" },
          { name = "target-args" },
        ]
      }
      container = {
        image   = local.terraform_container_image
        command = ["bash", "-c"]
        args = [
          <<-EOT
        set -euo pipefail
        export PATH="/workspace/bin:$PATH"
        ${local.terraform_azure_env_exports}
        cd ${local.terraform_workdir}

        target_name="{{inputs.parameters.target-name}}"
        target_args="{{inputs.parameters.target-args}}"

        echo "Applying Terraform changes for $target_name."
        if [ -n "$target_args" ]; then
          terraform apply -auto-approve -input=false $target_args
        else
          terraform apply -auto-approve -input=false
        fi
        EOT
        ]
        volumeMounts = [
          {
            name      = "workspace"
            mountPath = "/workspace"
          }
        ]
      }
    },
    local.terraform_step_template_metadata,
  )

  write_terraform_outputs_step_template = merge(
    {
      name               = "terraform-output"
      serviceAccountName = kubernetes_service_account_v1.step_instances["terraform_apply"].metadata[0].name
      container = {
        image   = local.terraform_container_image
        command = ["bash", "-c"]
        args = [
          <<-EOT
        set -euo pipefail
        export PATH="/workspace/bin:$PATH"
        ${local.terraform_azure_env_exports}
        cd ${local.terraform_workdir}
        terraform output -json > /workspace/terraform-outputs.json
        EOT
        ]
        volumeMounts = [
          {
            name      = "workspace"
            mountPath = "/workspace"
          }
        ]
      }
    },
    local.terraform_step_template_metadata,
  )

  push_terraform_state_step_template = merge(
    {
      name               = "terraform-push-state"
      serviceAccountName = kubernetes_service_account_v1.step_instances["terraform_apply"].metadata[0].name
      container = {
        image   = local.terraform_container_image
        command = ["bash", "-c"]
        args = [
          <<-EOT
        set -euo pipefail
        export PATH="/workspace/bin:$PATH"
        ${local.terraform_azure_env_exports}
        ${local.terraform_azure_login_command}

        if [ ! -d "${local.terraform_workdir}" ]; then
          echo "Terraform workdir does not exist; skipping state push."
          exit 0
        fi

        cd ${local.terraform_workdir}
        python3 ../../scripts/pushstate.py -e "${var.environment}" -f \
          --cloud "${local.cloud}" \
          --project-id "${var.project_id}"${local.terraform_state_backend_args}
        EOT
        ]
        volumeMounts = [
          {
            name      = "workspace"
            mountPath = "/workspace"
          }
        ]
      }
    },
    local.terraform_step_template_metadata,
  )

  terraform_step_templates = [
    local.prepare_terraform_workspace_step_template,
    local.apply_terraform_target_step_template,
    local.write_terraform_outputs_step_template,
    local.push_terraform_state_step_template,
  ]
}
