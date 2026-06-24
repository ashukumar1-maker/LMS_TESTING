"""Build the cloud-appropriate Terraform state backend."""

from typing import Optional

from common.azure_state_backend import AzureBlobStateBackend
from common.check_azure_auth import check_azure_auth
from common.check_gcloud_auth import check_gcloud_auth
from common.colors import Colors
from common.exceptions import ProjectConfigError
from common.gcs_state_backend import GcsStateBackend
from common.get_azure_config import get_azure_config
from common.get_bucket_name import get_bucket_name
from common.get_project_ids import get_project_ids
from common.resolve_azure_storage import resolve_azure_storage
from common.state_backend import StateBackend
from common.types import AzureConfig, Cloud, ProjectIds


def get_state_backend(
    cloud: Cloud,
    env_dir: str,
    environment: str,
    project_id: Optional[str] = None,
    gcp_project_id: Optional[str] = None,
    azure_subscription_id: Optional[str] = None,
) -> StateBackend:
    """
    Resolve configuration, verify auth, and return a ready state backend.

    Args:
        cloud: Target cloud provider ('gcp' or 'azure').
        env_dir: The environment directory path.
        environment: The environment name.
        project_id: Optional project_id override.
        gcp_project_id: Optional gcp_project_id override (GCP only).
        azure_subscription_id: Optional subscription override (Azure only).

    Raises:
        ProjectConfigError: If configuration cannot be resolved.
        AuthenticationError: If the cloud CLI is not authenticated.
        BucketAccessError: If the Azure storage account cannot be resolved.
    """
    if cloud == "azure":
        if gcp_project_id:
            raise ProjectConfigError(
                "--gcp-project-id is only valid for GCP environments; use "
                "--azure-subscription-id for Azure"
            )
        return _build_azure_backend(
            env_dir, environment, project_id, azure_subscription_id
        )

    if azure_subscription_id:
        raise ProjectConfigError(
            "--azure-subscription-id is only valid for Azure environments; use "
            "--gcp-project-id for GCP"
        )
    return _build_gcs_backend(env_dir, environment, project_id, gcp_project_id)


def _build_gcs_backend(
    env_dir: str,
    environment: str,
    project_id: Optional[str],
    gcp_project_id: Optional[str],
) -> GcsStateBackend:
    if project_id and gcp_project_id:
        ids = ProjectIds(project_id=project_id, gcp_project_id=gcp_project_id)
        print(f"{Colors.green('Using command-line project IDs:')}")
        print(f"  project_id: {ids['project_id']}")
        print(f"  gcp_project_id: {ids['gcp_project_id']}")
    elif project_id or gcp_project_id:
        raise ProjectConfigError(
            "Both --project-id and --gcp-project-id must be provided together"
        )
    else:
        ids = get_project_ids(env_dir)

    check_gcloud_auth()

    bucket_name = get_bucket_name(ids["project_id"], environment)
    print(f"{Colors.blue('GCP Project: ' + ids['gcp_project_id'])}")

    return GcsStateBackend(bucket_name, ids["gcp_project_id"])


def _build_azure_backend(
    env_dir: str,
    environment: str,
    project_id: Optional[str],
    azure_subscription_id: Optional[str],
) -> AzureBlobStateBackend:
    if project_id and azure_subscription_id:
        config = AzureConfig(
            project_id=project_id, azure_subscription_id=azure_subscription_id
        )
        print(f"{Colors.green('Using command-line Azure config:')}")
        print(f"  project_id: {config['project_id']}")
        print(f"  azure_subscription_id: {config['azure_subscription_id']}")
    elif project_id or azure_subscription_id:
        raise ProjectConfigError(
            "Both --project-id and --azure-subscription-id must be provided "
            "together"
        )
    else:
        config = get_azure_config(env_dir)

    check_azure_auth()

    location = resolve_azure_storage(
        config["project_id"], environment, config["azure_subscription_id"]
    )
    print(f"{Colors.blue('Azure Subscription: ' + config['azure_subscription_id'])}")
    print(f"{Colors.blue('Storage account: ' + location.account_name)}")

    return AzureBlobStateBackend(
        location.account_name,
        location.container_name,
        location.resource_group,
        config["azure_subscription_id"],
    )
