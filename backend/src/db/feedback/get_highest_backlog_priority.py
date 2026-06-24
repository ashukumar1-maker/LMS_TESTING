"""Query to get the highest backlog priority."""

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.models import FeedbackItem


async def get_highest_backlog_priority(db: AsyncSession) -> float | None:
    """Get the highest priority_index in the backlog column.

    Args:
        db: The database session.

    Returns:
        The highest priority index, or None if backlog is empty.
    """
    result = await db.execute(
        select(FeedbackItem.priority_index)
        .where(FeedbackItem.column_id == "backlog")
        .order_by(FeedbackItem.priority_index.desc())
        .limit(1)
    )
    return result.scalar()
