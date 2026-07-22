"""Add Phase 1 training tables.

Revision ID: 9a1b7d65b84d
Revises: e0edc56e1ac4
Create Date: 2026-07-08 00:00:00.000000

"""

from __future__ import annotations

from typing import TYPE_CHECKING

import sqlalchemy as sa

from alembic import op

if TYPE_CHECKING:
    from collections.abc import Sequence


revision: str = "9a1b7d65b84d"
down_revision: str | None = "e0edc56e1ac4"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


TRAIT_FLOAT_COLUMNS = [
    "accountability",
    "ethical_propensity",
    "self_assurance",
    "stress_management",
    "learning_agility",
    "initiative_taking",
    "collaboration",
    "inclusion",
    "networking",
    "interpersonal_skills",
    "process_orientation",
    "result_orientation",
    "planning",
    "service_orientation",
    "quality_focus",
    "flexibility",
    "innovation",
]


def upgrade() -> None:
    """Upgrade schema."""
    _ = op.create_table(
        "employees",
        sa.Column("employee_id", sa.String(length=36), nullable=False),
        sa.Column("first_name", sa.String(length=255), nullable=False),
        sa.Column("last_name", sa.String(length=255), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("test_taker_id", sa.String(length=80), nullable=False),
        sa.Column("overall_status", sa.String(length=80), nullable=False),
        sa.Column("overall_score", sa.Float(), nullable=True),
        sa.Column("test_date", sa.String(length=80), nullable=False),
        sa.Column("gender", sa.String(length=80), nullable=False),
        sa.Column("date_of_birth", sa.String(length=80), nullable=False),
        sa.Column("contact_number", sa.String(length=120), nullable=False),
        sa.Column("is_valid", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint("employee_id"),
        sa.UniqueConstraint("email"),
    )
    op.create_index(op.f("ix_employees_email"), "employees", ["email"], unique=False)

    _ = op.create_table(
        "employee_sten_scores",
        sa.Column("employee_id", sa.String(length=36), nullable=False),
        *[sa.Column(column, sa.Float(), nullable=True) for column in TRAIT_FLOAT_COLUMNS],
        sa.Column("strengths_text", sa.Text(), nullable=False),
        sa.Column("areas_of_development_text", sa.Text(), nullable=False),
        sa.Column("response_style", sa.Text(), nullable=False),
        sa.Column("gaps_json", sa.Text(), nullable=False),
        sa.ForeignKeyConstraint(["employee_id"], ["employees.employee_id"]),
        sa.PrimaryKeyConstraint("employee_id"),
    )

    _ = op.create_table(
        "course_repository",
        sa.Column("course_id", sa.String(length=36), nullable=False),
        sa.Column("course_name", sa.String(length=500), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("department", sa.String(length=255), nullable=False),
        sa.Column("role_type", sa.String(length=255), nullable=False),
        sa.Column("level_1", sa.Boolean(), nullable=False),
        sa.Column("level_2", sa.Boolean(), nullable=False),
        sa.Column("level_3", sa.Boolean(), nullable=False),
        sa.Column("content_format", sa.String(length=255), nullable=False),
        sa.Column("is_lms_module", sa.Boolean(), nullable=False),
        sa.Column("training_duration_minutes", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        *[sa.Column(column, sa.Boolean(), nullable=False) for column in TRAIT_FLOAT_COLUMNS],
        sa.PrimaryKeyConstraint("course_id"),
    )

    _ = op.create_table(
        "tna_form_submissions",
        sa.Column("submission_id", sa.String(length=36), nullable=False),
        sa.Column("employee_email", sa.String(length=255), nullable=False),
        sa.Column("employee_name", sa.String(length=500), nullable=False),
        sa.Column("department", sa.String(length=255), nullable=False),
        sa.Column("team", sa.String(length=255), nullable=False),
        sa.Column("employee_role", sa.String(length=255), nullable=False),
        sa.Column("supervisor_name", sa.String(length=255), nullable=False),
        sa.Column("assessment_period", sa.String(length=255), nullable=False),
        sa.Column("gap_description", sa.Text(), nullable=False),
        sa.Column("business_impact", sa.Text(), nullable=False),
        sa.Column("capabilities_required", sa.Text(), nullable=False),
        sa.Column("expected_training_outcome", sa.Text(), nullable=False),
        sa.Column("additional_comments", sa.Text(), nullable=False),
        sa.Column("hr_id_entered", sa.String(length=80), nullable=False),
        sa.Column("is_verified", sa.Boolean(), nullable=False),
        sa.Column("submitted_at", sa.DateTime(), nullable=False),
        sa.Column("ai_processed", sa.Boolean(), nullable=False),
        sa.Column("extracted_traits", sa.Text(), nullable=True),
        sa.Column("extracted_keywords", sa.Text(), nullable=True),
        sa.Column("extracted_priority", sa.String(length=80), nullable=True),
        sa.Column("extracted_business_impact", sa.Text(), nullable=True),
        sa.PrimaryKeyConstraint("submission_id"),
    )
    op.create_index(
        op.f("ix_tna_form_submissions_employee_email"),
        "tna_form_submissions",
        ["employee_email"],
        unique=False,
    )

    _ = op.create_table(
        "recommendations",
        sa.Column("recommendation_id", sa.String(length=36), nullable=False),
        sa.Column("employee_email", sa.String(length=255), nullable=False),
        sa.Column("course_id", sa.String(length=36), nullable=False),
        sa.Column("recommendation_source", sa.String(length=20), nullable=False),
        sa.Column("matched_traits", sa.Text(), nullable=False),
        sa.Column("recommendation_rank", sa.Integer(), nullable=False),
        sa.Column("is_mandatory", sa.Boolean(), nullable=False),
        sa.Column("generated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["course_id"], ["course_repository.course_id"]),
        sa.PrimaryKeyConstraint("recommendation_id"),
    )
    op.create_index(
        op.f("ix_recommendations_employee_email"),
        "recommendations",
        ["employee_email"],
        unique=False,
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f("ix_recommendations_employee_email"), table_name="recommendations")
    op.drop_table("recommendations")
    op.drop_index(
        op.f("ix_tna_form_submissions_employee_email"),
        table_name="tna_form_submissions",
    )
    op.drop_table("tna_form_submissions")
    op.drop_table("course_repository")
    op.drop_table("employee_sten_scores")
    op.drop_index(op.f("ix_employees_email"), table_name="employees")
    op.drop_table("employees")
