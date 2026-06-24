"""Feedback Kanban Board API Router.

Provides CRUD operations for feedback items in a 3-column Kanban board:
- backlog: Customer-created items awaiting triage
- inProgress: Items currently being worked on
- done: Completed items

Permission model:
- Customers can create/update/delete their own items in Backlog
- Ciridae users (@ciridae.com) have full control over all items
"""

from fastapi import APIRouter, Depends

from src.auth.verify_user import verify_user

router = APIRouter(
    prefix="/feedback", tags=["feedback"], dependencies=[Depends(verify_user)]
)
