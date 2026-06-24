"""SQLAlchemy ORM models and shared model type aliases."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Literal
from uuid import uuid4

from sqlalchemy import DateTime, Float, String, Text
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

# Type definitions for feedback items
ColumnId = Literal["backlog", "inProgress", "done"]
Status = Literal["in_review", "triaged", "in_progress", "done"]


def _current_utc_timestamp() -> datetime:
    """Returns the current UTC timestamp without timezone metadata.

    Returns:
        The current UTC timestamp as a naive `datetime` value.
    """
    return datetime.now(UTC).replace(tzinfo=None)


class Base(DeclarativeBase):
    """Base class for all SQLAlchemy ORM models."""


class FeedbackItem(Base):
    """Feedback item for the Kanban board.

    Represents a customer feedback ticket that can be in one of three columns:
    - backlog: Customer-created items awaiting triage
    - inProgress: Items currently being worked on
    - done: Completed items

    Status values:
    - in_review: New item in backlog, awaiting triage
    - triaged: Item reviewed and ready for work (backlog only)
    - in_progress: Item being actively worked on
    - done: Item completed
    """

    __tablename__: str = "feedback_items"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid4())
    )
    column_id: Mapped[ColumnId] = mapped_column(String(20), default="backlog")
    status: Mapped[Status] = mapped_column(String(20), default="in_review")
    priority_index: Mapped[float] = mapped_column(Float, default=0.0)
    title: Mapped[str] = mapped_column(String(255))
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    reporter_email: Mapped[str] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=_current_utc_timestamp
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=_current_utc_timestamp,
        onupdate=_current_utc_timestamp,
    )

    # App identifier (from frontend APPS config)
    app_id: Mapped[str | None] = mapped_column(String(50), nullable=True)
