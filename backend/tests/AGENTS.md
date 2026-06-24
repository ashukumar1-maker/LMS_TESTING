# Backend Testing Guide

## Quick Start

Here's all you need to run tests:

```bash
# 1. Navigate to the backend directory
cd backend

# 2. Run the tests
uv run pytest
```

If you need to run the tests outside of the backend container of the docker compose, you can use the following commands:
```bash
docker compose up -d

docker compose exec backend uv run pytest
```

The test infrastructure automatically:
- Creates the test database if it doesn't exist
- Runs all necessary migrations
- Sets up test fixtures
- Cleans up after each test

## What to Test (and What Not To)

A test is a liability like any other code — each one must earn its place. The bar here is strict:

- **Test behavior, not implementation.** Assert on observable outcomes (status codes, response shapes, persisted rows), never on *which* internal functions were called. A test built mostly of mocks that asserts `mock_session.execute.assert_called_once()` is testing implementation details — it locks in the current code shape and breaks on every refactor. Prefer a route/integration test that exercises the real path.
- **Don't test trivial functions.** A test for a one-line formatter, a pure pass-through, or a simple internal interface adds noise, not safety. If it's obviously correct at a glance, don't test it.
- **A test must not be more complex than the code it covers.** If the setup needs more machinery than the function itself, the test is wrong — either the code needs a cleaner seam, or the test isn't worth writing.
- **Prefer integration tests over heavily-mocked unit tests** for anything touching the DB or HTTP. Reach for `tests/routes/` (a real DB transaction, rolled back per test) before mocking a session; mock only genuinely external, slow, or non-deterministic dependencies.

> The mocked `tests/unit/` example further down illustrates the *fixture mechanics* of overriding a session — it is **not** a model test to copy. For DB-backed logic, write a route/integration test instead of asserting on mock calls.

## Test Directory Structure

```
backend/tests/
├── fixtures/                # Test fixtures
├── routes/                  # Integration tests (full API → DB cycle)
│   │── test_example_route.py
│   └── test_health_check.py
│── unit/                    # Unit tests (isolated, mocked dependencies)
└── conftest.py              # pytest conftest
```

### Integration Tests vs Unit Tests

This codebase distinguishes between two types of tests:

| Aspect | Integration Tests (`routes/`) | Unit Tests (`unit/`) |
|--------|------------------------------|----------------------|
| **Purpose** | Test full request/response cycle | Test isolated functions/classes |
| **Scope** | HTTP → FastAPI → DB → Response | Single function with mocked deps |
| **Fixtures needed** | `client`, `db_session`, overrides | Standard pytest, mocks |
| **Speed** | Slower (real DB transactions) | Fast (no I/O) |
| **Test functions** | `async def` with `@pytest.mark.asyncio` | Can be sync `def` |

### When to Use Each

**Use Integration Tests (`routes/`)** when testing:
- API endpoint behavior (status codes, response shapes)
- Request validation (Pydantic models, 422 errors)
- Authentication/authorization flows
- Database operations through the API
- Full request lifecycle

**Use Unit Tests (`unit/`)** when testing:
- Pure business logic functions (validators, calculators, formatters)
- Service layer functions with mocked database
- Utility functions
- Edge cases in isolated logic
- Functions that don't need HTTP or real database

### Unit Test Examples

Unit tests don't need the integration fixtures. They use standard pytest with mocks:

```python
# tests/unit/test_validators.py
def test_calculate_discount():
    """Pure function - no async, no DB, no client needed."""
    from src.utils import calculate_discount

    assert calculate_discount(100, 10) == 90.0
    assert calculate_discount(50, 50) == 25.0
```

```python
# tests/unit/test_services.py
from unittest.mock import AsyncMock
import pytest

@pytest.mark.asyncio
async def test_get_user_by_email():
    """Service function with mocked database session."""
    from src.services.users import get_user_by_email
    from src.models import User

    # Create a mock session
    mock_session = AsyncMock()
    mock_session.execute.return_value.scalar_one_or_none.return_value = User(
        id="123", email="test@example.com"
    )

    # Test the function with mocked dependency
    result = await get_user_by_email(mock_session, "test@example.com")

    assert result.id == "123"
    assert result.email == "test@example.com"
    mock_session.execute.assert_called_once()
```

