"""Upload a file to GCS."""

import os
import subprocess

from common.colors import Colors


def upload_file(
    bucket_name: str, filename: str, local_path: str, gcp_project_id: str
) -> bool:
    """
    Upload a single file to GCS.

    Args:
        bucket_name: Name of the GCS bucket
        filename: Name of the file to upload
        local_path: Local directory containing the file
        gcp_project_id: GCP project ID

    Returns:
        True if upload successful, False otherwise.
    """
    print(f"Uploading {filename}... ", end="", flush=True)

    local_file = os.path.join(local_path, filename)

    try:
        result = subprocess.run(
            [
                "gcloud",
                "storage",
                "cp",
                local_file,
                f"gs://{bucket_name}/{filename}",
                f"--project={gcp_project_id}",
            ],
            capture_output=True,
            text=True,
            check=True,
        )

        print(Colors.green("✓"))
        return True

    except subprocess.CalledProcessError as e:
        print(Colors.red("✗ Failed"))
        if e.stderr:
            print(f"  {e.stderr.strip()}")
        return False
    except Exception as e:
        print(Colors.red("✗ Failed"))
        print(f"  {str(e)}")
        return False
