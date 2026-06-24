"""Custom exceptions for terraform state sync scripts."""


class TerraformSyncError(Exception):
    """Base exception for terraform state sync operations."""
    pass


class EnvironmentError(TerraformSyncError):
    """Raised when environment cannot be detected or is invalid."""
    pass


class ProjectConfigError(TerraformSyncError):
    """Raised when project configuration cannot be loaded."""
    pass


class AuthenticationError(TerraformSyncError):
    """Raised when gcloud authentication fails."""
    pass


class BucketAccessError(TerraformSyncError):
    """Raised when GCS bucket cannot be accessed."""
    pass


class FileOperationError(TerraformSyncError):
    """Raised when file operations fail."""
    pass


class ConfigurationError(TerraformSyncError):
    """Raised when configuration file cannot be loaded or is invalid."""
    pass