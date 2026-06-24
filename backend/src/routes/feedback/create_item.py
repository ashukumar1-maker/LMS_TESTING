"""POST /feedback - Create a new feedback item."""

from __future__ import annotations

from typing import Annotated

from fastapi import Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.auth.verify_user import VerifyUserResponse, verify_user
from src.db.feedback import create_feedback_item as create_feedback_item_in_db
from src.db.feedback import get_highest_backlog_priority
from src.get_async_db import get_async_db
from src.routes.feedback.router import router
from src.routes.feedback.schemas import (
    FeedbackItemCreate,
    FeedbackItemResponse,
    db_feedback_item_to_response,
)


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
)
async def create_feedback_item(
    item: FeedbackItemCreate,
    current_user: Annotated[VerifyUserResponse, Depends(verify_user)],
    db: Annotated[AsyncSession, Depends(get_async_db)],
) -> FeedbackItemResponse:
    """Create a new feedback item.

    The item is created in the Backlog column with the reporter_email
    automatically set from the authenticated user.

    Args:
        item: The feedback item data.
        current_user: The authenticated user.
        db: The database session.

    Returns:
        The created feedback item.
    """
    highest_priority = await get_highest_backlog_priority(db)
    new_priority = (highest_priority or 0.0) + 1.0

    feedback_item = await create_feedback_item_in_db(
        db=db,
        title=item.title,
        description=item.description,
        reporter_email=current_user.email,
        priority_index=new_priority,
        app_id=item.appId,
    )

    return db_feedback_item_to_response(feedback_item)
