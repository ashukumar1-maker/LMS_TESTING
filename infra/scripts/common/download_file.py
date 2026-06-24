"""Download a file from GCS."""

import os
import subprocess

from common.colors import Colors


def download_file(
    bucket_name: str, filename: str, local_path: str, gcp_project_id: str
) -> bool:
    """
    Download a single file from GCS.

    Args:
        bucket_name: Name of the GCS bucket
        filename: Name of the file to download
        local_path: Local directory to download to
        gcp_project_id: GCP project ID

    Returns:
        True if download successful, False otherwise.
    """
    print(f"Downloading {filename}... ", end="", flush=True)

    local_file = os.path.join(local_path, filename)

    try:
        result = subprocess.run(
            [
                "gcloud",
                "storage",
                "cp",
                f"gs://{bucket_name}/{filename}",
                local_file,
                f"--project={gcp_project_id}",
            ],
            capture_output=True,
            text=True,
        )

        if result.returncode == 0:
            print(Colors.green("✓"))
            return True
        else:
            print(Colors.yellow("⚠ Not found"))
            return False

    except Exception:
        print(Colors.yellow("⚠ Not found"))
        return False
