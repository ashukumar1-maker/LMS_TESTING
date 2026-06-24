"""Azure Blob Storage-backed Terraform state backend."""

import os
import subprocess
from datetime import datetime
from typing import Dict, Optional

from common.colors import Colors
from common.exceptions import BucketAccessError
from common.state_backend import StateBackend
from common.types import AccessType


class AzureBlobStateBackend(StateBackend):
    """
    Sync Terraform state to an Azure Blob Storage container via ``az``.

    Blob operations authenticate with the storage account access key, which is
    retrieved through the control plane (``az storage account keys list``). This
    mirrors the default behavior of Terraform's ``azurerm`` backend and works
    for any operator with control-plane access (Owner/Contributor), without
    requiring a separate data-plane ``Storage Blob Data`` role assignment.
    """

    def __init__(
        self,
        account_name: str,
        container_name: str,
        resource_group: str,
        subscription_id: str,
    ) -> None:
        self.account_name = account_name
        self.container_name = container_name
        self.resource_group = resource_group
        self.subscription_id = subscription_id
        self._account_key: Optional[str] = None

    @property
    def location_label(self) -> str:
        return (
            f"https://{self.account_name}.blob.core.windows.net/"
            f"{self.container_name}"
        )

    def _get_account_key(self) -> str:
        """
        Retrieve and cache the storage account access key via the control plane.

        Raises:
            BucketAccessError: If the key cannot be retrieved.
        """
        if self._account_key is not None:
            return self._account_key

        try:
            result = subprocess.run(
                [
                    "az",
                    "storage",
                    "account",
                    "keys",
                    "list",
                    "--account-name",
                    self.account_name,
                    "--resource-group",
                    self.resource_group,
                    "--subscription",
                    self.subscription_id,
                    "--query",
                    "[0].value",
                    "--output",
                    "tsv",
                ],
                capture_output=True,
                text=True,
            )
        except FileNotFoundError as e:
            raise BucketAccessError(
                "Azure CLI not found. Please install the Azure CLI (az)."
            ) from e

        if result.returncode != 0 or not result.stdout.strip():
            error_msg = (
                f"Unable to retrieve the access key for storage account "
                f"'{self.account_name}'.\n"
            )
            error_msg += "Possible issues:\n"
            error_msg += (
                "  - Your account needs control-plane access to list keys "
                "(e.g. the Contributor or Owner role)\n"
            )
            error_msg += (
                "  - The storage account may have shared key access disabled\n"
            )
            if result.stderr.strip():
                error_msg += f"  Details: {result.stderr.strip()}"
            raise BucketAccessError(error_msg)

        self._account_key = result.stdout.strip()
        return self._account_key

    def _blob_env(self) -> Dict[str, str]:
        """Return an environment that authenticates az with the account key."""
        env = os.environ.copy()
        env["AZURE_STORAGE_ACCOUNT"] = self.account_name
        env["AZURE_STORAGE_KEY"] = self._get_account_key()
        env["AZURE_STORAGE_AUTH_MODE"] = "key"
        return env

    def check_access(self, access_type: AccessType) -> None:
        print("Checking blob container access...")

        env = self._blob_env()

        try:
            result = subprocess.run(
                [
                    "az",
                    "storage",
                    "blob",
                    "list",
                    "--container-name",
                    self.container_name,
                    "--num-results",
                    "1",
                    "--output",
                    "none",
                ],
                capture_output=True,
                text=True,
                env=env,
            )
        except FileNotFoundError as e:
            raise BucketAccessError(
                "Azure CLI not found. Please install the Azure CLI (az)."
            ) from e

        if result.returncode != 0:
            error_msg = (
                f"Unable to access container '{self.container_name}' in "
                f"storage account '{self.account_name}'.\n"
            )
            error_msg += "Possible issues:\n"
            error_msg += (
                "  - The container may not exist yet (run 'terraform apply' "
                "to provision the infrastructure)\n"
            )
            if result.stderr.strip():
                error_msg += f"  Details: {result.stderr.strip()}"
            raise BucketAccessError(error_msg)

    def list_remote_files(self) -> None:
        print(f"Remote files in {self.location_label}:")

        try:
            result = subprocess.run(
                [
                    "az",
                    "storage",
                    "blob",
                    "list",
                    "--container-name",
                    self.container_name,
                    "--query",
                    "[].{name:name, size:properties.contentLength,"
                    " modified:properties.lastModified}",
                    "--output",
                    "table",
                ],
                capture_output=True,
                text=True,
                env=self._blob_env(),
            )

            if result.returncode == 0 and result.stdout.strip():
                print(result.stdout)
            else:
                print("No remote files found")

        except Exception:
            print("No remote files found")

    def remote_file_exists(self, filename: str) -> bool:
        result = subprocess.run(
            [
                "az",
                "storage",
                "blob",
                "exists",
                "--container-name",
                self.container_name,
                "--name",
                filename,
                "--query",
                "exists",
                "--output",
                "tsv",
            ],
            capture_output=True,
            text=True,
            env=self._blob_env(),
        )

        if result.returncode == 0:
            return result.stdout.strip().lower() == "true"

        raise RuntimeError(
            f"Unable to check whether {self.location_label}/{filename} "
            f"already exists: {result.stderr.strip() or result.stdout.strip()}"
        )

    def get_remote_mtime(self, filename: str) -> int:
        try:
            result = subprocess.run(
                [
                    "az",
                    "storage",
                    "blob",
                    "show",
                    "--container-name",
                    self.container_name,
                    "--name",
                    filename,
                    "--query",
                    "properties.lastModified",
                    "--output",
                    "tsv",
                ],
                capture_output=True,
                text=True,
                env=self._blob_env(),
            )

            if result.returncode == 0 and result.stdout.strip():
                # az returns ISO-8601 like "2024-01-15T10:30:45+00:00".
                time_str = result.stdout.strip().replace("Z", "+00:00")
                try:
                    return int(datetime.fromisoformat(time_str).timestamp())
                except Exception:
                    return 0

            return 0

        except Exception:
            return 0

    def upload(self, filename: str, local_path: str) -> bool:
        print(f"Uploading {filename}... ", end="", flush=True)

        local_file = os.path.join(local_path, filename)

        try:
            subprocess.run(
                [
                    "az",
                    "storage",
                    "blob",
                    "upload",
                    "--container-name",
                    self.container_name,
                    "--name",
                    filename,
                    "--file",
                    local_file,
                    "--overwrite",
                    "--only-show-errors",
                    "--output",
                    "none",
                ],
                capture_output=True,
                text=True,
                check=True,
                env=self._blob_env(),
            )

            print(Colors.green("✓"))
            return True

        except subprocess.CalledProcessError as e:
            print(Colors.red("✗ Failed"))
            if e.stderr:
                print(f"  {e.stderr.strip()}")
            return False
        except Exception as e:
            print(Colors.red("✗ Failed"))
            print(f"  {str(e)}")
            return False

    def download(self, filename: str, local_path: str) -> bool:
        print(f"Downloading {filename}... ", end="", flush=True)

        local_file = os.path.join(local_path, filename)

        try:
            result = subprocess.run(
                [
                    "az",
                    "storage",
                    "blob",
                    "download",
                    "--container-name",
                    self.container_name,
                    "--name",
                    filename,
                    "--file",
                    local_file,
                    "--only-show-errors",
                    "--output",
                    "none",
                ],
                capture_output=True,
                text=True,
                env=self._blob_env(),
            )

            if result.returncode == 0:
                print(Colors.green("✓"))
                return True
            else:
                print(Colors.yellow("⚠ Not found"))
                return False

        except Exception:
            print(Colors.yellow("⚠ Not found"))
            return False
