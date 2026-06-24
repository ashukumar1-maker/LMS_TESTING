"""Locate the tfvars file for an environment."""

from pathlib import Path
from typing import Optional

# Checked in priority order. GCP environments use terraform.auto.tfvars; Azure
# environments may use either. The first existing file wins.
TFVARS_FILENAMES = ["terraform.auto.tfvars", "terraform.tfvars"]


def find_tfvars_file(env_dir: str) -> Optional[Path]:
    """
    Return the path to the environment's tfvars file, or None if absent.
    """
    for filename in TFVARS_FILENAMES:
        candidate = Path(env_dir) / filename
        if candidate.exists():
            return candidate

    return None
