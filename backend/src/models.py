"""SQLAlchemy ORM models and shared model type aliases."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Literal
from uuid import uuid4

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text
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


class Employee(Base):
    """Employee identity and Mettl assessment metadata."""

    __tablename__: str = "employees"

    employee_id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid4())
    )
    first_name: Mapped[str] = mapped_column(String(255), default="")
    last_name: Mapped[str] = mapped_column(String(255), default="")
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    test_taker_id: Mapped[str] = mapped_column(String(80), default="")
    overall_status: Mapped[str] = mapped_column(String(80), default="")
    overall_score: Mapped[float | None] = mapped_column(Float, nullable=True)
    test_date: Mapped[str] = mapped_column(String(80), default="")
    gender: Mapped[str] = mapped_column(String(80), default="")
    date_of_birth: Mapped[str] = mapped_column(String(80), default="")
    contact_number: Mapped[str] = mapped_column(String(120), default="")
    is_valid: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=_current_utc_timestamp
    )


class EmployeeStenScore(Base):
    """The 17 Mettl STEN scores and derived gap data for an employee."""

    __tablename__: str = "employee_sten_scores"

    employee_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("employees.employee_id"), primary_key=True
    )
    accountability: Mapped[float | None] = mapped_column(Float, nullable=True)
    ethical_propensity: Mapped[float | None] = mapped_column(Float, nullable=True)
    self_assurance: Mapped[float | None] = mapped_column(Float, nullable=True)
    stress_management: Mapped[float | None] = mapped_column(Float, nullable=True)
    learning_agility: Mapped[float | None] = mapped_column(Float, nullable=True)
    initiative_taking: Mapped[float | None] = mapped_column(Float, nullable=True)
    collaboration: Mapped[float | None] = mapped_column(Float, nullable=True)
    inclusion: Mapped[float | None] = mapped_column(Float, nullable=True)
    networking: Mapped[float | None] = mapped_column(Float, nullable=True)
    interpersonal_skills: Mapped[float | None] = mapped_column(Float, nullable=True)
    process_orientation: Mapped[float | None] = mapped_column(Float, nullable=True)
    result_orientation: Mapped[float | None] = mapped_column(Float, nullable=True)
    planning: Mapped[float | None] = mapped_column(Float, nullable=True)
    service_orientation: Mapped[float | None] = mapped_column(Float, nullable=True)
    quality_focus: Mapped[float | None] = mapped_column(Float, nullable=True)
    flexibility: Mapped[float | None] = mapped_column(Float, nullable=True)
    innovation: Mapped[float | None] = mapped_column(Float, nullable=True)
    strengths_text: Mapped[str] = mapped_column(Text, default="")
    areas_of_development_text: Mapped[str] = mapped_column(Text, default="")
    response_style: Mapped[str] = mapped_column(Text, default="")
    gaps_json: Mapped[str] = mapped_column(Text, default="[]")


class CourseRepositoryItem(Base):
    """Learning content repository course with primary/secondary skill tags."""

    __tablename__: str = "course_repository"

    course_id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid4())
    )
    course_name: Mapped[str] = mapped_column(String(500))
    description: Mapped[str] = mapped_column(Text, default="")
    department: Mapped[str] = mapped_column(String(255), default="")
    role_type: Mapped[str] = mapped_column(String(255), default="")
    level_1: Mapped[bool] = mapped_column(Boolean, default=False)
    level_2: Mapped[bool] = mapped_column(Boolean, default=False)
    level_3: Mapped[bool] = mapped_column(Boolean, default=False)
    content_format: Mapped[str] = mapped_column(String(255), default="")
    is_lms_module: Mapped[bool] = mapped_column(Boolean, default=False)
    training_duration_minutes: Mapped[int | None] = mapped_column(Integer, nullable=True)
    primary_skill: Mapped[str] = mapped_column(String(255), default="")
    secondary_skill: Mapped[str] = mapped_column(String(255), default="")
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=_current_utc_timestamp
    )


class TnaFormSubmission(Base):
    """Raw Training Needs Assessment form submission."""

    __tablename__: str = "tna_form_submissions"

    submission_id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid4())
    )
    employee_email: Mapped[str] = mapped_column(String(255), index=True)
    provana_email: Mapped[str] = mapped_column(String(255), default="")
    employee_name: Mapped[str] = mapped_column(String(500), default="")
    employee_id_entered: Mapped[str] = mapped_column(String(80), default="")
    department: Mapped[str] = mapped_column(String(255), default="")
    team: Mapped[str] = mapped_column(String(255), default="")
    employee_role: Mapped[str] = mapped_column(String(255), default="")
    supervisor_name: Mapped[str] = mapped_column(String(255), default="")
    assessment_period: Mapped[str] = mapped_column(String(255), default="")
    gap_description: Mapped[str] = mapped_column(Text)
    business_impact: Mapped[str] = mapped_column(Text)
    capabilities_required: Mapped[str] = mapped_column(Text)
    expected_training_outcome: Mapped[str] = mapped_column(Text)
    additional_comments: Mapped[str] = mapped_column(Text, default="")
    hr_id_entered: Mapped[str] = mapped_column(String(80))
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    submitted_at: Mapped[datetime] = mapped_column(
        DateTime, default=_current_utc_timestamp
    )
    ai_processed: Mapped[bool] = mapped_column(Boolean, default=False)
    extracted_traits: Mapped[str | None] = mapped_column(Text, nullable=True)
    extracted_skills: Mapped[str | None] = mapped_column(Text, nullable=True)
    unmapped_skills: Mapped[str | None] = mapped_column(Text, nullable=True)
    extracted_keywords: Mapped[str | None] = mapped_column(Text, nullable=True)
    extracted_priority: Mapped[str | None] = mapped_column(String(80), nullable=True)
    extracted_business_impact: Mapped[str | None] = mapped_column(Text, nullable=True)


class Recommendation(Base):
    """Course recommendation generated by the matching engine."""

    __tablename__: str = "recommendations"

    recommendation_id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid4())
    )
    employee_email: Mapped[str] = mapped_column(String(255), index=True)
    course_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("course_repository.course_id")
    )
    recommendation_source: Mapped[str] = mapped_column(String(20), default="tna")
    matched_skills: Mapped[str] = mapped_column(Text, default="[]")
    matched_traits: Mapped[str] = mapped_column(Text, default="[]")
    recommendation_rank: Mapped[int] = mapped_column(Integer, default=0)
    is_mandatory: Mapped[bool] = mapped_column(Boolean, default=False)
    generated_at: Mapped[datetime] = mapped_column(
        DateTime, default=_current_utc_timestamp
    )
