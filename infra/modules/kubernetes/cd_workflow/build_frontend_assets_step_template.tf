locals {
  # Argo Template object; see README.md for the WorkflowTemplate and Template schema links.
  build_frontend_assets_step_template = {
    name               = "frontend-build"
    serviceAccountName = kubernetes_service_account_v1.step_instances["frontend_deployer"].metadata[0].name
    container = {
      image   = "node:22-bookworm-slim"
      command = ["bash", "-c"]
      args = [
        <<-EOT
        set -euo pipefail
        apt-get update && apt-get install -y jq
        corepack enable
        cd /workspace/repo/frontend

        ADDITIONAL_FRONTEND_ENV_VARS="$(jq -r '(.frontend_env_vars.value // {}) | to_entries | sort_by(.key)[] | "\(.key)=\(.value | tostring)"' /workspace/terraform-outputs.json)"

        if [ -n "$ADDITIONAL_FRONTEND_ENV_VARS" ]; then
          while IFS= read -r line; do
            if [ -n "$line" ]; then
              export "$line"
            fi
          done <<< "$ADDITIONAL_FRONTEND_ENV_VARS"
        fi

        export VITE_IDENTITY_PLATFORM_API_KEY="${var.identity_platform_api_key}"
        export VITE_IDENTITY_PLATFORM_AUTH_DOMAIN="${var.identity_platform_auth_domain}"
        export VITE_IDENTITY_PLATFORM_PROJECT_ID="${var.identity_platform_project_id}"
        export VITE_IDENTITY_PLATFORM_STORAGE_BUCKET="${var.identity_platform_storage_bucket}"
        export VITE_IDENTITY_PLATFORM_MESSAGING_SENDER_ID="${var.identity_platform_messaging_sender_id}"
        export VITE_IDENTITY_PLATFORM_APP_ID="${var.identity_platform_app_id}"
        export VITE_API_URL="${var.api_url}"
        export VITE_PROJECT_ID="${var.project_id}"
        export VITE_AUTH_SERVICE_FRONTEND_URL="${var.auth_service_frontend_url}"
        export VITE_ENVIRONMENT="${var.environment}"
        export SENTRY_ORG="${var.sentry_org}"
        export SENTRY_PROJECT="${var.sentry_project}"

        yarn install
        yarn build
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
