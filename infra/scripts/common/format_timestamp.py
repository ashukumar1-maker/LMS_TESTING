"""Format timestamp to human readable date."""

from datetime import datetime


def format_timestamp(timestamp: int) -> str:
    """
    Format a timestamp to human readable date.

    Args:
        timestamp: Unix timestamp in seconds

    Returns:
        Formatted date string or "Unknown" if timestamp is 0.
    """
    if timestamp == 0:
        return "Unknown"

    try:
        dt = datetime.fromtimestamp(timestamp)
        return dt.strftime("%Y-%m-%d %H:%M:%S")
    except Exception:
        return "Unknown"
