"""Check access to GCS bucket."""

import subprocess

from common.exceptions import BucketAccessError
from common.types import AccessType


def check_bucket_access(
    bucket_name: str, gcp_project_id: str, access_type: AccessType
) -> None:
    """
    Check if user has access to the specified GCS bucket.

    Args:
        bucket_name: Name of the GCS bucket
        gcp_project_id: GCP project ID
        access_type: Type of access needed ('read' or 'write')

    Raises:
        BucketAccessError: If bucket cannot be accessed.
    """
    print("Checking bucket access...")

    try:
        result = subprocess.run(
            [
                "gcloud",
                "storage",
                "ls",
                f"gs://{bucket_name}",
                f"--project={gcp_project_id}",
            ],
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            error_msg = f"Unable to access bucket gs://{bucket_name}\n"
            error_msg += "Please ensure you have the necessary permissions to access this bucket.\n"
            error_msg += "Possible issues:\n"
            error_msg += (
                "  - You need to run 'gcloud auth login' to authenticate with gcloud\n"
            )

            if access_type == "write":
                error_msg += "  - Your account may not have Storage Object Viewer and Creator permissions\n"
            else:
                error_msg += (
                    "  - Your account may not have Storage Object Viewer permissions\n"
                )

            error_msg += "  - The bucket may not exist yet\n"
            error_msg += f"  - The GCP project ID '{gcp_project_id}' may be incorrect"

            raise BucketAccessError(error_msg)

    except FileNotFoundError as e:
        raise BucketAccessError(
            "gcloud CLI not found. Please install Google Cloud SDK."
        ) from e
