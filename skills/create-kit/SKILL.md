---
name: create-kit
description: Create or update reusable provisioning kits stored on `kit/*` Git branches with root `KitDescription.md` and `KitInstallation.md`. Use when adding or editing a kit source branch, authoring either root kit markdown file, or explaining how kits for this system should be structured.
---

# Create Kit

## Overview

A kit is an installable package defined by `(source_repo, source_branch)`, where the branch name starts with `kit/`. A valid kit branch must contain both `KitDescription.md` and `KitInstallation.md` at the repository root.

The installer clones the kit beside the target project and uses the kit checkout as reference-only. Installation should change the target project, not mutate the kit checkout in place. The installer is an autonomous agent that must finish the kit installation without clarifying questions.

## Authoring Workflow

1. Create or switch to a branch named `kit/<slug>`.
2. Choose a stable, readable slug. Reuse it consistently in install-facing names.
3. Add or update `KitDescription.md` at the repository root.
4. Add or update `KitInstallation.md` at the repository root.
5. Make the description human-facing and the installation guide agent-facing.
6. Keep installation instructions explicit about scope, integration points, and what must stay untouched.
7. Do not include post-remote follow-up work such as discovery, catalog sync, manual scans, or UI metadata edits unless the user asks for that separately.

## Branch Rules

- Kit branches must start with `kit/`.
- The branch itself is the kit source of truth.
- The slug should be stable and readable rather than temporary or task-specific.
- Write the kit so an install agent can reproduce the behavior in another repo without assuming identical file paths or app structure.

## `KitDescription.md`

Use this file as catalog copy for a human deciding whether to install the kit.

- It must be present and non-empty or the branch may be skipped by kit detection.
- Describe what the kit provides and why someone would want it.
- Keep it concise and product-oriented.
- Do not turn it into an install runbook.

## `KitInstallation.md`

Use this file as the install agent's runbook. The platform adds a fixed system preamble before these instructions. Write the file so it works with that setup rather than repeating it.

Assume the system preamble already tells the installer to:

- work only in the target project working tree
- treat the kit checkout as reference-only
- use the target branch as the PR base
- keep changes minimal and relevant
- run lint and tests when appropriate
- avoid unnecessary container churn
- complete the work without clarifying questions
- finish with the platform's expected commit and PR behavior

Your job in `KitInstallation.md` is to provide the kit-specific instructions the preamble cannot infer:

1. State exactly what the kit should deliver.
2. State exactly what is in scope to copy or recreate in the target repo.
3. State exactly what is out of scope, including application logic, infrastructure, or styling, not related to the kit.
4. Identify the target integration points so the agent knows where new behavior should plug into the target app.
5. Explain how to adapt names, paths, registrations, routes, config, dependency wiring, and exports to the target repo's conventions while preserving the intended behavior.
6. Call out when only part of a source file should be reproduced instead of copying the whole file.
7. Tell the agent what existing modules or flows must remain untouched unless replacement is explicitly required.

## Installation Authoring Rules

- Use a numbered checklist the agent can execute end to end.
- Prefer precise instructions over broad goals.
- Name concrete files, directories, exports, routes, config blocks, or code regions when possible.
- If the kit depends on existing application structure, describe the integration strategy instead of assuming a direct copy will work.
- If a full-file copy would be wrong, specify the exact sections or behaviors to port.
- Keep `KitInstallation.md` authoritative for install behavior even if name, icon, or archived state may be managed elsewhere later.

## Minimal Templates

### `KitDescription.md`

```md
# <Kit Name>

<Short product-style summary of what the kit installs and why it is useful.>
```

### `KitInstallation.md`

```md
# <Kit Name> Installation

1. Inspect the target repo areas this kit must integrate with.
2. Reproduce the in-scope behavior from the kit branch in the target repo.
3. Wire the new behavior into the target repo's existing modules, routes, config, or dependency graph.
4. Skip all explicitly out-of-scope files, folders, and tooling.
5. Run the appropriate validation commands for the touched areas.
```

## Out of Scope

This skill does not cover what happens after the kit branch exists on the remote, including discovery, catalog sync, manual scans, or product UI edits.
