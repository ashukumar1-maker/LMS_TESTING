# Frontend Review Guidelines

Apply these rules in addition to the project-wide [`../REVIEW.md`](../REVIEW.md).

## Contracts And Documentation

- When routes, API hooks, generated clients, UI behavior, environment variables, design conventions, or analytics events change, check that `frontend/AGENTS.md`, `frontend/STYLE_GUIDELINES.md`, `DESIGN.md`, `CIRIDAE_PRECISION.md`, generated schemas, examples, and user-facing docs stay in sync.
- Flag frontend changes that consume backend data without matching the backend JSON contract, generated types, or Zod schema.

## UI, State, And Types

- Follow Ciridae UI and semantic tokens; do not introduce one-off design systems, hardcoded colors, or custom token names.
- Validate backend data at the API boundary with Zod schemas and `.parse()`; do not trust plain TypeScript response types for server data.
- Use React Query for server state: put every server-state input in the query key, use `invalidateQueries` or `setQueryData` after mutations, use `refetchInterval`/`enabled` for polling, and avoid copied query data, manual refetch chains, or `useEffect`-synced mirrors of server or URL state.
- Do not add `@ts-ignore`, `@ts-expect-error`, `eslint-disable`, `any`, or other lint/type escape hatches; fix the type boundary with `satisfies`, tighter source types, runtime guards, or Zod parsing.

When JSX repeats the same component shape across inline branches, prefer naming the repeated concept and rendering it from a small typed config list.

```tsx
// Avoid: repeated branches obscure the shared footer-link shape.
{showLogsLink && <DeploymentFooterLink {...logsLinkProps} />}
{showSettingsLink && <DeploymentFooterLink {...settingsLinkProps} />}
{showEnvironmentSettingsLink && <DeploymentFooterLink {...environmentSettingsLinkProps} />}

// Prefer: name the domain list and render the shared shape once.
type DeploymentFooterLinkConfig = {
	path: string
	icon: LucideIcon
	label: string
}

const footerLinks = getDeploymentFooterLinks({
	showLogsLink,
	showSettingsLink,
	showTerminalLink,
	showEnvironmentSettingsLink,
})

{footerLinks.map((link) => (
	<DeploymentFooterLink
		key={link.label}
		to={`/project/${projectId}/deployments/${deploymentId}/${link.path}`}
		icon={link.icon}
		label={link.label}
	/>
))}
```

Do not replace every branch with `.map`; use this only when the items share the same component shape and the array has a real domain name.

For complex forms, flag components that combine unrelated responsibilities like input parsing, file upload, mutation orchestration, permission checks, result rendering, copy state, and privacy behavior.

```tsx
// Flag: one form owns selection, parsing, upload, mutation, results, and copy state.
const [selectedEnvironmentName, setSelectedEnvironmentName] = useState("")
const [emailsInput, setEmailsInput] = useState("")
const [bulkResults, setBulkResults] = useState<BulkInviteResult[] | null>(null)
const [copiedIndex, setCopiedIndex] = useState<number | null>(null)

const extractEmails = (text: string): string[] => { ... }
const handleFileUpload = async (...) => { ... }
const handleSubmit = async (...) => { ... }
const copyAllLinks = () => { ... }
const copyIndividualLink = async (...) => { ... }
```

Ask whether each responsibility has a separate reason to change. If yes, split with names like `parseUniqueInviteEmails`, `BulkInviteFieldsForm`, or `GeneratedInviteLinksPanel`; if not, keep it local and readable.
