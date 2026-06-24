locals {
  # Argo Template object; see ../README.md and the shared Kubernetes CD workflow README for schema context.
  upload_frontend_assets_step_template = {
    name               = "frontend-upload"
    serviceAccountName = var.step_service_account_name
    metadata = {
      labels = {
        "azure.workload.identity/use" = "true"
      }
    }
    container = {
      image   = var.azure_cli_image
      command = ["bash", "-c"]
      args = [
        <<-EOT
        set -euo pipefail

        az login \
          --service-principal \
          --username "$${AZURE_CLIENT_ID}" \
          --tenant "$${AZURE_TENANT_ID}" \
          --federated-token "$(cat "$${AZURE_FEDERATED_TOKEN_FILE}")" \
          --output none

        # `az storage blob sync` shells out to AzCopy. Install it explicitly so
        # deployments do not depend on Azure CLI's runtime download path, which
        # has failed in AKS on GitHub release redirect URLs.
        mkdir -p "$HOME/.azure/bin"
        export PATH="$HOME/.azure/bin:$PATH"
        python3 - <<'PY'
        import os
        import stat
        import tarfile
        import tempfile
        import urllib.request

        archive_path = os.path.join(tempfile.gettempdir(), "azcopy_linux_amd64.tar.gz")
        urllib.request.urlretrieve("https://aka.ms/downloadazcopy-v10-linux", archive_path)

        with tarfile.open(archive_path, "r:gz") as archive:
            azcopy_member = next(
                member
                for member in archive.getmembers()
                if member.isfile() and os.path.basename(member.name) == "azcopy"
            )
            azcopy_binary = archive.extractfile(azcopy_member)
            if azcopy_binary is None:
                raise RuntimeError("Unable to extract azcopy from archive.")

            install_path = os.path.expanduser("~/.azure/bin/azcopy")
            with open(install_path, "wb") as output:
                output.write(azcopy_binary.read())

        os.chmod(install_path, os.stat(install_path).st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
        PY

        az storage blob sync \
          --subscription "${var.azure_subscription_id}" \
          --account-name "${var.frontend_storage_account_name}" \
          --auth-mode login \
          --container '$web' \
          --source /workspace/repo/frontend/dist \
          --delete-destination true \
          --only-show-errors
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
