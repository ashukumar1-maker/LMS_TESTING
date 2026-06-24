# /// script
# dependencies = [
# ]
# ///


"""Pull Terraform state files from remote storage to local environment."""

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
    confirm_replacement,
    confirm_with_conflicts,
    detect_environment,
    determine_cloud,
    get_env_dir,
    get_state_backend,
    is_tfstate_backup,
    load_sync_config,
)


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Pull Terraform state and tfvars files from remote storage to local environment directory."
    )
    parser.add_argument(
        "-e", "--environment", help="Specify the environment (dev, staging, prod)"
    )
    parser.add_argument(
        "-f", "--force", action="store_true", help="Skip confirmation prompts"
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

    print(f"{Colors.yellow(f'Source location: {backend.location_label}')}")

    # Check access
    try:
        backend.check_access("read")
    except BucketAccessError as e:
        print(f"{Colors.red('Error:')} {e}")
        return 1

    # Load sync configuration
    config_file = os.path.join(env_dir, ".tfstate-sync.yaml")
    if not os.path.exists(config_file):
        config_file = os.path.join(script_dir, ".tfstate-sync.yaml")

    config = load_sync_config(config_file)

    # List available files
    print()
    backend.list_remote_files()

    # Gather all files that will be downloaded
    print()
    print("Checking which files to download...")
    files_to_download: List[str] = []

    # Check individual files (skip tfstate backups on pull)
    for filename in config["files"]:
        if is_tfstate_backup(filename):
            continue

        try:
            if backend.remote_file_exists(filename):
                files_to_download.append(filename)
        except RuntimeError as e:
            print(f"{Colors.red('Error:')} {e}")
            return 1

    # Check timestamps and warn about conflicts
    if files_to_download:
        result, status = check_file_timestamps(
            "pull",
            backend,
            env_dir,
            files_to_download,
        )

        # Handle different scenarios based on status
        if status == "will_replace":
            # Files will be replaced (no timestamp conflicts)
            if not confirm_replacement(args.force):
                return 1
        elif status == "has_conflicts":
            # Files will be replaced AND there are timestamp conflicts
            if not confirm_replacement(args.force):
                return 1
            # Ask for additional confirmation about timestamp conflicts
            if not args.force:
                if not confirm_with_conflicts("You may lose newer local changes."):
                    return 1

    print()
    print("Starting download...")

    # Download explicit non-backup files
    for filename in files_to_download:
        backend.download(filename, env_dir)

    print()
    print(f"{Colors.green('Pull complete!')}")
    print(f"Files downloaded to: {env_dir}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
