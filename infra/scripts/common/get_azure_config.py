"""Extract Azure config (project_id, subscription_id) from tfvars."""

import re

from common.colors import Colors
from common.exceptions import ProjectConfigError
from common.find_tfvars_file import find_tfvars_file
from common.types import AzureConfig


def get_azure_config(env_dir: str) -> AzureConfig:
    """
    Extract project_id and azure_subscription_id from the env tfvars file.

    Falls back to interactive prompts when the tfvars file is missing.

    Raises:
        ProjectConfigError: If values cannot be extracted from the file.
    """
    tfvars_file = find_tfvars_file(env_dir)

    if tfvars_file is None:
        print(f"{Colors.yellow('Warning:')} no tfvars file found in {env_dir}")
        print("Please enter the Azure configuration manually:")

        while True:
            project_id = input("Enter project_id: ").strip()
            if project_id:
                break
            print(f"{Colors.red('Error:')} project_id cannot be empty")

        while True:
            subscription_id = input("Enter azure_subscription_id: ").strip()
            if subscription_id:
                break
            print(f"{Colors.red('Error:')} azure_subscription_id cannot be empty")

        return AzureConfig(
            project_id=project_id, azure_subscription_id=subscription_id
        )

    try:
        content = tfvars_file.read_text()

        project_id_match = re.search(
            r'^\s*project_id\s*=\s*"([^"]+)"', content, re.MULTILINE
        )
        if not project_id_match:
            raise ProjectConfigError(f"Could not extract project_id from {tfvars_file}")

        subscription_id_match = re.search(
            r'^\s*azure_subscription_id\s*=\s*"([^"]+)"', content, re.MULTILINE
        )
        if not subscription_id_match:
            raise ProjectConfigError(
                f"Could not extract azure_subscription_id from {tfvars_file}"
            )

        return AzureConfig(
            project_id=project_id_match.group(1).strip(),
            azure_subscription_id=subscription_id_match.group(1).strip(),
        )

    except IOError as e:
        raise ProjectConfigError(f"Failed to read {tfvars_file}: {e}") from e
