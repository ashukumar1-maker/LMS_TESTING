"""Constants for the Feedback API."""

from src.models import ColumnId, Status

# Status that corresponds to each column when auto-transitioning
COLUMN_TO_STATUS: dict[ColumnId, Status] = {
    "inProgress": "in_progress",
    "done": "done",
}

# Valid statuses for each column
COLUMN_VALID_STATUSES: dict[ColumnId, set[Status]] = {
    "backlog": {"in_review", "triaged"},
    "inProgress": {"in_progress"},
    "done": {"done"},
}

# Convenience alias for backlog (used in validation messages)
BACKLOG_STATUSES: set[Status] = COLUMN_VALID_STATUSES["backlog"]
