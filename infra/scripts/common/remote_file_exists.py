"""Check whether a file exists in a GCS bucket."""

import subprocess


def remote_file_exists(bucket_name: str, filename: str, gcp_project_id: str) -> bool:
    """Return True if the file exists, or raise if the check fails."""
    result = subprocess.run(
        [
            "gcloud",
            "storage",
            "ls",
            f"gs://{bucket_name}/{filename}",
            f"--project={gcp_project_id}",
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode == 0:
        return True

    error_output = f"{result.stdout}\n{result.stderr}".lower()
    if "matched no objects" in error_output or "no urls matched" in error_output:
        return False

    raise RuntimeError(
        f"Unable to check whether gs://{bucket_name}/{filename} already exists: "
        f"{result.stderr.strip() or result.stdout.strip()}"
    )
