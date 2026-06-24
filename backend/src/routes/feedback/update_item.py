"""PATCH /feedback/{item_id} - Update a feedback item."""

from __future__ import annotations

from typing import Annotated

from fastapi import Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.auth.verify_user import VerifyUserResponse, is_ciridae, verify_user
from src.db.feedback import get_feedback_item_by_id
from src.get_async_db import get_async_db
from src.models import ColumnId, FeedbackItem
from src.routes.feedback.constants import (
    BACKLOG_STATUSES,
    COLUMN_TO_STATUS,
    COLUMN_VALID_STATUSES,
)
from src.routes.feedback.router import router
from src.routes.feedback.schemas import (
    FeedbackItemResponse,
    FeedbackItemUpdate,
    db_feedback_item_to_response,
)


def _validate_customer_permissions(
    *,
    item_column_id: ColumnId,
    reporter_email: str,
    user_email: str,
    update: FeedbackItemUpdate,
) -> None:
    """Validate update permissions for non-Ciridae users.

    Args:
        item_column_id: The current column ID for the feedback item.
        reporter_email: The email address of the feedback item's reporter.
        user_email: The email address of the authenticated user.
        update: The requested feedback item changes.

    Raises:
        HTTPException: If a non-Ciridae user tries to make a forbidden update.
    """
    if item_column_id != "backlog":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only update items in the Backlog",
        )

    if update.columnId is not None and update.columnId != item_column_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only Ciridae users can move items between columns",
        )

    is_editing_content = update.title is not None or update.description is not None
    is_own_item = reporter_email == user_email
    if not is_own_item and is_editing_content:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only edit your own feedback items",
        )


def _validate_status_update(
    *,
    update: FeedbackItemUpdate,
    item_column_id: ColumnId,
    user_is_ciridae: bool,
) -> None:
    """Validate a status change request against permissions and column rules.

    Args:
        update: The requested feedback item changes.
        item_column_id: The current column ID for the feedback item.
        user_is_ciridae: Whether the authenticated user has Ciridae access.

    Raises:
        HTTPException: If the user cannot change status or the status is invalid.
    """
    if update.status is None:
        return

    if not user_is_ciridae:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only Ciridae users can change item status",
        )

    target_column: ColumnId = update.columnId or item_column_id
    valid_statuses = COLUMN_VALID_STATUSES.get(target_column, set())
    if update.status not in valid_statuses:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Column '{target_column}' requires status: {', '.join(sorted(valid_statuses))}",
        )


def _apply_updates(update: FeedbackItemUpdate, item: FeedbackItem) -> None:
    """Apply validated update fields to a feedback item model.

    Args:
        update: The requested feedback item changes.
        item: The feedback item model being updated.
    """
    if update.columnId is not None and update.columnId != item.column_id:
        item.column_id = update.columnId
        if update.columnId in COLUMN_TO_STATUS:
            item.status = COLUMN_TO_STATUS[update.columnId]
        elif update.columnId == "backlog" and item.status not in BACKLOG_STATUSES:
            item.status = "in_review"

    if update.status is not None:
        item.status = update.status
    if update.priorityIndex is not None:
        item.priority_index = update.priorityIndex
    if update.title is not None:
        item.title = update.title
    if update.description is not None:
        item.description = update.description


@router.patch("/{item_id}")
async def update_feedback_item(
    item_id: str,
    update: FeedbackItemUpdate,
    current_user: Annotated[VerifyUserResponse, Depends(verify_user)],
    db: Annotated[AsyncSession, Depends(get_async_db)],
) -> FeedbackItemResponse:
    """Update an existing feedback item.

    Permission rules:
    - Customers can only update their own items in the Backlog column
    - Customers cannot change the column_id
    - Ciridae users can update any item including column changes

    Failure responses:
        `404 Not Found`: The requested feedback item does not exist.
        `403 Forbidden`: The caller is not allowed to update the item, move it between
        columns, edit another user's item, or change status without Ciridae access.
        `400 Bad Request`: The provided status is invalid for the target column.

    Args:
        item_id: The ID of the item to update.
        update: The update data.
        current_user: The authenticated user.
        db: The database session.

    Returns:
        The updated feedback item.

    Raises:
        HTTPException: If the item is not found, invalid, or the user lacks permission.
    """
    item = await get_feedback_item_by_id(db, item_id)

    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Feedback item not found",
        )

    user_email = current_user.email
    user_is_ciridae = is_ciridae(user_email)

    if not user_is_ciridae:
        _validate_customer_permissions(
            item_column_id=item.column_id,
            reporter_email=item.reporter_email,
            user_email=user_email,
            update=update,
        )

    _validate_status_update(
        update=update,
        item_column_id=item.column_id,
        user_is_ciridae=user_is_ciridae,
    )
    _apply_updates(update=update, item=item)

    await db.commit()
    await db.refresh(item)

    return db_feedback_item_to_response(item)
