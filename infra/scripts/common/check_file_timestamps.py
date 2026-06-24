"""Check file timestamps and warn about conflicts."""

import os
from dataclasses import dataclass
from typing import TYPE_CHECKING, Literal

from common.colors import Colors
from common.format_time_diff import format_time_diff
from common.format_timestamp import format_timestamp
from common.types import TimestampStatus

if TYPE_CHECKING:
    from common.state_backend import StateBackend

Direction = Literal["push", "pull"]


@dataclass
class _FileConflict:
    """Represents a file with timestamp conflicts."""

    filename: str
    local_timestamp: int
    remote_timestamp: int
    local_date: str
    remote_date: str
    time_diff: int
    time_diff_str: str

    def __str__(self) -> str:
        """Format conflict for display."""
        return f"{self.filename} - Local: {self.local_date}, Remote: {self.remote_date} ({self.time_diff_str})"


@dataclass
class TimestampCheckResult:
    """Result of timestamp checking."""

    will_replace: list[str]
    conflicts: list[_FileConflict]

    @property
    def has_conflicts(self) -> bool:
        """Check if there are any conflicts."""
        return len(self.conflicts) > 0

    @property
    def has_replacements(self) -> bool:
        """Check if any files will be replaced."""
        return len(self.will_replace) > 0


def check_file_timestamps(
    direction: Direction,
    backend: "StateBackend",
    local_path: str,
    files_being_copied: list[str],
) -> tuple[TimestampCheckResult, TimestampStatus]:
    """
    Check file timestamps and warn about conflicts.

    Args:
        direction: 'push' or 'pull'
        backend: The state backend used to read remote modification times
        local_path: Local directory path
        files_being_copied: List of files to check,
            When pulling, these should be the remote files
            When pushing, these should be the local files

    Returns:
        Tuple of (TimestampCheckResult, status)
        status: 'no_changes', 'will_replace', or 'has_conflicts'
    """
    will_replace = []
    conflicts = []

    for filename in files_being_copied:
        local_file = os.path.join(local_path, filename)
        local_mtime = _get_local_file_mtime(local_file)
        remote_mtime = backend.get_remote_mtime(filename)

        if direction == "pull":
            # Check if local file exists and will be replaced
            if os.path.exists(local_file):
                will_replace.append(filename)

                # Warn if remote is older than local
                if remote_mtime > 0 and local_mtime > 0 and remote_mtime < local_mtime:
                    time_diff = local_mtime - remote_mtime
                    conflicts.append(
                        _FileConflict(
                            filename=filename,
                            local_timestamp=local_mtime,
                            remote_timestamp=remote_mtime,
                            local_date=format_timestamp(local_mtime),
                            remote_date=format_timestamp(remote_mtime),
                            time_diff=time_diff,
                            time_diff_str=f"local is {format_time_diff(time_diff)} newer",
                        )
                    )
        else:  # push
            # Warn if local is older than remote
            if remote_mtime > 0 and local_mtime > 0 and local_mtime < remote_mtime:
                time_diff = remote_mtime - local_mtime
                conflicts.append(
                    _FileConflict(
                        filename=filename,
                        local_timestamp=local_mtime,
                        remote_timestamp=remote_mtime,
                        local_date=format_timestamp(local_mtime),
                        remote_date=format_timestamp(remote_mtime),
                        time_diff=time_diff,
                        time_diff_str=f"remote is {format_time_diff(time_diff)} newer",
                    )
                )

    result = TimestampCheckResult(will_replace=will_replace, conflicts=conflicts)

    # Show warnings
    if direction == "pull" and result.has_replacements:
        print()
        print(Colors.yellow("⚠️  The following local files will be replaced:"))
        for filename in will_replace:
            print(f"  - {filename}")

    if result.has_conflicts:
        print()
        print(Colors.yellow("⚠️  WARNING: Potential data loss detected!"))
        if direction == "pull":
            print("The following remote files are OLDER than your local files:")
        else:
            print("The following local files are OLDER than the remote files:")

        for conflict in conflicts:
            print(f"  {Colors.yellow('- ' + str(conflict))}")
        print()

    # Determine status
    if result.has_conflicts:
        return result, "has_conflicts"
    elif result.has_replacements:
        return result, "will_replace"
    else:
        return result, "no_changes"


def _get_local_file_mtime(filepath: str) -> int:
    """
    Get the modification time of a local file.

    Args:
        filepath: Path to the file

    Returns:
        Modification time in seconds since epoch, or 0 if file doesn't exist.
    """
    try:
        if os.path.exists(filepath):
            return int(os.path.getmtime(filepath))
        else:
            return 0
    except Exception:
        return 0
