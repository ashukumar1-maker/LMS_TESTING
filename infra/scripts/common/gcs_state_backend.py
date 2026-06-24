"""GCS-backed Terraform state backend."""

import re
import subprocess
from datetime import datetime

from common.check_bucket_access import check_bucket_access
from common.download_file import download_file
from common.list_remote_files import list_remote_files
from common.remote_file_exists import remote_file_exists
from common.state_backend import StateBackend
from common.types import AccessType
from common.upload_file import upload_file


class GcsStateBackend(StateBackend):
    """Sync Terraform state to a Google Cloud Storage bucket via ``gcloud``."""

    def __init__(self, bucket_name: str, gcp_project_id: str) -> None:
        self.bucket_name = bucket_name
        self.gcp_project_id = gcp_project_id

    @property
    def location_label(self) -> str:
        return f"gs://{self.bucket_name}"

    def check_access(self, access_type: AccessType) -> None:
        check_bucket_access(self.bucket_name, self.gcp_project_id, access_type)

    def list_remote_files(self) -> None:
        list_remote_files(self.bucket_name, self.gcp_project_id)

    def remote_file_exists(self, filename: str) -> bool:
        return remote_file_exists(self.bucket_name, filename, self.gcp_project_id)

    def get_remote_mtime(self, filename: str) -> int:
        try:
            result = subprocess.run(
                [
                    "gcloud",
                    "storage",
                    "stat",
                    f"gs://{self.bucket_name}/{filename}",
                    f"--project={self.gcp_project_id}",
                ],
                capture_output=True,
                text=True,
            )

            if result.returncode == 0 and result.stdout:
                # Looking for a line like: "Update time: 2024-01-15T10:30:45Z"
                match = re.search(r"Update time:\s*(.+)", result.stdout)
                if match:
                    time_str = match.group(1).strip().rstrip("Z")
                    try:
                        return int(datetime.fromisoformat(time_str).timestamp())
                    except Exception:
                        return 0

            return 0

        except Exception:
            return 0

    def upload(self, filename: str, local_path: str) -> bool:
        return upload_file(self.bucket_name, filename, local_path, self.gcp_project_id)

    def download(self, filename: str, local_path: str) -> bool:
        return download_file(
            self.bucket_name, filename, local_path, self.gcp_project_id
        )
