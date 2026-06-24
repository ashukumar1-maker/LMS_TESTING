"""Format time differences in human readable format."""


def format_time_diff(seconds: int) -> str:
    """
    Format a time difference in seconds to human readable format.

    Args:
        seconds: Time difference in seconds

    Returns:
        Human readable time difference (e.g., "2h", "3d").
    """
    if seconds < 60:
        return f"{seconds}s"
    elif seconds < 3600:
        return f"{seconds // 60}m"
    elif seconds < 86400:
        return f"{seconds // 3600}h"
    else:
        return f"{seconds // 86400}d"
