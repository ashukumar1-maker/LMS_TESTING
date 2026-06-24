"""Abstract interface for a Terraform remote state backend."""

from abc import ABC, abstractmethod

from common.types import AccessType


class StateBackend(ABC):
    """
    Cloud-agnostic interface for syncing Terraform state files.

    Implementations wrap a specific cloud's remote object store (e.g. a GCS
    bucket or an Azure Blob Storage container) so that ``pushstate.py`` and
    ``pullstate.py`` can orchestrate uploads and downloads without knowing
    which cloud they are talking to.
    """

    @property
    @abstractmethod
    def location_label(self) -> str:
        """Human-readable location of the remote store, used for printing."""

    @abstractmethod
    def check_access(self, access_type: AccessType) -> None:
        """
        Verify the user can access the remote store.

        Args:
            access_type: Type of access needed ('read' or 'write').

        Raises:
            BucketAccessError: If the remote store cannot be accessed.
        """

    @abstractmethod
    def list_remote_files(self) -> None:
        """Print the files currently stored in the remote store."""

    @abstractmethod
    def remote_file_exists(self, filename: str) -> bool:
        """
        Return True if the file exists in the remote store.

        Raises:
            RuntimeError: If existence cannot be determined.
        """

    @abstractmethod
    def get_remote_mtime(self, filename: str) -> int:
        """
        Return the remote file's modification time in epoch seconds.

        Returns 0 if the file does not exist or the time cannot be read.
        """

    @abstractmethod
    def upload(self, filename: str, local_path: str) -> bool:
        """
        Upload a single file from ``local_path`` to the remote store.

        Returns:
            True if the upload succeeded, False otherwise.
        """

    @abstractmethod
    def download(self, filename: str, local_path: str) -> bool:
        """
        Download a single file from the remote store into ``local_path``.

        Returns:
            True if the download succeeded, False otherwise.
        """
