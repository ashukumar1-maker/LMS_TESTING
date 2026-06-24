"""Construct bucket name for terraform state."""


def get_bucket_name(project_id: str, environment: str) -> str:
    """
    Construct the bucket name for terraform state.

    Args:
        project_id: The project ID
        environment: The environment name

    Returns:
        The constructed bucket name.
    """
    return f"{project_id}-{environment}-tfstate"
