"""Common functions for terraform state sync scripts."""

# Import all functions to make them available at package level
from common.azure_state_backend import AzureBlobStateBackend
from common.check_azure_auth import check_azure_auth
from common.check_bucket_access import check_bucket_access
from common.check_file_timestamps import check_file_timestamps
from common.check_gcloud_auth import check_gcloud_auth
from common.colors import Colors
from common.confirm_replacement import confirm_replacement
from common.confirm_with_conflicts import confirm_with_conflicts
from common.detect_cloud import detect_cloud
from common.detect_environment import detect_environment
from common.determine_cloud import determine_cloud
from common.download_file import download_file
from common.exceptions import (
    AuthenticationError,
    BucketAccessError,
    ConfigurationError,
    EnvironmentError,
    FileOperationError,
    ProjectConfigError,
    TerraformSyncError,
)
from common.find_numbered_tfstate_backups import find_numbered_tfstate_backups
from common.find_tfvars_file import find_tfvars_file
from common.gcs_state_backend import GcsStateBackend
from common.is_tfstate_backup import is_tfstate_backup
from common.remote_file_exists import remote_file_exists
from common.format_time_diff import format_time_diff
from common.format_timestamp import format_timestamp
from common.get_azure_config import get_azure_config
from common.get_bucket_name import get_bucket_name
from common.get_env_dir import get_env_dir
from common.get_project_ids import get_project_ids
from common.get_state_backend import get_state_backend
from common.list_remote_files import list_remote_files
from common.load_sync_config import load_sync_config
from common.resolve_azure_storage import resolve_azure_storage
from common.state_backend import StateBackend
from common.types import AzureConfig, Cloud, ProjectIds
from common.upload_file import upload_file

__all__ = [
    "Colors",
    "detect_cloud",
    "determine_cloud",
    "detect_environment",
    "find_tfvars_file",
    "get_env_dir",
    "get_project_ids",
    "get_azure_config",
    "get_bucket_name",
    "get_state_backend",
    "resolve_azure_storage",
    "check_gcloud_auth",
    "check_azure_auth",
    "check_bucket_access",
    "list_remote_files",
    "download_file",
    "upload_file",
    "find_numbered_tfstate_backups",
    "is_tfstate_backup",
    "remote_file_exists",
    "check_file_timestamps",
    "format_time_diff",
    "format_timestamp",
    "load_sync_config",
    "confirm_with_conflicts",
    "confirm_replacement",
    # Backends
    "StateBackend",
    "GcsStateBackend",
    "AzureBlobStateBackend",
    # Types
    "ProjectIds",
    "AzureConfig",
    "Cloud",
    # Exceptions
    "TerraformSyncError",
    "EnvironmentError",
    "ProjectConfigError",
    "AuthenticationError",
    "BucketAccessError",
    "FileOperationError",
    "ConfigurationError",
]
