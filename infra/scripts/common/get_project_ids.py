"""Extract project IDs from terraform.auto.tfvars."""

import re

from common.colors import Colors
from common.exceptions import ProjectConfigError
from common.find_tfvars_file import find_tfvars_file
from common.types import ProjectIds


def get_project_ids(env_dir: str) -> ProjectIds:
    """
    Extract project_id and gcp_project_id from the environment tfvars file.

    Args:
        env_dir: The environment directory path

    Returns:
        Dictionary with project IDs.

    Raises:
        ProjectConfigError: If project IDs cannot be extracted.
    """
    tfvars_file = find_tfvars_file(env_dir)

    if tfvars_file is None:
        print(
            f"{Colors.yellow('Warning:')} no tfvars file found in {env_dir}"
        )
        print("Please enter the project IDs manually:")

        # Prompt for project_id
        while True:
            project_id = input("Enter project_id: ").strip()
            if project_id:
                break
            print(f"{Colors.red('Error:')} project_id cannot be empty")

        # Prompt for gcp_project_id
        while True:
            gcp_project_id = input("Enter gcp_project_id: ").strip()
            if gcp_project_id:
                break
            print(f"{Colors.red('Error:')} gcp_project_id cannot be empty")

        return ProjectIds(project_id=project_id, gcp_project_id=gcp_project_id)

    try:
        with open(tfvars_file, "r") as f:
            content = f.read()

        # Extract project_id
        project_id_match = re.search(
            r'^\s*project_id\s*=\s*"([^"]+)"', content, re.MULTILINE
        )
        if not project_id_match:
            raise ProjectConfigError(f"Could not extract project_id from {tfvars_file}")

        # Extract gcp_project_id
        gcp_project_id_match = re.search(
            r'^\s*gcp_project_id\s*=\s*"([^"]+)"', content, re.MULTILINE
        )
        if not gcp_project_id_match:
            raise ProjectConfigError(
                f"Could not extract gcp_project_id from {tfvars_file}"
            )

        return ProjectIds(
            project_id=project_id_match.group(1).strip(),
            gcp_project_id=gcp_project_id_match.group(1).strip(),
        )

    except IOError as e:
        raise ProjectConfigError(f"Failed to read {tfvars_file}: {e}") from e
