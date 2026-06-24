# Backend Development Guide

## Technology Stack

### Core Framework
- **FastAPI**: Modern, async Python web framework with automatic API documentation
  - Auto-generated OpenAPI/Swagger docs at `/docs`
  - Type validation with Pydantic
  - Async/await support for high performance
  - Dependency injection system

### Database & ORM
- **PostgreSQL**: Primary database
- **SQLAlchemy 2.0**: ORM with async support via `asyncpg`
  - Declarative models in `src/models.py`
  - Async sessions via `src/get_async_db.py`
  - Connection pooling configured in settings
- **Alembic**: Database migration management
  - Migration files in `alembic/`
  - Configuration in `alembic.ini`

### Authentication
- **Ciridae Auth Integration**: Custom authentication service
  - Token verification in `src/auth/verify_user.py`
  - Protected routes using `Depends(verify_user)`
  - Firebase Admin SDK for token validation

### Development Tools
- **uv**: Fast Python package manager
  - Dependency management via `pyproject.toml`
  - Lock file for reproducible builds (`uv.lock`)
- **Ruff**: Linter and formatter (replaces Black, isort, flake8)
- **Basedpyright**: Strict static type checking
- **pytest**: Testing framework with async support

## Project Structure

```
backend/
├── src/                      # Main application code
│   ├── server.py            # FastAPI app initialization & middleware
│   ├── config.py            # Pydantic settings management
│   ├── models.py            # SQLAlchemy ORM models
│   ├── get_async_db.py      # Database session management
│   ├── auth/                # Authentication logic
│   │   └── verify_user.py   # Token verification dependency
│   └── routes/              # API endpoints
│       ├── health.py        # Health check endpoint
│       └── example_route.py # Example protected route
├── tests/                   # Test suite
│   ├── fixtures/            # Test fixtures
│   ├── routes/              # Route-specific tests
│   ├── unit/                # Unit tests
│   └── conftest.py          # pytest conftest
├── alembic/                 # Database migrations
├── pyproject.toml          # Project dependencies & configuration
├── uv.lock                 # Dependency lock file
├── alembic.ini             # Alembic configuration
└── Dockerfile              # Container configuration
```

## Key Architecture Patterns

### API Route Organization
- Routes are organized in `src/routes/` as separate modules
- Each route module exports a FastAPI `APIRouter`
- Routers are included in main app via `app.include_router()`
- Example pattern:
```python
from fastapi import APIRouter, Depends
from src.auth.verify_user import verify_user

router = APIRouter()

@router.get("/endpoint")
async def handler(user_id: str = Depends(verify_user)):
    # Protected endpoint logic
```

### Configuration Management
- Environment variables managed via Pydantic Settings
- `.env` file for local development
- Type-safe configuration access via `src.config.settings`
- Required environment variables:
  - `DATABASE_URL`: PostgreSQL connection string
  - `GOOGLE_CLOUD_PROJECT`: GCP project ID
  - `AUTH_SERVICE_BACKEND_URL`: Auth service endpoint
  - `PROJECT_ID`: Project identifier

### Database Sessions
- Async database sessions via dependency injection
- Use `Depends(get_async_db)` to get session in routes
- Automatic session cleanup after request completion
- Connection pooling for performance
- Never leave sessions open after use. Always close them explicitly. Outside actions such as llm calls should not be run while database sessions remain open.

### Search Implementation
- Default to PostgreSQL for database search.
- Use PostgreSQL full-text search (FTS) for most user-facing search over natural-language text fields; do not hand-roll tokenizers, regex splitters, or word-boundary matchers.
- Consider alternative strategies only for specific requirements: `ILIKE` for exact substring matching, exact indexes for structured lookups, trigram search for fuzzy matching, and vector search for semantic similarity.
- Before filtering on an unfamiliar column, inspect its real values first, for example with `SELECT DISTINCT`.

### Error Handling
- Global exception handlers in `server.py`
- HTTPException for expected errors with proper status codes
- Generic exception handler for unexpected errors (returns 500)
- Structured error responses with `detail` field
- Never pass stack traces or raw errors directly to the client via HTTP Errors or otherwise
- Create custom exceptions for errors instead of using generic `ValueError` or `RuntimeError` instances


## Coding Standards

