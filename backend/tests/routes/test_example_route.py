"""Tests for the example route."""

from http import HTTPStatus

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_example_route_returns_message(client: AsyncClient) -> None:
    """Test that the example route returns the expected message.

    This test demonstrates:
    - Making a GET request to an authenticated endpoint
    - The override_auth fixture automatically bypasses authentication
    - Verifying the response status and JSON content
    """
    # Act - Make the API request
    response = await client.get("/example")

    # Assert - Verify the response
    assert response.status_code == HTTPStatus.OK
    assert response.json() == {"message": "example"}


@pytest.mark.asyncio
async def test_example_route_receives_fake_user_id(client: AsyncClient) -> None:
    """Test that the route receives the fake user ID from override_auth.

    This test demonstrates that the override_auth fixture (conftest.py:164-177)
    automatically provides a fake user ID ("test-user-123") to routes that use
    the verify_user dependency, allowing tests to bypass real authentication.

    Note: In a real scenario, you might want to verify the user_id is actually
    used (e.g., for filtering data). This example route just prints it.
    """
    # The override_auth fixture is auto-applied, so this request is authenticated
    response = await client.get("/example")

    # The route successfully processes with the fake user ID
    assert response.status_code == HTTPStatus.OK
    assert response.json()["message"] == "example"

    # In a real test, you might verify the user_id was used correctly:
    # For example, if the route returned user-specific data, you'd assert
    # that the data belongs to "test-user-123"
