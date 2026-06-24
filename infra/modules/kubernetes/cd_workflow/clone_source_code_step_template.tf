locals {
  # Argo Template object; see README.md for the WorkflowTemplate and Template schema links.
  clone_source_code_step_template = {
    name               = "clone-source"
    serviceAccountName = kubernetes_service_account_v1.step_instances["source_inspector"].metadata[0].name
    container = {
      image   = "bash:5.2-alpine3.20"
      command = ["bash", "-c"]
      args = [
        <<-EOT
        set -euo pipefail
        apk add --no-cache git

        case "{{workflow.parameters.deployment-mode}}" in
          INFRA_ONLY|BACKEND_ONLY|FRONTEND_ONLY|FULL)
            ;;
          *)
            echo "Invalid deployment-mode: {{workflow.parameters.deployment-mode}}"
            echo "Expected one of: INFRA_ONLY, BACKEND_ONLY, FRONTEND_ONLY, FULL"
            exit 1
            ;;
        esac

        AUTHORIZATION_HEADER="$(cat /source-auth/authorization-header)"
        REPOSITORY_URL="${var.source_repository_url}"

        rm -rf /workspace/repo

        GIT_CONFIG_COUNT=1 \
          GIT_CONFIG_KEY_0=http.extraHeader \
          GIT_CONFIG_VALUE_0="$AUTHORIZATION_HEADER" \
          git clone "$REPOSITORY_URL" /workspace/repo

        cd /workspace/repo
        git checkout "{{workflow.parameters.commit-sha}}"
        EOT
      ]
      volumeMounts = [
        {
          name      = "workspace"
          mountPath = "/workspace"
        },
        {
          name      = "source-auth"
          mountPath = "/source-auth"
          readOnly  = true
        },
      ]
    }
    volumes = [
      {
        name = "source-auth"
        secret = {
          secretName = "{{workflow.parameters.source-auth-secret-name}}"
        }
      }
    ]
  }
}