### Running Tests by Type

```bash
# Run only integration tests
uv run pytest tests/routes/

# Run only unit tests
uv run pytest tests/unit/

# Run a specific test file
uv run pytest tests/unit/test_validators.py
```

## Running Tests

```bash
# Run all tests in a specific (hypothetical) file
uv run pytest tests/test_cases.py

# Run a specific (hypothetical) test
uv run pytest tests/test_cases.py::test_create_case_with_defaults

# Run tests stopping after the first failure
uv run pytest -x

# Run with verbose output
uv run pytest -v

# Run with output from print statements
uv run pytest -v -s
```

---

## Integration Test Infrastructure

The integration test setup in `conftest.py` and `tests/fixtures/` provides full API-to-Database testing with automatic isolation.

> **Note:** Unit tests in `tests/unit/` do not use these fixtures; they use standard pytest with mocks.

### Architecture Overview

Tests run in a transaction that is rolled back after completion, ensuring a clean state for every test. The infrastructure handles database creation, schema migration, and dependency overriding automatically.

### Key Components

1.  **Test Database (`tests/fixtures/postgres_container.py`)**
    -   Connects to a separate `fullstack_test` database to avoid touching development data.
    -   **Docker Compose Optimization:** If Docker Compose is running, tests use the existing `db` container (via localhost) for performance but connect to the isolated `fullstack_test` database.
    -   **In-Container Testing:** When running tests inside the backend container, they also use the Docker Compose `db` container but maintain isolation via the `fullstack_test` database.
    -   Automatically creates the database if it doesn't exist.
    -   **Clears the database** (drops/recreates public schema) before the session to ensure a fresh start.

2.  **Schema Migrations (`tests/fixtures/migrate_test_db.py`)**
    -   Runs Alembic migrations once per session to match the production schema.

3.  **Transaction Isolation (`tests/fixtures/db_session.py`)**
    -   Wraps each test in a database transaction.
    -   Rolls back the transaction after the test, discarding any changes.

4.  **Dependency Overrides (`tests/fixtures/override_get_async_db.py`, `tests/fixtures/override_auth.py`)**
    -   Redirects API database calls to the test transaction.
    -   Bypasses authentication, providing a fake user identity.

5.  **Direct Session Mocking (`tests/fixtures/override_async_session_local.py`)**
    -   Intercepts direct `AsyncSessionLocal()` calls in service code.
    -   Forces them to use the test transaction so they are also rolled back.

6.  **HTTP Client (`tests/fixtures/client.py`)**
    -   Provides an async `httpx` client for making in-memory requests to the FastAPI app.

## Writing Tests

### Basic Test Structure

```python
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_my_endpoint(client: AsyncClient):
    """Test description following Google-style docstrings."""
    # Arrange - Set up test data
    request_data = {"field": "value"}

    # Act - Make the API request
    response = await client.post("/endpoint", json=request_data)

    # Assert - Verify the response
    assert response.status_code == 201
    assert response.json()["field"] == "value"
```

### Available Fixtures

All fixtures are automatically available in test functions:

- **`client`**: Async HTTP client for API requests
- **`db_session`**: Direct database session (if you need to query/setup data)
- **`override_db`**: Auto-applied, ensures tests use test database
- **`override_auth`**: Auto-applied, bypasses authentication

### Testing CRUD Operations

Example from `test_cases.py`:

```python
@pytest.mark.asyncio
async def test_case_crud(client: AsyncClient):
    # Create
    response = await client.post("/cases", json={"title": "Test Case"})
    assert response.status_code == 201
    case_id = response.json()["id"]

    # Read
    response = await client.get(f"/cases/{case_id}")
    assert response.status_code == 200
    assert response.json()["title"] == "Test Case"

    # Update
    response = await client.patch(f"/cases/{case_id}", json={"title": "Updated"})
    assert response.status_code == 200
    assert response.json()["title"] == "Updated"

    # Delete
    response = await client.delete(f"/cases/{case_id}")
    assert response.status_code == 204

    # Verify deletion
    response = await client.get(f"/cases/{case_id}")
    assert response.status_code == 404
```

