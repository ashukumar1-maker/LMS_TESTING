"""Find local numbered Terraform state backup files."""

import glob
import os
from typing import List


def find_numbered_tfstate_backups(directory: str) -> List[str]:
    """Return numbered Terraform state backup filenames in the directory."""
    full_pattern = os.path.join(directory, "terraform.tfstate.*.backup")
    matching_files = glob.glob(full_pattern)

    return [os.path.basename(f) for f in matching_files if os.path.isfile(f)]
