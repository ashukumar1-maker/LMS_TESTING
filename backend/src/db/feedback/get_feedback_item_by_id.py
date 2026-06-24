"""Query to get a feedback item by ID."""

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.models import FeedbackItem


async def get_feedback_item_by_id(
    db: AsyncSession, item_id: str
) -> FeedbackItem | None:
    """Get a feedback item by its ID.

    Args:
        db: The database session.
        item_id: The ID of the feedback item.

    Returns:
        The feedback item, or None if not found.
    """
    result = await db.execute(select(FeedbackItem).where(FeedbackItem.id == item_id))
    return result.scalar_one_or_none()