### Testing Validation Errors

```python
@pytest.mark.asyncio
async def test_invalid_input(client: AsyncClient):
    """Test that invalid input returns 422 validation error."""
    response = await client.post("/cases", json={"title": ""})
    assert response.status_code == 422
```

### Using Database Session Directly

If you need to set up test data or verify database state:

```python
@pytest.mark.asyncio
async def test_with_db_access(client: AsyncClient, db_session: AsyncSession):
    """Test with direct database access."""
    from sqlalchemy import select
    from src.models import Case

    # Query database directly
    result = await db_session.execute(select(Case))
    cases = result.scalars().all()

    assert len(cases) == 0  # Clean state

    # Make API request
    response = await client.post("/cases", json={"title": "Test"})
    assert response.status_code == 201

    # Verify in database
    result = await db_session.execute(select(Case))
    cases = result.scalars().all()
    assert len(cases) == 1
```

### Testing Functions That Use AsyncSessionLocal Directly

Some functions may create database sessions directly rather than using the `get_async_db` dependency. For example, service layer functions that need database access:

```python
from src.get_async_db import AsyncSessionLocal
from sqlalchemy import select

async def get_user_count() -> int:
    """Service function that creates its own database session."""
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(func.count(User.id)))
        return result.scalar_one()
```

**The good news:** The `mock_async_session_local` fixture (auto-applied) handles this automatically! Your tests work seamlessly:

```python
@pytest.mark.asyncio
async def test_service_function_with_direct_session(client: AsyncClient):
    """Test function that uses AsyncSessionLocal directly."""
    # The mock_async_session_local fixture is auto-applied
    # No special setup needed!

    # Initially no users
    count = await get_user_count()
    assert count == 0

    # Create a user via API
    await client.post("/users", json={"name": "Test User"})

    # Service function sees the same test data
    count = await get_user_count()
    assert count == 1

    # All operations are rolled back after the test
```

**How it works:**
1. The fixture monkeypatches `AsyncSessionLocal` in `src.get_async_db`
2. When code calls `AsyncSessionLocal()`, it returns the test session
3. All database operations happen within the test transaction
4. Everything is rolled back automatically after the test

**Key differences between fixtures:**
- **`override_db`**: Handles FastAPI routes using `Depends(get_async_db)`
- **`mock_async_session_local`**: Handles functions using `async with AsyncSessionLocal() as session:`
- Both fixtures work together automatically, ensuring complete test isolation

**Example: Testing a complete flow with both patterns**

```python
# Service layer (uses AsyncSessionLocal directly)
async def create_user_internal(name: str) -> User:
    """Internal service function that creates a user."""
    async with AsyncSessionLocal() as session:
        user = User(name=name, id=str(uuid.uuid4()))
        session.add(user)
        await session.commit()
        await session.refresh(user)
        return user

# API route (uses Depends(get_async_db))
@router.post("/users")
async def create_user(
    name: str,
    session: AsyncSession = Depends(get_async_db)
):
    """API endpoint that uses dependency injection."""
    user = User(name=name, id=str(uuid.uuid4()))
    session.add(user)
    await session.commit()
    return user

# Test that uses both patterns
@pytest.mark.asyncio
async def test_mixed_patterns(client: AsyncClient):
    """Test that combines API calls and direct service calls."""
    # API call (uses override_db fixture)
    response = await client.post("/users", json={"name": "API User"})
    assert response.status_code == 201

    # Direct service call (uses mock_async_session_local fixture)
    user = await create_user_internal("Service User")
    assert user.name == "Service User"

    # Both operations are in the same transaction
    # Both will be rolled back after the test
```

**When you need this:**
- Service layer functions that create their own sessions
- Background tasks that use `AsyncSessionLocal` directly
- Utility functions that need database access
- Any code pattern using `async with AsyncSessionLocal() as session:`

**You don't need to do anything special** - the fixture is auto-applied to all tests!
