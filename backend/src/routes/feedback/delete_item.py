"""DELETE /feedback/{item_id} - Delete a feedback item."""

from __future__ import annotations

from typing import Annotated

from fastapi import Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.auth.verify_user import VerifyUserResponse, is_ciridae, verify_user
from src.db.feedback import get_feedback_item_by_id
from src.get_async_db import get_async_db
from src.routes.feedback.router import router


@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_feedback_item(
    item_id: str,
    current_user: Annotated[VerifyUserResponse, Depends(verify_user)],
    db: Annotated[AsyncSession, Depends(get_async_db)],
) -> None:
    """Delete a feedback item.

    Permission rules:
    - Customers can only delete their own items in the Backlog column
    - Ciridae users can delete any item

    Failure responses:
        `404 Not Found`: The requested feedback item does not exist.
        `403 Forbidden`: The caller is not allowed to delete the item, such as when the
        item belongs to another user or is not in the Backlog column.

    Args:
        item_id: The ID of the item to delete.
        current_user: The authenticated user.
        db: The database session.

    Raises:
        HTTPException: If the item is not found or the user lacks permission.
    """
    item = await get_feedback_item_by_id(db, item_id)

    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Feedback item not found",
        )

    user_email = current_user.email
    user_is_ciridae = is_ciridae(user_email)

    # Permission check for non-Ciridae users
    if not user_is_ciridae:
        if item.reporter_email != user_email:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only delete your own feedback items",
            )
        if item.column_id != "backlog":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only delete your own items in the Backlog",
            )

    await db.delete(item)
    await db.commit()
