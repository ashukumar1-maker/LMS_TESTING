resource "null_resource" "build_and_push_initial_image" {
  triggers = {
    registry_id = azurerm_container_registry.default.id
    image_tag   = var.default_container_tag
  }

  provisioner "local-exec" {
    working_dir = abspath("${path.module}/../../../..")

    command = <<-EOT
      backend_bootstrap_context="$(mktemp -d)"
      trap 'rm -rf "$backend_bootstrap_context"' EXIT
      cp -R backend/. "$backend_bootstrap_context/"
      cp infra/modules/azure/backend/acr-build-initial.yaml "$backend_bootstrap_context/acr-build-initial.yaml"
      cat >> "$backend_bootstrap_context/.dockerignore" <<'DOCKERIGNORE'
node_modules/
.git/
DOCKERIGNORE

      az acr run \
        --subscription ${var.azure_subscription_id} \
        --registry ${var.acr_name} \
        --file acr-build-initial.yaml \
        --set image_name=${var.default_container_name} \
        --set image_tag=${var.default_container_tag} \
        "$backend_bootstrap_context"
    EOT
  }

  depends_on = [azurerm_container_registry.default]
}
