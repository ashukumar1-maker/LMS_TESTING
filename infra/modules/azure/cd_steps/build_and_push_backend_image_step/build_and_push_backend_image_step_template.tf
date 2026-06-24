locals {
  # Argo Template object; see ../../README.md and the shared Kubernetes CD workflow README for schema context.
  build_and_push_backend_image_step_template = {
    name               = "backend-build"
    serviceAccountName = var.step_service_account_name
    metadata = {
      labels = {
        "azure.workload.identity/use" = "true"
      }
    }
    inputs = {
      parameters = [
        { name = "desired-image" },
      ]
    }
    container = {
      image   = var.azure_cli_image
      command = ["bash", "-c"]
      args = [
        <<-EOT
        set -euo pipefail

        desired_image="{{inputs.parameters.desired-image}}"
        registry_login_server="${var.container_registry_login_server}"
        registry_name="$${registry_login_server%%.*}"
        image_ref="$${desired_image#"$${registry_login_server}/"}"

        if [ "$${image_ref}" = "$${desired_image}" ]; then
          echo "Desired image '$${desired_image}' is not in Azure Container Registry '$${registry_login_server}'." >&2
          exit 1
        fi

        image_name="$${image_ref%:*}"
        image_tag="$${image_ref##*:}"

        if [ -z "$${image_name}" ] || [ -z "$${image_tag}" ] || [ "$${image_name}" = "$${image_ref}" ]; then
          echo "Unable to parse desired image '$${desired_image}' into repository and tag." >&2
          exit 1
        fi

        az login \
          --service-principal \
          --username "$${AZURE_CLIENT_ID}" \
          --tenant "$${AZURE_TENANT_ID}" \
          --federated-token "$(cat "$${AZURE_FEDERATED_TOKEN_FILE}")" \
          --output none
        az account set --subscription "${var.azure_subscription_id}"

        task_file="acr-build.yaml"
        task_file_path="/workspace/repo/backend/$${task_file}"
        cat > "$${task_file_path}" <<'YAML'
        version: v1.1.0
        stepTimeout: 3600
        steps:
          - build: >-
              --platform linux/amd64
              --file Dockerfile
              --build-arg BUILDKIT_INLINE_CACHE=1
              --cache-from $Registry/{{.Values.image_name}}:latest
              --tag $Registry/{{.Values.image_name}}:{{.Values.image_tag}}
              --tag $Registry/{{.Values.image_name}}:latest
              .
            env:
              - DOCKER_BUILDKIT=1
          - push:
              - $Registry/{{.Values.image_name}}:{{.Values.image_tag}}
              - $Registry/{{.Values.image_name}}:latest
        YAML

        az acr run \
          --subscription "${var.azure_subscription_id}" \
          --registry "$${registry_name}" \
          --file "$${task_file}" \
          --set "image_name=$${image_name}" \
          --set "image_tag=$${image_tag}" \
          /workspace/repo/backend
        EOT
      ]
      volumeMounts = [
        {
          name      = "workspace"
          mountPath = "/workspace"
        }
      ]
    }
  }
}
