# Alembic Migrations

## Prerequisites

All Alembic commands require a running PostgreSQL database. Start the database before running commands:

```bash
# Start only the database
docker-compose up -d db

# Or start the full stack (db + backend + frontend)
docker-compose up -d
```

## Golden Rule

**NEVER manually edit migration files.** If a migration needs changes, delete it and regenerate.

## Workflow

1. Modify models in `src/models.py`
2. Generate migration: `uv run alembic revision --autogenerate -m "add created_at to users"`
3. Review the generated file in `alembic/versions/`
4. Apply: `uv run alembic upgrade head`

## Essential Commands

```bash
# Generate migration from model changes (always use --autogenerate)
uv run alembic revision --autogenerate -m "description of change"

# Apply all pending migrations
uv run alembic upgrade head

# Verify models match database schema (catches forgotten migrations)
uv run alembic check

# Show current migration state
uv run alembic current
```

## CI Validation

The `database-tests.yml` workflow runs on every PR that touches `backend/alembic/**` or `backend/src/models.py`:

1. `alembic upgrade head` - tests that migrations apply cleanly
2. `alembic check` - fails if model changes lack a corresponding migration

## Common Mistakes

- Editing migration files instead of regenerating them
- Creating migrations without `--autogenerate`
- Pushing model changes without a corresponding migration
- Modifying database schema directly via SQL
