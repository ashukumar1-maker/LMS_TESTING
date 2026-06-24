# Common Package for Terraform State Sync Scripts

This package contains all shared functionality for the terraform state sync scripts.

## Structure

```
common/
├── __init__.py           # Package initialization and exports
├── types.py              # Type definitions (TypedDict, Literal types)
├── exceptions.py         # Custom exception classes
├── colors.py             # Terminal color handling
├── detect_environment.py # Environment detection from directory
├── detect_cloud.py       # Infer cloud provider from tfvars identifiers
├── get_env_dir.py        # Get environment directory path
├── find_tfvars_file.py   # Locate the env tfvars file
├── get_project_ids.py    # Extract GCP project IDs (with manual fallback)
├── get_azure_config.py   # Extract Azure project_id + subscription
├── get_bucket_name.py    # Construct GCS bucket name
├── state_backend.py      # StateBackend abstract interface
├── get_state_backend.py  # Backend factory (config + auth + backend)
├── gcs_state_backend.py  # GCS backend implementation
├── azure_state_backend.py # Azure Blob backend implementation
├── check_gcloud_auth.py  # Verify gcloud authentication
├── check_azure_auth.py   # Verify Azure CLI authentication
├── resolve_azure_storage.py # Resolve Azure storage account + container
├── check_bucket_access.py # Verify GCS bucket permissions
├── list_remote_files.py  # List files in GCS bucket
├── remote_file_exists.py # Check file existence in GCS bucket
├── download_file.py      # Download single file from GCS
├── upload_file.py        # Upload single file to GCS
├── find_numbered_tfstate_backups.py # Find numbered local tfstate backups
├── check_file_timestamps.py  # Compare file timestamps
├── format_time_diff.py   # Format time differences
├── format_timestamp.py   # Format timestamps to readable dates
├── load_sync_config.py   # Load YAML configuration
├── confirm_replacement.py # Prompt for file replacement
└── confirm_with_conflicts.py # Prompt on timestamp conflicts
```

## Key Components

### Type Definitions (`types.py`)
- `ProjectIds` - TypedDict for project_id and gcp_project_id
- `AzureConfig` - TypedDict for project_id and azure_subscription_id
- `SyncConfig` - TypedDict for explicit files to sync
- `Cloud` - Literal type for "gcp" or "azure"
- `AccessType` - Literal type for "read" or "write" access
- `TimestampStatus` - Literal type for timestamp check results

### Exception Classes (`exceptions.py`)
- `TerraformSyncError` - Base exception class
- `EnvironmentError` - Environment detection failures
- `ProjectConfigError` - Project ID extraction failures
- `AuthenticationError` - Cloud CLI auth failures
- `BucketAccessError` - Remote store access failures
- `FileOperationError` - File operation failures
- `ConfigurationError` - Config file loading failures

### State Backends

`StateBackend` (`state_backend.py`) is the cloud-agnostic interface the sync
scripts use. Implementations:

- `GcsStateBackend` - GCS via `gcloud`
- `AzureBlobStateBackend` - Azure Blob Storage via `az`

`get_state_backend(cloud, env_dir, environment, ...)` resolves configuration,
verifies authentication, and returns the appropriate backend.

### Core Functions

#### Environment and Configuration
- `detect_environment()` - Auto-detect from current directory
- `detect_cloud()` - Infer cloud provider from tfvars identifiers (defaults to gcp)
- `get_project_ids()` - Extract GCP IDs from tfvars (prompts if missing)
- `get_azure_config()` - Extract Azure config from tfvars (prompts if missing)
- `load_sync_config()` - Load YAML configuration with defaults

#### Authentication and Access
- `check_gcloud_auth()` - Raises AuthenticationError if not authenticated
- `check_azure_auth()` - Raises AuthenticationError if not authenticated
- `check_bucket_access()` - Raises BucketAccessError if no access
- `resolve_azure_storage()` - Resolve the Azure storage account holding state

#### File Operations
- `download_file()` - Returns bool for success
- `upload_file()` - Returns bool for success
- `list_remote_files()` - Prints remote file listing

#### Timestamp Handling
- `check_file_timestamps()` - Returns (TimestampCheckResult, TimestampStatus)
- Status values: "no_changes", "will_replace", "has_conflicts"

#### User Interaction
- `confirm_replacement()` - Returns bool
- `confirm_with_conflicts()` - Returns bool

## Design Principles

1. **Single Responsibility**: Each file contains one function
2. **Type Safety**: Full type annotations throughout
3. **Exception-Based**: Critical functions raise exceptions instead of returning error codes
4. **No Side Effects**: Functions are focused and predictable
5. **User-Friendly**: Interactive prompts when configuration is missing

## Usage

Functions are imported at the package level:

```python
from common import (
    check_gcloud_auth,
    get_project_ids,
    ProjectConfigError,
    AuthenticationError
)

try:
    check_gcloud_auth()
    project_ids = get_project_ids(env_dir)
except AuthenticationError as e:
    print(f"Auth error: {e}")
except ProjectConfigError as e:
    print(f"Config error: {e}")
```