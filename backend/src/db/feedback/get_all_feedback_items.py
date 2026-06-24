"""Query to get all feedback items."""

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.models import FeedbackItem


async def get_all_feedback_items(db: AsyncSession) -> list[FeedbackItem]:
    """Get all feedback items sorted by column and priority.

    Args:
        db: The database session.

    Returns:
        List of feedback items.
    """
    result = await db.execute(
        select(FeedbackItem).order_by(
            FeedbackItem.column_id, FeedbackItem.priority_index
        )
    )
    return list(result.scalars().all())
