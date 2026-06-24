"""Check Azure CLI authentication status."""

import subprocess

from common.colors import Colors
from common.exceptions import AuthenticationError


def check_azure_auth() -> None:
    """
    Check if user is authenticated with the Azure CLI.

    Raises:
        AuthenticationError: If not authenticated or the az CLI is not found.
    """
    print("Checking Azure authentication...")

    try:
        result = subprocess.run(
            ["az", "account", "show", "--query", "user.name", "--output", "tsv"],
            capture_output=True,
            text=True,
        )

        if result.returncode == 0 and result.stdout.strip():
            print(f"{Colors.green('✓ Authenticated with Azure')}")
        else:
            raise AuthenticationError(
                "You are not authenticated with the Azure CLI.\n"
                "Please run:\n"
                f"{Colors.yellow('  az login')}"
            )

    except FileNotFoundError as e:
        raise AuthenticationError(
            "Azure CLI not found. Please install the Azure CLI (az)."
        ) from e
