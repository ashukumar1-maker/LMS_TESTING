# Backend Review Guidelines

Apply these rules in addition to the project-wide [`../REVIEW.md`](../REVIEW.md).

## Contracts And Documentation

- When API routes, request/response models, auth behavior, migrations, environment variables, settings, or background jobs change, check that nearby docs, `backend/AGENTS.md`, OpenAPI/generated schemas, examples, and deployment docs stay in sync.
- Flag backend changes that alter externally observed behavior without updating the API contract or documenting the caller impact.

## Types And Boundaries

- Avoid casts and loose primitives; type values as strictly as possible with Pydantic models, `Literal[...]`, branded values, `NewType`, or discriminated unions where they clarify the contract.
- Use Pydantic field types suited to the job, such as `UUID`, `EmailStr`, constrained strings, and explicit request/response models instead of broad `str` or unstructured dictionaries.
- Scrutinize `None` and optional fields: only allow missing values when the real contract can omit them.
- Do not add defaults for values that should always be passed, and define each real default exactly once.
- Do not add Ruff/Basedpyright ignore statements, `Any`, or other type-checker bypasses to silence errors; fix the type model or boundary.

```py
# Avoid: optional/default value that every real caller must know.
async def open_ghost_env_acp_stdio_streams(
    *,
    cwd: str | None = None,
) -> AsyncIterator[...]:
    working_directory = cwd or "/workspace"

# Prefer: require the boundary-owned value.
async def open_ghost_env_acp_stdio_streams(
    *,
    cwd: str,
) -> AsyncIterator[...]:
    ...


class EnvVarSettingProvidence(BaseModel):
    type: Literal["env_var_setting"]
    setting_id: int


class GhostEnvProvidence(BaseModel):
    type: Literal["ghost_env"]
    ghost_env_id: UUID


type EnvVarProvidence = EnvVarSettingProvidence | GhostEnvProvidence
```