### Type Hints
- Always use type hints for all function arguments and return values, including `None` when appropriate
- Use built-in generic types (e.g., `list[str]`, `dict[str, int]`) instead of legacy types from `typing`
- Use the `|` operator for union types (e.g., `str | None` instead of `Optional[str]`)
- Use Pydantic models instead of `@dataclass` for structured data and validation; make value objects you don't mutate frozen with `model_config = ConfigDict(frozen=True)`.
- Functions should accept and return specific types (e.g. `UserInformation` as a Pydantic base model instead of `dict[str, Any]`)
- Prefer string literals (`Literal["a", "b"]`) over `str`/SQLAlchemy enums for fixed value sets — enums cause friction in autogenerated migrations (no down-step) and conversions, while a literal enforces the same constraint at the Python layer.
- Parse a loosely-typed value into a Pydantic model or brand it (`NewType`) instead of passing a bare `str`/`dict` around. If you made a type, use it — don't fall back to `object` plus casts.
- Never use the `Any` type unless absolutely necessary.
- All functions must have type hints for all arguments and return values.
- Never use arbitrary generic types like `dict` or `list` whose contents are unclear or hard to reason about. Use explicit types for data models and require strong typing on all function inputs and return values.
- Do not pass around unstructured dict[str, Any] or mixed-type lists when a typed model would be clearer. Use precise type annotations for all function parameters and return values.
- All FastAPI routes must have type hints for the request and response models. The output of the route must be a pydantic model to take advantage of the rust serializer.

### Docstrings
- Every function must include a Google-style docstring
- Include descriptions for: what the function does, parameters, return values, and exceptions explicitly raised. The code should explicitly catch index and os errors and raise custom exceptions.
- Ruff will check for docstring coverage and formatting. Always fix the issues reported by Ruff before committing.

Example:
```python
def get_user_age(name: str) -> int:
    """
    Retrieves the age of a user by their name.

    Args:
        name: The name of the user.

    Returns:
        The age of the user as an integer.

    Raises:
        ValueError: If the user does not exist or has no age recorded.
    """
```


### LLM Usage
- **ALWAYS use the LLM Gateway** when integrating with any LLM provider
- Never make direct API calls to OpenAI, Anthropic, Google, or other LLM providers
- Use the OpenAI-compatible client with the Gateway URL and API key
- See `docs/llm_gateway_docs.md` for implementation details

Example:
```python
from openai import AsyncOpenAI

# Correct - using LLM Gateway
client = AsyncOpenAI(
    api_key=os.environ["LLM_GATEWAY_API_KEY"],
    base_url=os.environ.get("GATEWAY_BASE_URL", "https://llm-gateway-5q22j.ondigitalocean.app"),
)

# Wrong - direct provider calls
# client = OpenAI(api_key="sk-...")  # DO NOT DO THIS
# client = anthropic.Client(...)     # DO NOT DO THIS
```

### Code Style Guidelines

#### Named Parameters
- Use named parameters when calling methods unless the parameters are obvious
- This is especially important for:
  - Methods with multiple parameters
  - Boolean parameters
  - Numeric parameters
  - Non-standard library methods


#### Method Design
- Break down complex methods into smaller, unit-testable functions
- Each method should have a single, clear responsibility
- Methods should be easy to test in isolation

#### Naming Conventions
- Use clear, descriptive names that explain the purpose
- Avoid abbreviations unless widely understood
- Prefer clarity over brevity
- **One exported function per file, named after that function.** A single-public-function module's file name and function name must match — `fetch_cloud_run_logs.py` defines `fetch_cloud_run_logs(...)`. Don't bury the main export in a vaguely-named file.
- **A file name answers "what does this do?"** Name files for their one job (`resolve_cloud_run_log_target.py`), never a `utils.py` / `helpers.py` junk drawer. If you can't tell what's in a file from its name, rename it.
- **One concern per file.** Each function, type, or model with its own responsibility gets its own file in a named subpackage — not grab-bagged together or left loose at the top of `src/`.
- **Bake intent into the name** — e.g. put `default` in the name when it holds the default.

#### File Ordering — Top-Down Readability
Files should read like a story: **highest-level (exported/public) functions first, lower-level helpers below.** A reader opening a file should immediately see the public API at the top, with implementation details further down.

