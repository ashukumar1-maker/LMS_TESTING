"""Type definitions for terraform state sync scripts."""

from typing import Literal, TypedDict


class ProjectIds(TypedDict):
    """Project IDs extracted from terraform.auto.tfvars."""

    project_id: str
    gcp_project_id: str


class AzureConfig(TypedDict):
    """Azure configuration extracted from the environment tfvars file."""

    project_id: str
    azure_subscription_id: str


class SyncConfig(TypedDict):
    """Configuration for files to sync."""

    files: list[str]


Cloud = Literal["gcp", "azure"]
AccessType = Literal["read", "write"]
TimestampStatus = Literal["no_changes", "will_replace", "has_conflicts"]
