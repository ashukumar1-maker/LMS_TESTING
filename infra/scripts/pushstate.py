# /// script
# dependencies = [
# ]
# ///


"""Push Terraform state files from local environment to remote storage."""

import argparse
import os
import sys
from pathlib import Path
from typing import List

# Add common module to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from common import (
    AuthenticationError,
    BucketAccessError,
    Colors,
    ProjectConfigError,
    StateBackend,
    check_file_timestamps,
    confirm_with_conflicts,
    detect_environment,
    determine_cloud,
    find_numbered_tfstate_backups,
    get_env_dir,
    get_state_backend,
    is_tfstate_backup,
    load_sync_config,
)


def confirm_action(location_label: str, environment: str, force: bool = False) -> bool:
    """
    Confirm the push action.

    Args:
        location_label: Human-readable target location
        environment: Environment name
        force: If True, skip confirmation

    Returns:
        True if confirmed, False otherwise.
    """
    if force:
        return True

    print(
        f"{Colors.yellow('⚠️  WARNING: This will overwrite the remote state and tfvars files!')}"
    )
    print(f"{Colors.yellow(f'Environment: {environment}')}")
    print(f"{Colors.yellow(f'Location: {location_label}')}")
    print()

    while True:
        response = (
            input("Are you sure you want to continue? (yes/no): ").strip().lower()
        )

        if response in ["yes", "y"]:
            return True
        elif response in ["no", "n"]:
            print(Colors.red("Operation cancelled."))
            return False
        else:
            print("Please answer 'yes' or 'no'.")


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Push Terraform state and tfvars files from local environment directory to remote storage."
    )
    parser.add_argument(
        "-e", "--environment", help="Specify the environment (dev, staging, prod)"
    )
    parser.add_argument(
        "-f", "--force", action="store_true", help="Skip confirmation prompt"
    )
    parser.add_argument(
        "-c",
        "--cloud",
        choices=["gcp", "azure"],
        help="Override the cloud provider (default: detected from tfvars)",
    )
    parser.add_argument(
        "-p",
        "--project-id",
        help="Override project_id (e.g., 'my-project', 'fullstack-template-1')",
    )
    parser.add_argument(
        "-g",
        "--gcp-project-id",
        help="Override gcp_project_id (GCP only, e.g., 'my-project-dev')",
    )
    parser.add_argument(
        "-s",
        "--azure-subscription-id",
        help="Override azure_subscription_id (Azure only)",
    )

    args = parser.parse_args()

    # Determine environment
    environment = args.environment
    if not environment:
        environment = detect_environment()
        if not environment:
            print(
                f"{Colors.red('Error: Unable to detect environment from current directory.')}"
            )
            print(
                "Please run this script from an environment directory (e.g., infra/environments/dev)"
            )
            print("or specify the environment using the -e flag.")
            print()
            parser.print_help()
            return 1
        print(f"{Colors.green(f'Detected environment: {environment}')}")

    # Get environment directory
    script_dir = Path(__file__).parent  # This is the scripts dir
    env_dir = get_env_dir(environment, str(script_dir))

    # Validate environment directory exists
    if not os.path.isdir(env_dir):
        print(f"{Colors.red(f'Error: Environment directory not found: {env_dir}')}")
        return 1

    # Determine the cloud provider
    cloud = determine_cloud(
        args.cloud, args.gcp_project_id, args.azure_subscription_id, env_dir
    )
    print(f"{Colors.green(f'Cloud provider: {cloud}')}")

    # Resolve configuration, authenticate, and build the state backend
    try:
        backend: StateBackend = get_state_backend(
            cloud,
            env_dir,
            environment,
            project_id=args.project_id,
            gcp_project_id=args.gcp_project_id,
            azure_subscription_id=args.azure_subscription_id,
        )
    except ProjectConfigError as e:
        print(f"{Colors.red('Error:')} {e}")
        return 1
    except AuthenticationError as e:
        print(f"{Colors.red('Error:')} {e}")
        return 1
    except BucketAccessError as e:
        print(f"{Colors.red('Error:')} {e}")
        return 1

    print(f"{Colors.blue(f'Target location: {backend.location_label}')}")

    # Check access
    try:
        backend.check_access("write")
    except BucketAccessError as e:
        print(f"{Colors.red('Error:')} {e}")
        return 1

    # Load sync configuration
    config_file = os.path.join(env_dir, ".tfstate-sync.yaml")
    if not os.path.exists(config_file):
        config_file = os.path.join(script_dir, ".tfstate-sync.yaml")

    config = load_sync_config(config_file)

    # Check which files exist locally
    print()
    print("Local files found:")
    files_to_push: List[str] = []

    # Check individual files
    for filename in config["files"]:
        filepath = os.path.join(env_dir, filename)
        if os.path.exists(filepath):
            print(f"{Colors.green(f'✓ {filename}')}")
            files_to_push.append(filename)
        else:
            print(f"{Colors.yellow(f'✗ {filename} (not found)')}")

    for filename in find_numbered_tfstate_backups(env_dir):
        if filename not in files_to_push:
            print(f"{Colors.green(f'✓ {filename}')}")
            files_to_push.append(filename)

    if not files_to_push:
        print()
        print(f"{Colors.red(f'Error: No files found to push in {env_dir}')}")
        return 1

    # Numbered backups are only pushed when they are not already in the remote
    # store. Terraform's default backup file is refreshed on every push.
    files_to_upload: List[str] = []
    try:
        for filename in files_to_push:
            existing_numbered_backup = (
                filename != "terraform.tfstate.backup"
                and is_tfstate_backup(filename)
                and backend.remote_file_exists(filename)
            )
            if existing_numbered_backup:
                print(
                    f"{Colors.yellow(f'↷ {filename} (already in remote, skipping)')}"
                )
                continue
            files_to_upload.append(filename)
    except RuntimeError as e:
        print(f"{Colors.red('Error:')} {e}")
        return 1

    if not files_to_upload:
        print()
        print(f"{Colors.yellow('No new files to push.')}")
        return 0

    # Show current remote files
    print()
    backend.list_remote_files()

    # Check timestamps and warn about conflicts
    if files_to_upload:
        result, status = check_file_timestamps(
            "push",
            backend,
            env_dir,
            files_to_upload,
        )

        # For push, we only care about timestamp conflicts
        if status == "has_conflicts":
            # Timestamp conflicts detected
            if not args.force:
                if not confirm_with_conflicts("You may overwrite newer remote files."):
                    return 1

    # Confirm action
    print()
    if not confirm_action(backend.location_label, environment, args.force):
        return 1

    # Push files
    print("Pushing files...")
    upload_failed = False

    for filename in files_to_upload:
        if not backend.upload(filename, env_dir):
            upload_failed = True
            break

    if upload_failed:
        print(f"{Colors.red('Error: Upload failed')}")
        return 1

    print()
    print(f"{Colors.green('Push complete!')}")
    print(f"Files uploaded to: {backend.location_label}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
