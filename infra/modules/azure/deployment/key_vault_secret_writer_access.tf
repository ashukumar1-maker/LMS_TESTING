locals {
  key_vault_secret_writer_role = "Key Vault Secrets Officer"
}

# Terraform writes several deployment-owned secrets into the backend Key Vault
# during apply, so the active Terraform runner needs Azure Key Vault data-plane
# access before those secret resources are created. The active runner is not a
# stable identity: local applies use the local Azure principal, while CD applies
# use the workload identity principal. Managing that grant with
# azurerm_role_assignment made Terraform replace the assignment whenever the
# runner changed, which could delete another runner's access and then fail when
# the target assignment already existed.
#
# This resource is intentionally non-declarative and non-destructive. Its
# triggers rerun the provisioner when the Key Vault, active runner principal, or
# role name changes. The script preserves an existing local Azure CLI login, but
# logs in with workload identity when CD exposes AZURE_FEDERATED_TOKEN_FILE. It
# then checks whether the current runner already has the Key Vault Secrets
# Officer role at the vault scope and creates the assignment only when missing.
# There is no destroy provisioner, so changing from local to CD or back never
# removes another principal's secret-write access.
resource "null_resource" "current_key_vault_secret_writer_access" {
  triggers = {
    key_vault_id         = azurerm_key_vault.default.id
    principal_id         = data.azurerm_client_config.current.object_id
    role_definition_name = local.key_vault_secret_writer_role
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      if [ -n "$${AZURE_FEDERATED_TOKEN_FILE:-}" ] && [ -n "$${AZURE_CLIENT_ID:-}" ] && [ -n "$${AZURE_TENANT_ID:-}" ]; then
        az login \
          --service-principal \
          --username "$${AZURE_CLIENT_ID}" \
          --tenant "$${AZURE_TENANT_ID}" \
          --federated-token "$(cat "$${AZURE_FEDERATED_TOKEN_FILE}")" \
          --output none
      fi

      key_vault_id="${self.triggers.key_vault_id}"
      principal_id="${self.triggers.principal_id}"
      role_definition_name="${self.triggers.role_definition_name}"

      max_attempts=60
      wait_seconds=10
      last_error_file="$(mktemp)"
      trap 'rm -f "$last_error_file"' EXIT

      for attempt in $(seq 1 "$max_attempts"); do
        if az resource show --subscription "${var.azure_subscription_id}" --ids "$key_vault_id" --query id -o tsv >/dev/null 2>"$last_error_file"; then
          break
        fi

        if [ "$attempt" -eq "$max_attempts" ]; then
          echo "Key Vault $key_vault_id was not readable by Azure CLI after $((max_attempts * wait_seconds)) seconds." >&2
          echo "Last Azure CLI error:" >&2
          cat "$last_error_file" >&2
          exit 1
        fi

        sleep "$wait_seconds"
      done

      assignment_id="$(
        az role assignment list \
          --subscription "${var.azure_subscription_id}" \
          --scope "$key_vault_id" \
          --assignee "$principal_id" \
          --role "$role_definition_name" \
          --query "[0].id" \
          -o tsv
      )"

      if [ -n "$assignment_id" ]; then
        echo "Key Vault secret writer role assignment already exists: $assignment_id"
        exit 0
      fi

      if ! create_output="$(
        az role assignment create \
          --subscription "${var.azure_subscription_id}" \
          --scope "$key_vault_id" \
          --assignee-object-id "$principal_id" \
          --role "$role_definition_name" \
          --only-show-errors \
          -o none 2>&1
      )"; then
        case "$create_output" in
          *RoleAssignmentExists*)
            echo "Key Vault secret writer role assignment already exists."
            ;;
          *)
            echo "$create_output" >&2
            exit 1
            ;;
        esac
      fi
    EOT
  }
}
