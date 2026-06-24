"""Example authenticated API route."""

from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from src.auth.verify_user import VerifyUserResponse, verify_user

router = APIRouter()


class ExampleResponse(BaseModel):
    """Response payload for the example route."""

    message: str


@router.get("/example")
async def example_route_handler(
    current_user: Annotated[VerifyUserResponse, Depends(verify_user)],
) -> ExampleResponse:
    """An example route that uses the verify_user dependency (formerly verify_token).

    It receives the user_id from the dependency but returns a fixed message.

    Returns:
        A simple example response payload.
    """
    print(f"Authenticated user ID: {current_user.uid}")
    return ExampleResponse(message="example")
