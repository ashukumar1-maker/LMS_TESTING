"""Query to create a new feedback item."""

from sqlalchemy.ext.asyncio import AsyncSession

from src.models import FeedbackItem


async def create_feedback_item(
    db: AsyncSession,
    title: str,
    description: str | None,
    reporter_email: str,
    priority_index: float,
    app_id: str | None,
) -> FeedbackItem:
    """Create a new feedback item in the database.

    Args:
        db: The database session.
        title: The title of the feedback item.
        description: The description of the feedback item.
        reporter_email: The email of the user creating the item.
        priority_index: The priority index for ordering in the backlog.
        app_id: Optional app ID to associate the feedback with.

    Returns:
        The created feedback item.
    """
    feedback_item = FeedbackItem(
        title=title,
        description=description,
        reporter_email=reporter_email,
        column_id="backlog",
        status="in_review",
        priority_index=priority_index,
        app_id=app_id,
    )
    db.add(feedback_item)
    await db.commit()
    await db.refresh(feedback_item)
    return feedback_item
