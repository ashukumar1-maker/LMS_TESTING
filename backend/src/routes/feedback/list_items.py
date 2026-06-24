"""GET /feedback - List all feedback items."""

from __future__ import annotations

from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.db.feedback import get_all_feedback_items
from src.get_async_db import get_async_db
from src.routes.feedback.router import router
from src.routes.feedback.schemas import (
    FeedbackItemResponse,
    db_feedback_item_to_response,
)


@router.get("")
async def list_feedback_items(
    db: Annotated[AsyncSession, Depends(get_async_db)],
) -> list[FeedbackItemResponse]:
    """List all feedback items sorted by column and priority.

    Requires authentication but all authenticated users can view all items.

    Args:
        db: The database session.

    Returns:
        A list of all feedback items.
    """
    items = await get_all_feedback_items(db)

    return [db_feedback_item_to_response(item) for item in items]
