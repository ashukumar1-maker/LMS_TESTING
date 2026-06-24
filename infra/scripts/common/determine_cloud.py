"""Determine the cloud provider from CLI overrides, falling back to tfvars."""

from typing import Optional

from common.detect_cloud import detect_cloud
from common.types import Cloud


def determine_cloud(
    cli_cloud: Optional[str],
    gcp_project_id: Optional[str],
    azure_subscription_id: Optional[str],
    env_dir: str,
) -> Cloud:
    """
    Resolve the cloud provider for a sync operation.

    Precedence:
        1. An explicit ``-c/--cloud`` value wins.
        2. Else a cloud-specific override implies its cloud:
           ``--azure-subscription-id`` => ``azure``,
           ``--gcp-project-id`` => ``gcp``.
        3. Else fall back to tfvars-based detection (defaults to ``gcp``).

    ``project_id`` is intentionally not a signal because it is shared across
    clouds; only the cloud-specific overrides disambiguate the provider.
    """
    if cli_cloud:
        return cli_cloud  # type: ignore[return-value]
    if azure_subscription_id:
        return "azure"
    if gcp_project_id:
        return "gcp"
    return detect_cloud(env_dir)
