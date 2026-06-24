"""Load sync configuration from YAML-like files."""

import os
import re

from common.colors import Colors
from common.types import SyncConfig

# Default configuration
DEFAULT_SYNC_FILES = [
    "terraform.tfstate",
    "terraform.tfstate.backup",
    "terraform.auto.tfvars",
    "terraform.tfvars",
]


def load_sync_config(config_file: str) -> SyncConfig:
    """
    Load sync configuration from a YAML-like file.

    Args:
        config_file: Path to the configuration file

    Returns:
        SyncConfig with files to sync.
    """
    # Start with defaults
    files = DEFAULT_SYNC_FILES.copy()

    if os.path.exists(config_file):
        print(f"Loading configuration from {config_file}...")

        try:
            with open(config_file, "r") as f:
                content = f.read()

            # Simple YAML-like parser
            in_files = False
            custom_files_found = False
            unsupported_patterns_found = False

            for line in content.split("\n"):
                # Skip empty lines and comments
                if not line.strip() or line.strip().startswith("#"):
                    continue

                # Check for section headers
                if line.strip() == "files:":
                    in_files = True
                    if not custom_files_found:
                        files = []  # Clear defaults on first custom config
                        custom_files_found = True
                    continue
                elif line.strip() == "patterns:":
                    in_files = False
                    unsupported_patterns_found = True
                    continue
                elif not line.startswith((" ", "\t", "-")):
                    in_files = False

                # Parse list items
                match = re.match(r"^\s*-\s+(.+)$", line)
                if match:
                    item = match.group(1).strip()
                    # Remove quotes if present
                    item = item.strip("\"'")

                    if in_files:
                        files.append(item)

            if unsupported_patterns_found:
                print(
                    f"{Colors.yellow('Warning:')} patterns are not supported and were ignored"
                )
            print(Colors.green("✓ Configuration loaded"))

        except Exception as e:
            print(f"{Colors.yellow('Warning:')} Failed to load config: {e}")
            print("Using default configuration")

    return SyncConfig(files=files)
