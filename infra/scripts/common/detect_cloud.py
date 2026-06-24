"""Detect the cloud provider for an environment from its tfvars."""

import re

from common.find_tfvars_file import find_tfvars_file
from common.types import Cloud

DEFAULT_CLOUD: Cloud = "gcp"


def detect_cloud(env_dir: str) -> Cloud:
    """
    Determine the cloud provider for an environment from its tfvars file.

    The provider is inferred from the cloud-specific identifier present in the
    tfvars: ``azure_subscription_id`` implies Azure and ``gcp_project_id``
    implies GCP. The ``cloud`` variable is intentionally not consulted because
    environments rely on its per-environment default rather than setting it in
    tfvars, so it is not a reliable signal here.

    Defaults to ``gcp`` when nothing can be determined, preserving the
    historical GCP-only behavior.
    """
    tfvars_file = find_tfvars_file(env_dir)
    if tfvars_file is None:
        return DEFAULT_CLOUD

    try:
        content = tfvars_file.read_text()
    except IOError:
        return DEFAULT_CLOUD

    if re.search(r'^\s*azure_subscription_id\s*=', content, re.MULTILINE):
        return "azure"
    if re.search(r'^\s*gcp_project_id\s*=', content, re.MULTILINE):
        return "gcp"

    return DEFAULT_CLOUD
