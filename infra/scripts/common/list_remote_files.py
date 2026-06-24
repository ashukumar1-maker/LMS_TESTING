"""List files in GCS bucket."""

import subprocess


def list_remote_files(bucket_name: str, gcp_project_id: str) -> None:
    """
    List files in the specified GCS bucket.

    Args:
        bucket_name: Name of the GCS bucket
        gcp_project_id: GCP project ID
    """
    print(f"Remote files in gs://{bucket_name}:")

    try:
        result = subprocess.run(
            [
                "gcloud",
                "storage",
                "ls",
                "-l",
                f"gs://{bucket_name}/",
                f"--project={gcp_project_id}",
            ],
            capture_output=True,
            text=True,
        )

        if result.returncode == 0 and result.stdout.strip():
            print(result.stdout)
        else:
            print("No remote files found")

    except Exception:
        print("No remote files found")
