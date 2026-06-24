locals {
  inspect_source_to_gauge_necessary_steps_step_template = {
    name               = "inspect-source"
    serviceAccountName = kubernetes_service_account_v1.step_instances["source_inspector"].metadata[0].name
    container = {
      image   = "bash:5.2-alpine3.20"
      command = ["bash", "-c"]
      args = [
        <<-EOT
        set -euo pipefail
        apk add --no-cache coreutils git jq kubectl

        cd /workspace/repo

        ADDITIONAL_FRONTEND_ENV_VARS="$(jq -r '(.frontend_env_vars.value // {}) | to_entries | sort_by(.key)[] | "\(.key)=\(.value | tostring)"' /workspace/terraform-outputs.json)"

        BACKEND_HASH="$(git ls-files -z backend | sort -z | xargs -0 sha256sum | sha256sum | awk '{print $1}')"
        FRONTEND_HASH="$(git ls-files -z frontend | sort -z | xargs -0 sha256sum | sha256sum | awk '{print $1}')"
        FRONTEND_ENV_HASH="$(printf '%s\n' \
          "${var.identity_platform_api_key}" \
          "${var.identity_platform_auth_domain}" \
          "${var.identity_platform_project_id}" \
          "${var.identity_platform_storage_bucket}" \
          "${var.identity_platform_messaging_sender_id}" \
          "${var.identity_platform_app_id}" \
          "${var.project_id}" \
          "${var.auth_service_frontend_url}" \
          "${var.api_url}" \
          "$ADDITIONAL_FRONTEND_ENV_VARS" | sha256sum | awk '{print $1}')"
        IMAGE_URI="${var.backend_image_repository_uri}:{{workflow.parameters.commit-sha}}"

        LAST_BACKEND_HASH="$(kubectl -n ${var.namespace} get configmap ${kubernetes_config_map_v1.workflow_state.metadata[0].name} -o jsonpath='{.data.backend_hash}' 2>/dev/null || true)"
        LAST_BACKEND_IMAGE="$(kubectl -n ${var.namespace} get configmap ${kubernetes_config_map_v1.workflow_state.metadata[0].name} -o jsonpath='{.data.backend_image}' 2>/dev/null || true)"
        LAST_FRONTEND_HASH="$(kubectl -n ${var.namespace} get configmap ${kubernetes_config_map_v1.workflow_state.metadata[0].name} -o jsonpath='{.data.frontend_hash}' 2>/dev/null || true)"
        LAST_FRONTEND_ENV_HASH="$(kubectl -n ${var.namespace} get configmap ${kubernetes_config_map_v1.workflow_state.metadata[0].name} -o jsonpath='{.data.frontend_env_hash}' 2>/dev/null || true)"
        CURRENT_IMAGE="$(kubectl -n "${var.backend_namespace}" get deployment "${var.backend_deployment_name}" -o jsonpath="{.spec.template.spec.containers[?(@.name=='${var.backend_container_name}')].image}" 2>/dev/null || true)"

        BACKEND_BUILD_NEEDED=false
        if [ "$BACKEND_HASH" != "$LAST_BACKEND_HASH" ] || [ "$IMAGE_URI" != "$LAST_BACKEND_IMAGE" ]; then
          BACKEND_BUILD_NEEDED=true
        fi

        BACKEND_ROLLOUT_NEEDED=false
        if [ "$IMAGE_URI" != "$CURRENT_IMAGE" ]; then
          BACKEND_ROLLOUT_NEEDED=true
        fi

        FRONTEND_DEPLOY_NEEDED=false
        if [ "$FRONTEND_HASH" != "$LAST_FRONTEND_HASH" ] || [ "$FRONTEND_ENV_HASH" != "$LAST_FRONTEND_ENV_HASH" ]; then
          FRONTEND_DEPLOY_NEEDED=true
        fi

        printf '%s' "$BACKEND_HASH" > /tmp/backend-hash
        printf '%s' "$FRONTEND_HASH" > /tmp/frontend-hash
        printf '%s' "$FRONTEND_ENV_HASH" > /tmp/frontend-env-hash
        printf '%s' "$IMAGE_URI" > /tmp/desired-image
        printf '%s' "$BACKEND_BUILD_NEEDED" > /tmp/backend-build-needed
        printf '%s' "$BACKEND_ROLLOUT_NEEDED" > /tmp/backend-rollout-needed
        printf '%s' "$FRONTEND_DEPLOY_NEEDED" > /tmp/frontend-deploy-needed
        EOT
      ]
      volumeMounts = [
        {
          name      = "workspace"
          mountPath = "/workspace"
        },
      ]
    }
    outputs = {
      parameters = [
        { name = "backend-hash", valueFrom = { path = "/tmp/backend-hash" } },
        { name = "frontend-hash", valueFrom = { path = "/tmp/frontend-hash" } },
        { name = "frontend-env-hash", valueFrom = { path = "/tmp/frontend-env-hash" } },
        { name = "desired-image", valueFrom = { path = "/tmp/desired-image" } },
        { name = "backend-build-needed", valueFrom = { path = "/tmp/backend-build-needed" } },
        { name = "backend-rollout-needed", valueFrom = { path = "/tmp/backend-rollout-needed" } },
        { name = "frontend-deploy-needed", valueFrom = { path = "/tmp/frontend-deploy-needed" } },
      ]
    }
  }
}
