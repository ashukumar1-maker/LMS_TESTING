"""Feedback API module."""

from __future__ import annotations

# Import handlers to register routes via decorators
from src.routes.feedback import (
    create_item,
    delete_item,
    list_items,
    update_item,
)
from src.routes.feedback.router import router

__all__ = ["create_item", "delete_item", "list_items", "router", "update_item"]
