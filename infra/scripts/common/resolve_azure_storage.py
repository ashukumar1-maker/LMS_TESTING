"""Resolve the Azure Storage account and container holding Terraform state."""

import re
import subprocess
from typing import NamedTuple

from common.exceptions import BucketAccessError

# Matches the `terraform-state` container created in
# infra/modules/azure/storage/main.tf. Do not change without updating that
# module.
TERRAFORM_STATE_CONTAINER = "terraform-state"


class AzureStorageLocation(NamedTuple):
    """Resolved Azure Storage location for Terraform state."""

    account_name: str
    container_name: str
    resource_group: str


def azure_resource_group_name(project_id: str, environment: str) -> str:
    """
    Derive the deterministic resource group name for an Azure environment.

    Mirrors the ``name_prefix``/resource group locals in
    infra/modules/azure/deployment/main.tf so the state-sync scripts can locate
    resources without reading Terraform state.
    """
    safe_project = re.sub(r"[^a-z0-9-]", "-", project_id.lower())
    safe_environment = re.sub(r"[^a-z0-9-]", "-", environment.lower())
    name_prefix = f"{safe_project}-{safe_environment}"[:40]
    return f"{name_prefix}-rg"


def resolve_azure_storage(
    project_id: str, environment: str, subscription_id: str
) -> AzureStorageLocation:
    """
    Find the Azure Storage account that holds the Terraform state container.

    The account name carries a random suffix, so it cannot be derived directly.
    Instead this resolves the deterministic resource group and discovers the
    single storage account within it.

    Raises:
        BucketAccessError: If the account cannot be resolved.
    """
    resource_group = azure_resource_group_name(project_id, environment)

    try:
        result = subprocess.run(
            [
                "az",
                "storage",
                "account",
                "list",
                "--resource-group",
                resource_group,
                "--subscription",
                subscription_id,
                "--query",
                "[].name",
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

    if result.returncode != 0:
        error_msg = (
            f"Unable to list storage accounts in resource group "
            f"'{resource_group}'.\n"
        )
        error_msg += "Possible issues:\n"
        error_msg += "  - You need to run 'az login' to authenticate\n"
        error_msg += (
            f"  - The subscription ID '{subscription_id}' may be incorrect\n"
        )
        error_msg += (
            "  - The infrastructure may not be provisioned yet (run "
            "'terraform apply' first)\n"
        )
        if result.stderr.strip():
            error_msg += f"  Details: {result.stderr.strip()}"
        raise BucketAccessError(error_msg)

    account_names = [name for name in result.stdout.split() if name.strip()]

    if not account_names:
        raise BucketAccessError(
            f"No storage account found in resource group '{resource_group}'.\n"
            "The infrastructure may not be provisioned yet. Run "
            "'terraform apply' before syncing state."
        )

    if len(account_names) > 1:
        raise BucketAccessError(
            f"Found multiple storage accounts in resource group "
            f"'{resource_group}': {', '.join(account_names)}.\n"
            "Unable to determine which one holds Terraform state."
        )

    return AzureStorageLocation(
        account_name=account_names[0],
        container_name=TERRAFORM_STATE_CONTAINER,
        resource_group=resource_group,
    )
