"""Pydantic schemas for the Feedback API."""

from __future__ import annotations

from datetime import (
    datetime,  # noqa: TC003 - Pydantic resolves this annotation at runtime.
)

from pydantic import BaseModel

from src.models import ColumnId, FeedbackItem, Status


class FeedbackItemCreate(BaseModel):
    """Schema for creating a new feedback item."""

    title: str
    description: str | None = None
    appId: str | None = None


class FeedbackItemUpdate(BaseModel):
    """Schema for updating an existing feedback item."""

    columnId: ColumnId | None = None
    priorityIndex: float | None = None
    title: str | None = None
    description: str | None = None
    status: Status | None = None


class FeedbackItemResponse(BaseModel):
    """Schema for feedback item responses."""

    id: str
    columnId: ColumnId
    status: Status
    priorityIndex: float
    title: str
    description: str | None
    reporterEmail: str
    createdAt: datetime
    updatedAt: datetime
    appId: str | None = None


def db_feedback_item_to_response(item: FeedbackItem) -> FeedbackItemResponse:
    """Serialize a feedback item to a response schema.

    Args:
        item: The feedback item to serialize.

    Returns:
        Serialized feedback item response.
    """
    return FeedbackItemResponse(
        id=item.id,
        columnId=item.column_id,
        status=item.status,
        priorityIndex=item.priority_index,
        title=item.title,
        description=item.description,
        reporterEmail=item.reporter_email,
        createdAt=item.created_at,
        updatedAt=item.updated_at,
        appId=item.app_id,
    )
