# Review Bot Files

The canonical review checklist is hierarchical:

- [`REVIEW.md`](./REVIEW.md) applies repository-wide.
- [`backend/REVIEW.md`](./backend/REVIEW.md) adds backend-specific review rules.
- [`frontend/REVIEW.md`](./frontend/REVIEW.md) adds frontend-specific review rules.

Bot entry points:

- Devin Review reads `**/REVIEW.md` and scopes files by directory. Docs: [Devin Review](https://docs.devin.ai/work-with-devin/devin-review#reviewmd).
- Cursor Bugbot reads the root `.cursor/BUGBOT.md` plus nested `.cursor/BUGBOT.md` files found while traversing upward from changed files. Docs: [Cursor Bugbot](https://cursor.com/docs/bugbot#repository-rules).
- CodeRabbit reads well-known guideline files such as `**/AGENTS.md` by default. This repo's [`.coderabbit.yaml`](./.coderabbit.yaml) adds `**/REVIEW.md` so the same hierarchy is available to CodeRabbit. Docs: [CodeRabbit code guidelines](https://docs.coderabbit.ai/knowledge-base/code-guidelines) and [path-based review instructions](https://docs.coderabbit.ai/configuration/path-instructions).