```python
# Good — public function first, helper below
def create_user(name: str) -> UserResponse:
    """Creates a new user."""
    validated = _validate_name(name)
    return _persist_user(validated)

def _validate_name(name: str) -> str:
    """Validates and normalizes a user name."""
    ...

def _persist_user(name: str) -> UserResponse:
    """Persists a user to the database."""
    ...
```

```python
# Bad — helpers before the main function
def _validate_name(name: str) -> str: ...
def _persist_user(name: str) -> UserResponse: ...

def create_user(name: str) -> UserResponse:
    validated = _validate_name(name)
    return _persist_user(validated)
```

#### Defaults in One Place
- **Define every default exactly once.** Don't re-spell a default across nested layers (route → service → helper); set it at the lowest layer that owns it and pass it explicitly above. Nested defaults silently disagree the moment you forget to thread one through.
- **Don't add options or arguments that callers never pass.** Drop unused parameters rather than carry speculative flexibility.

#### Scope Discipline
- **Keep a PR to its stated change.** Unrelated fixes, reformatting, and "while I'm here" edits to shared modules belong in their own PR — split them out.
- Watch for edits that sneak in while satisfying the type checker or linter; revert anything that isn't part of the change.

## Development Tools

### Package Management
- **uv**: Package manager for dependency management
  - Add dependencies: `uv add <package>`
  - Run files: `uv run <filename.py>`

### Code Quality Tools
- **Ruff**: Linter and formatter
  - Lint: `uv run ruff check`
  - Format: `uv run ruff format`
- **Basedpyright**: Strict static type checker
  - Type check: `uv run basedpyright`

### Running Quality Checks
Always run these commands before considering a change complete:
```bash
uv run ruff check --fix
uv run ruff format
uv run basedpyright
```
Make sure all 3 of these commands are run before considering code complete.
Make sure these commands are run on the whole backend so that type errors haven't propagated to other files.

Always fix the issues reported by ruff and Basedpyright before committing. Do not just skip the issues or add comments to disable the checks. There should almost never be a scenario where you need to disable a check and if you do, you must provide a clear justification in a comment next to the code that you are disabling the check for.

## Common Mistakes
These are common mistakes that developers make. Look closely at this section to make sure you avoid these mistakes.

* **Blocking I/O Blocks the Event Loop:** Filesystem calls like `f.read()` and `os.path.exists()` are blocking and will stall FastAPI's async event loop, especially with mounted buckets. Always use async or thread pools for blocking I/O operations.

* Database mistakes
  * **Never Guess Database Credentials:** Do not assume default credentials like `postgres`/`postgres`. Check `docker-compose.yml` for the actual values before running `psql` commands:
    ```bash
    # Find credentials in docker-compose.yml
    grep -E 'POSTGRES_(USER|DB|PASSWORD)' docker-compose.yml

    # Then use those values
    docker-compose exec -T db psql -U <POSTGRES_USER> -d <POSTGRES_DB> -c "..."
    ```
    The fullstack-template convention is `dev_user` / `<project>_dev` — never `postgres`.

  * **Never Manually Edit Migration Files:** Once Alembic generates a migration file, do not modify it by hand. If changes are needed, revert or delete the migration and regenerate it from updated models.

  * **Always Generate Migrations for Model Changes:** After modifying SQLAlchemy models, run `uv run alembic revision --autogenerate -m "description of change"` to create a corresponding migration. Never push model changes without an accompanying migration file.

  * **Always Use Mapped[Type] for all model fields in SQLAlchemy models:** Use the Mapped[Type] syntax for all model fields. Do not use the old-style `Column(Type)` syntax. This way you get type hints and validation for free.

  * **Never Use JSONB in SQLAlchemy Models:** Do not add PostgreSQL `JSONB` columns to SQLAlchemy models. Model structured data with typed relational columns and tables instead so schema, migrations, validation, and queries remain explicit.

  * **Database Must Be Running for Alembic Commands:** All Alembic commands require a running PostgreSQL database. Start it with `docker-compose up -d db` before running migrations.

* Docker dependency issues
  * **New Dependencies Not Appearing In Compose:** Docker installs backend Python packages into `/opt/venv` inside the backend image. If you add a dependency with `uv add`, rebuild the backend image before starting the service:
    ```bash
    docker-compose up --build backend
    ```
    Do NOT use `docker-compose down -v` for dependency refreshes as this drops all volumes including your database.
