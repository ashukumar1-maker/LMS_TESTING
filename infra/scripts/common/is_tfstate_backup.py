"""Check whether a filename is a Terraform state backup."""

import fnmatch


def is_tfstate_backup(filename: str) -> bool:
    """Return True if the filename is a Terraform state backup."""
    return filename == "terraform.tfstate.backup" or fnmatch.fnmatch(
        filename, "terraform.tfstate.*.backup"
    )
