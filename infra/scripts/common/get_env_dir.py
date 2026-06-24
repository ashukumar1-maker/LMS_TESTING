"""Get environment directory path."""

from pathlib import Path


def get_env_dir(environment: str, script_dir: str) -> str:
    """
    Get the environment directory path.

    Args:
        environment: The environment name (e.g., 'dev', 'staging', 'prod')
        script_dir: The directory containing the script

    Returns:
        The full path to the environment directory.
    """
    # Go up from scripts dir to infra dir
    infra_root = Path(script_dir).parent
    env_dir = infra_root / "environments" / environment

    return str(env_dir)
