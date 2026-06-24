# Terraform State Sync Scripts

These UV scripts help synchronize Terraform state files between local
environments and remote object storage. They support both Google Cloud Storage
(GCS) for GCP environments and Azure Blob Storage for Azure environments.

## Scripts

- **pullstate.py** - Downloads state files from remote storage to local environment
- **pushstate.py** - Uploads state files from local environment to remote storage
- **common/** - Package containing shared functions and utilities

These scripts have no dependencies other than the Python standard library and
the cloud CLI for the target environment (`gcloud` for GCP, `az` for Azure).

## Cloud Selection

The scripts choose a backend by inspecting the environment's tfvars file
(`terraform.auto.tfvars`, falling back to `terraform.tfvars`):

- A `gcp_project_id` value (or no recognized identifier) syncs to a GCS bucket via `gcloud`.
- An `azure_subscription_id` value syncs to an Azure Blob Storage container via `az`.

Detection uses these identifiers rather than the Terraform `cloud` variable,
which is typically left at its per-environment default and not written to
tfvars. Use `-c/--cloud` to override the detected provider. When `-c/--cloud`
is omitted, supplying `-s/--azure-subscription-id` implies Azure and
`-g/--gcp-project-id` implies GCP before tfvars detection is consulted.

## Usage

### Pull State Files
```bash
# From within an environment directory
cd infra/environments/dev
uv run ../../scripts/pullstate.py

# From anywhere with environment flag
uv run infra/scripts/pullstate.py -e dev

# Skip confirmation prompts
uv run infra/scripts/pullstate.py -e dev -f

# Provide project IDs manually (useful when the tfvars file doesn't exist)
uv run infra/scripts/pullstate.py -e dev -p my-project -g my-project-dev

# Azure environment
uv run infra/scripts/pullstate.py -e azuretest
```

### Push State Files
```bash
# From within an environment directory
cd infra/environments/dev
uv run ../../scripts/pushstate.py

# With environment flag and force (skip confirmation)
uv run infra/scripts/pushstate.py -e dev -f

# Provide project IDs manually (useful when the tfvars file doesn't exist)
uv run infra/scripts/pushstate.py -e dev -p my-project -g my-project-dev

# Azure environment
uv run infra/scripts/pushstate.py -e azuretest
```

### Command-Line Options

Both scripts support the following flags:

- `-e, --environment` - Specify the environment (dev, staging, prod, azuretest)
- `-f, --force` - Skip all confirmation prompts
- `-c, --cloud` - Override the cloud provider (`gcp` or `azure`)
- `-p, --project-id` - Override project_id (e.g., 'my-project', 'fullstack-template-1')
- `-g, --gcp-project-id` - Override gcp_project_id, GCP only (e.g., 'my-project-dev')
- `-s, --azure-subscription-id` - Override azure_subscription_id, Azure only

**Note**: On GCP, when overriding IDs, both `-p` and `-g` must be provided
together. On Azure, both `-p` and `-s` must be provided together.

## Configuration

The scripts use a YAML configuration file to determine which files to sync. The configuration is loaded from (in order of priority):

1. Environment-specific: `infra/environments/<env>/.tfstate-sync.yaml`
2. Global default: `infra/scripts/.tfstate-sync.yaml`

Only explicit files listed under `files` are read from the config. Glob patterns are not supported. `pushstate.py` also auto-discovers local `terraform.tfstate.*.backup` files and uploads them only when they are not already in the remote store.

### Configuration Format

```yaml
# Explicit files to consider.
# terraform.tfstate and terraform.auto.tfvars are pulled and pushed.
# terraform.tfstate.backup is push-only and is refreshed in the remote store.
files:
  - terraform.tfstate
  - terraform.tfstate.backup
  - terraform.auto.tfvars
  - terraform.tfvars # Azure environments may use this filename
```

Numbered backup files such as `terraform.tfstate.123.backup` do not need to be listed here; `pushstate.py` discovers them automatically.

### Customizing for an Environment

To customize which files are synced for a specific environment, create a `.tfstate-sync.yaml` file in that environment's directory:

```bash
# Example: Only sync tfstate files for production
cat > infra/environments/prod/.tfstate-sync.yaml << EOF
files:
  - terraform.tfstate
  - terraform.tfstate.backup
EOF
```

## Safety Features

The scripts include several safety checks to prevent accidental data loss:

### File Replacement Confirmation

- **Pull**: Always asks for confirmation before replacing local files
- **Push**: Always asks for confirmation before uploading files

### Timestamp Checks

- **Pull**: Additionally warns if remote files are older than local files (you might lose newer local changes)
- **Push**: Warns if local files are older than remote files (you might overwrite newer remote data)

### Confirmation Prompts

1. **Pull**: 
   - First prompt: Confirms you want to replace local files
   - Second prompt (if applicable): Confirms you want to proceed despite timestamp conflicts

2. **Push**:
   - First prompt: Confirms you want to upload files
   - Second prompt (if applicable): Confirms you want to proceed despite timestamp conflicts

Use the `-f` flag to skip all confirmation prompts.

## Authentication

The scripts require authentication with the target cloud. If not authenticated,
you'll be prompted to run:

```bash
# GCP
gcloud auth login

# Azure
az login
```

Azure blob operations authenticate with the storage account access key, which
the scripts retrieve through the control plane (`az storage account keys
list`). This mirrors the default behavior of Terraform's `azurerm` backend and
works for any operator with control-plane access (Contributor or Owner) — no
separate `Storage Blob Data` data-plane role assignment is required. The
storage account must allow shared key access (the default).

## Project / Subscription Handling

### GCP

The scripts need both `project_id` and `gcp_project_id` to construct bucket names and access the correct GCP project:

1. **Default behavior**: Read from the tfvars file
2. **Manual input**: If the tfvars file doesn't exist, you'll be prompted to enter the values
3. **Command-line flags**: Use `-p` and `-g` flags to provide IDs directly (bypasses file reading and prompts)

- **project_id**: Your logical project identifier (e.g., 'my-project', 'fullstack-template-1')
  - Used to construct the bucket name `<project_id>-<environment>-tfstate`
  - Typically the same across all environments

- **gcp_project_id**: The actual Google Cloud Project ID where resources are deployed
  - Format: `<project_id>-<environment>` (e.g., 'my-project-dev', 'fullstack-template-1-staging')
  - Different for each environment

### Azure

The scripts need `project_id` and `azure_subscription_id`:

1. **Default behavior**: Read from the tfvars file
2. **Manual input**: If the tfvars file doesn't exist, you'll be prompted to enter the values
3. **Command-line flags**: Use `-p` and `-s` flags to provide values directly

Azure storage account names carry a random suffix and cannot be derived
directly. Instead, the scripts compute the deterministic resource group name
(`<project>-<environment>-rg`, mirroring the Terraform `name_prefix` local) and
discover the single storage account within it. Terraform state is read from and
written to that account's `terraform-state` blob container. The infrastructure
must therefore be provisioned (the storage account must exist) before state can
be synced.

## Architecture

The scripts are written in Python with a modular structure for maintainability:

### Common Package (`common/`)

The common package contains all shared functionality:

#### Core Types and Utilities
- **types.py** - Type definitions (TypedDict classes, Literal types)
- **exceptions.py** - Custom exception classes
- **colors.py** - Terminal color handling

#### Environment Functions
- **detect_environment.py** - Detect environment from current directory
- **detect_cloud.py** - Detect the cloud provider from the tfvars `cloud` value
- **get_env_dir.py** - Get environment directory path
- **find_tfvars_file.py** - Locate the env tfvars file (auto.tfvars or tfvars)
- **get_project_ids.py** - Extract GCP project IDs from tfvars (with manual input fallback)
- **get_azure_config.py** - Extract Azure project_id + subscription from tfvars
- **get_bucket_name.py** - Construct the GCS bucket name

#### State Backends
- **state_backend.py** - `StateBackend` abstract interface
- **get_state_backend.py** - Factory that resolves config, auth, and backend
- **gcs_state_backend.py** - `GcsStateBackend` (GCS via `gcloud`)
- **azure_state_backend.py** - `AzureBlobStateBackend` (Azure Blob via `az`)

#### GCloud Functions
- **check_gcloud_auth.py** - Check gcloud authentication (raises AuthenticationError)
- **check_bucket_access.py** - Verify bucket access permissions (raises BucketAccessError)
- **list_remote_files.py** - List files in GCS bucket
- **remote_file_exists.py** - Check whether a file exists in a GCS bucket

#### Azure Functions
- **check_azure_auth.py** - Check Azure CLI authentication (raises AuthenticationError)
- **resolve_azure_storage.py** - Resolve the storage account + state container

#### File Operations
- **download_file.py** - Download single file from GCS
- **upload_file.py** - Upload single file to GCS
- **find_numbered_tfstate_backups.py** - Find numbered local tfstate backups

#### Timestamp Functions
- **check_file_timestamps.py** - Compare timestamps and warn (returns TimestampStatus)
- **format_time_diff.py** - Format time differences (e.g., "2h")
- **format_timestamp.py** - Format timestamp to readable date

#### Configuration and Prompts
- **load_sync_config.py** - Load YAML configuration
- **confirm_replacement.py** - Prompt user for file replacement
- **confirm_with_conflicts.py** - Prompt user on timestamp conflicts

### Main Scripts

- **pullstate.py** and **pushstate.py** are the entry points that:
  - Parse command-line arguments
  - Handle exceptions raised by common functions
  - Orchestrate the sync operations
  - Return appropriate exit codes

### Key Design Decisions

1. **Cloud-Agnostic Backend**: A `StateBackend` interface abstracts GCS and Azure Blob so the scripts share one orchestration path
2. **Exception-Based Error Handling**: Functions raise specific exceptions instead of returning error codes
3. **String Status Values**: Uses meaningful strings like "has_conflicts" instead of numeric codes
4. **Type Safety**: Full type annotations throughout the codebase
5. **No External Dependencies**: Uses only Python standard library
6. **Interactive Fallbacks**: Prompts for manual input when configuration is missing

This design makes the scripts robust, maintainable, and user-friendly.