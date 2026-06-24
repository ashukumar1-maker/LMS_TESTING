"""Check gcloud authentication status."""

import subprocess

from common.colors import Colors
from common.exceptions import AuthenticationError


def check_gcloud_auth() -> None:
    """
    Check if user is authenticated with gcloud.

    Raises:
        AuthenticationError: If not authenticated or gcloud CLI not found.
    """
    print("Checking gcloud authentication...")

    try:
        result = subprocess.run(
            [
                "gcloud",
                "auth",
                "list",
                "--filter=status:ACTIVE",
                "--format=value(account)",
            ],
            capture_output=True,
            text=True,
            check=True,
        )

        if result.stdout.strip():
            print(f"{Colors.green('✓ Authenticated with gcloud')}")
        else:
            raise AuthenticationError(
                "You are not authenticated with gcloud.\n"
                "Please run:\n"
                f"{Colors.yellow('  gcloud auth login')}"
            )

    except subprocess.CalledProcessError as e:
        raise AuthenticationError(f"Error checking gcloud auth: {e}") from e
    except FileNotFoundError as e:
        raise AuthenticationError(
            "gcloud CLI not found. Please install Google Cloud SDK."
        ) from e
