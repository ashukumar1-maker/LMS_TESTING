"""Detect environment from current directory."""

import os
import re
from typing import Optional


def detect_environment() -> Optional[str]:
    """
    Detect environment from current directory.

    Returns:
        Environment name if in an environment directory, None otherwise.
    """
    current_dir = os.getcwd()
    match = re.search(r"infra/environments/([^/]+)$", current_dir)

    if match:
        return match.group(1)

    return None
