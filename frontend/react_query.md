# React Query Guidance

React Query is the frontend's view of server state. State lives in the server, and the query cache is the client-side projection of it. Components read server data from query hooks at the point of use instead of copying it into local state, context, or another store.

## Query Keys

- Refetch-on-param-change is a `queryKey` change, not a `useEffect` that calls `refetch()`.
- Include every server-state input in the key: IDs, filters, cursors, sort order, and feature-specific flags.
- Use shared query-key constants for feature hooks so mutations invalidate the same key shape that queries use.

## Loading And Refresh States

- In React Query v5, `isLoading` means the first load has no data yet. Do not write `isLoading && !data`.
- Use `isPending` when branching on a query that has not resolved.
- Use `isFetching` for a background-refresh indicator while existing data stays rendered.
- "Last refreshed" comes from `dataUpdatedAt`, not a separate timestamp in component state.

## Refetching And Polling

- `refetch()` resolves with the query result. Branch on `result.isError` or `result.data` instead of wrapping it in `try/catch`.
- Polling is `refetchInterval`, not `setInterval`. `enabled: false` pauses the query and its polling.
- Avoid manual refetch chains. If a mutation changes server state, invalidate the affected query key or update it with `setQueryData` when the new cache value is known.

## Mutations

- Every mutation that changes server state must invalidate the queries it makes stale, or use `setQueryData` when the response contains the exact next cache value.
- Mutation success handlers are for cache updates, PostHog capture, and narrow UI follow-up. They should not copy server data into local state.
- Keep optimistic updates small and reversible. If the rollback shape is more complex than the mutation, invalidate instead.

## Pagination

- Windowed pagination state lives in the query key.
- Cursor accumulation belongs in `useInfiniteQuery`, not component state.
- Keep URL-shareable pagination inputs in the URL, then feed them into the query key.

## Boundary Work React Query Does Not Do

React Query does not replace API-boundary validation or analytics. API hooks still parse backend responses with Zod, capture required PostHog mutation events, and use shared query-key constants.
