---
name: supabase-data-hooks
version: 1.0.0
description: |
  Generate and review Supabase data hooks using SWR + @supabase-cache-helpers/postgrest-swr.
  Creates model-scoped custom hooks (useUsers, useProjects, etc.) that encapsulate ALL data
  operations: reads via useQuery, mutations via useSWRMutation or apiClient for RLS-bypass paths.
  Always verifies useSupabase hook exists before generating anything.
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - AskUserQuestion
---

# Supabase Data Hooks

You are implementing or reviewing data-access hooks for a project that uses Supabase as its
backend. The architecture is:

- **Read** → `useQuery` from `@supabase-cache-helpers/postgrest-swr` (auto cache, invalidation)
- **Mutation (client-safe)** → `useSWRMutation` calling the Supabase JS client directly
- **Mutation (RLS bypass)** → `apiClient` calling a Next.js/Express API route; read-back via plain `useSWR`
- **Supabase instance** → always obtained from a `useSupabase` hook (never import the client directly in model hooks)

---

## Step 0 — Understand the request

Determine what the user wants:
- Implement a **new** model hook (e.g. `useUsers`, `useProjects`)
- Review or extend an **existing** hook
- Decide whether an operation should go through the Supabase client or an API route

Ask with `AskUserQuestion` if the model name or table name is unclear.

---

## Step 1 — Verify `useSupabase` exists

Search the codebase for the `useSupabase` hook:

```bash
grep -r "useSupabase" --include="*.ts" --include="*.tsx" -l .
```

**If not found**, STOP and report:

> `useSupabase` hook not found. This hook MUST exist before any model hook can be created.
> Create it first at `hooks/useSupabase.ts` (see template in Step 1a), then re-run this skill.

**If found**, read the file to confirm its signature — it must return a Supabase client instance.
A correct implementation looks like:

```ts
// hooks/useSupabase.ts
import { createBrowserClient } from '@supabase/ssr'
import { useMemo } from 'react'
import type { Database } from '@/types/supabase'   // generated types

export function useSupabase() {
  return useMemo(
    () =>
      createBrowserClient<Database>(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
      ),
    []
  )
}
```

> **Reference:** `@supabase/ssr` docs — https://supabase.com/docs/guides/auth/server-side/creating-a-client
> The browser client is safe to create on every render **only if memoised**; `createBrowserClient` is
> a singleton factory internally, but the hook must still wrap it in `useMemo` for stability.

### Step 1a — `useSupabase` template (create only if missing)

Write `hooks/useSupabase.ts` with the content above, then confirm with the user before proceeding.

---

## Step 2 — Verify required packages

Check `package.json` for these dependencies:

```bash
cat package.json | grep -E "swr|supabase-cache|supabase/ssr|supabase-js"
```

Required packages:

| Package | Purpose |
|---|---|
| `swr` | Core SWR primitives (`useSWR`, `useSWRMutation`) |
| `@supabase-cache-helpers/postgrest-swr` | `useQuery` over PostgREST with automatic cache invalidation |
| `@supabase/ssr` | Browser/server Supabase client factory |
| `@supabase/supabase-js` | Core Supabase client (peer dep) |

If missing, advise:

```bash
npm install swr @supabase-cache-helpers/postgrest-swr @supabase/ssr @supabase/supabase-js
```

> **References:**
> - SWR — https://swr.vercel.app/docs/getting-started
> - postgrest-swr cache helpers — https://supabase-cache-helpers.vercel.app/postgrest/queries/postgrest-swr
> - npm: @supabase-cache-helpers/postgrest-swr — https://www.npmjs.com/package/@supabase-cache-helpers/postgrest-swr

---

## Step 3 — Determine read strategy

Before writing code, clarify the read path:

| Scenario | Hook to use |
|---|---|
| Simple authenticated query (respects RLS) | `useQuery` from `@supabase-cache-helpers/postgrest-swr` |
| Complex server-side query or RLS bypass | plain `useSWR` calling an API route |
| Paginated list | `useOffsetInfiniteQuery` or `useSWRInfinite` |
| Single row by ID | `useQuery(...).select('*').eq('id', id).single()` |

**Default to `useQuery`**. Only use the API route read path when the user confirms RLS bypass
or complex joins that cannot be expressed as a single PostgREST query.

---

## Step 4 — Determine mutation strategy

| Scenario | Mutation path |
|---|---|
| Insert / update / delete that respects RLS | `useSWRMutation` calling Supabase client directly |
| Needs service-role key, triggers, or bypasses RLS | `apiClient` hitting a Next.js API route |
| Complex business logic (email, payment, side-effects) | `apiClient` hitting an API route |

**Decision rule:** if the operation would need `SUPABASE_SERVICE_ROLE_KEY` on the client, it MUST go through an API route.

---

## Step 5 — Implement the model hook

### 5a — Full client-side pattern (all operations through Supabase JS)

```ts
// hooks/use[Model].ts
// Example: hooks/useUsers.ts
import useSWR from 'swr'
import { useQuery } from '@supabase-cache-helpers/postgrest-swr'
import useSWRMutation from 'swr/mutation'
import { useSupabase } from '@/hooks/useSupabase'
import type { Database } from '@/types/supabase'

type User = Database['public']['Tables']['users']['Row']
type UserInsert = Database['public']['Tables']['users']['Insert']
type UserUpdate = Database['public']['Tables']['users']['Update']

export function useUsers() {
  const supabase = useSupabase()

  // ── READ ────────────────────────────────────────────────────────────────
  // useQuery integrates with SWR: key is derived from the PostgREST query
  // object, cache is automatically invalidated when mutations run.
  const {
    data: users,
    error,
    isLoading,
    isValidating,
    mutate,   // manual revalidation
  } = useQuery(
    supabase
      .from('users')
      .select('id, email, name, created_at')
      .order('created_at', { ascending: false }),
    {
      revalidateOnFocus: false,
    }
  )

  // ── CREATE ───────────────────────────────────────────────────────────────
  // useSWRMutation: does NOT fire automatically; call trigger(payload) to run.
  // The key matches the read key so the cache is invalidated on success.
  const { trigger: create, isMutating: isCreating } = useSWRMutation(
    ['users', 'create'],
    async (_key: string[], { arg }: { arg: UserInsert }) => {
      const { data, error } = await supabase
        .from('users')
        .insert(arg)
        .select()
        .single()
      if (error) throw error
      return data
    },
    { revalidate: true }   // revalidate the read query after mutation
  )

  // ── UPDATE ───────────────────────────────────────────────────────────────
  const { trigger: update, isMutating: isUpdating } = useSWRMutation(
    ['users', 'update'],
    async (_key: string[], { arg }: { arg: { id: string } & UserUpdate }) => {
      const { id, ...patch } = arg
      const { data, error } = await supabase
        .from('users')
        .update(patch)
        .eq('id', id)
        .select()
        .single()
      if (error) throw error
      return data
    },
    { revalidate: true }
  )

  // ── DELETE ───────────────────────────────────────────────────────────────
  const { trigger: remove, isMutating: isDeleting } = useSWRMutation(
    ['users', 'delete'],
    async (_key: string[], { arg }: { arg: { id: string } }) => {
      const { error } = await supabase
        .from('users')
        .delete()
        .eq('id', arg.id)
      if (error) throw error
    },
    { revalidate: true }
  )

  return {
    // data
    users,
    // state
    error,
    isLoading,
    isValidating,
    isCreating,
    isUpdating,
    isDeleting,
    // actions
    create,   // (payload: UserInsert) => Promise<User>
    update,   // ({ id, ...patch }: { id: string } & UserUpdate) => Promise<User>
    remove,   // ({ id }: { id: string }) => Promise<void>
    mutate,   // () => void  — force revalidation
  }
}
```

> **SWR mutation reference:** https://swr.vercel.app/docs/mutation
> **postgrest-swr useQuery reference:** https://supabase-cache-helpers.vercel.app/postgrest/queries/postgrest-swr

---

### 5b — Mixed pattern (reads via useQuery, writes via API route)

Use this when any CUD operation must bypass RLS or run as service-role.

```ts
// hooks/use[Model].ts  — RLS-bypass writes
import { useQuery } from '@supabase-cache-helpers/postgrest-swr'
import useSWRMutation from 'swr/mutation'
import { useSupabase } from '@/hooks/useSupabase'
import { apiClient } from '@/lib/apiClient'   // see Step 6
import type { Database } from '@/types/supabase'

type User = Database['public']['Tables']['users']['Row']
type UserUpdate = Database['public']['Tables']['users']['Update']

export function useUsers() {
  const supabase = useSupabase()

  // READ — still goes through client (RLS shows the right rows to the caller)
  const { data: users, error, isLoading, mutate } = useQuery(
    supabase
      .from('users')
      .select('id, email, name, role, created_at')
      .order('created_at', { ascending: false })
  )

  // WRITE — uses apiClient; the API route holds the service-role key
  const { trigger: update, isMutating: isUpdating } = useSWRMutation(
    '/api/admin/users',                // key = API route URL
    async (url: string, { arg }: { arg: { id: string } & UserUpdate }) => {
      return apiClient.patch(`${url}/${arg.id}`, arg)
    },
    {
      revalidate: false,               // manual mutate for optimistic UI
      onSuccess: () => mutate(),       // revalidate the read query
    }
  )

  const { trigger: remove, isMutating: isDeleting } = useSWRMutation(
    '/api/admin/users',
    async (url: string, { arg }: { arg: { id: string } }) => {
      return apiClient.delete(`${url}/${arg.id}`)
    },
    { onSuccess: () => mutate() }
  )

  return {
    users,
    error,
    isLoading,
    isUpdating,
    isDeleting,
    update,
    remove,
    mutate,
  }
}
```

---

## Step 6 — `apiClient` (required for API-route mutations)

If any hook uses API routes, verify `lib/apiClient.ts` exists:

```bash
find . -path "*/lib/apiClient*" -o -path "*/utils/apiClient*" | grep -v node_modules
```

If missing, create it. The `apiClient` is a **thin wrapper around `fetch`** for typed CUD calls.
It is NOT a full HTTP client library — keep it minimal.

```ts
// lib/apiClient.ts
type JsonBody = Record<string, unknown> | unknown[]

async function request<T>(
  method: string,
  url: string,
  body?: JsonBody
): Promise<T> {
  const res = await fetch(url, {
    method,
    headers: { 'Content-Type': 'application/json' },
    body: body !== undefined ? JSON.stringify(body) : undefined,
    credentials: 'include',   // sends session cookie for auth
  })

  if (!res.ok) {
    const message = await res.text().catch(() => res.statusText)
    throw new Error(`${method} ${url} → ${res.status}: ${message}`)
  }

  // 204 No Content — return undefined cast as T
  if (res.status === 204) return undefined as T

  return res.json() as Promise<T>
}

export const apiClient = {
  get:    <T>(url: string)                   => request<T>('GET', url),
  post:   <T>(url: string, body: JsonBody)   => request<T>('POST', url, body),
  patch:  <T>(url: string, body: JsonBody)   => request<T>('PATCH', url, body),
  put:    <T>(url: string, body: JsonBody)   => request<T>('PUT', url, body),
  delete: <T>(url: string)                   => request<T>('DELETE', url),
}
```

> Plain `useSWR` should be used for GET calls to API routes (not `apiClient.get`), because SWR handles
> caching, deduplication, and revalidation. `apiClient` is only for CUD (POST, PATCH, PUT, DELETE).

---

## Step 7 — Generated types (optional but strongly recommended)

If the project uses Supabase-generated TypeScript types, verify they exist:

```bash
find . -name "supabase.ts" -path "*/types/*" | grep -v node_modules
```

If missing, advise the user to generate them:

```bash
npx supabase gen types typescript --project-id <project-id> > types/supabase.ts
```

> **Reference:** https://supabase.com/docs/reference/javascript/typescript-support

Always use generated `Database` types in model hooks. Avoid raw `any` or hand-written row types.

---

## Step 8 — Single-record hook variant

For detail pages that load one record by ID:

```ts
export function useUser(id: string | null) {
  const supabase = useSupabase()

  return useQuery(
    id
      ? supabase
          .from('users')
          .select('*')
          .eq('id', id)
          .single()
      : null,   // null key = SWR does not fetch
    { revalidateOnFocus: false }
  )
}
```

The `null` key is the standard SWR pattern for conditional fetching.

> **Reference:** https://swr.vercel.app/docs/conditional-fetching

---

## Step 9 — Checklist before finishing

Review the generated hook against this checklist:

- [ ] `useSupabase` is imported and called at the top of the hook — **never** import Supabase client directly
- [ ] All reads use `useQuery` (or `useSWR` for API-route reads) — no `useEffect` + `useState` fetch waterfalls
- [ ] All mutations use `useSWRMutation` — no `useState(isLoading)` manual tracking
- [ ] Mutations that require RLS bypass go through `apiClient` + API route
- [ ] The hook returns typed data (uses `Database` generated types, not `any`)
- [ ] Mutation triggers call `mutate()` or set `revalidate: true` so the read cache updates
- [ ] No service-role key in any client-side file
- [ ] `apiClient` only used for CUD; GET reads use `useSWR` or `useQuery`
- [ ] `useQuery` key is `null` when the required ID is not yet available (conditional fetching)
- [ ] Hook file is in `hooks/` and named `use[ModelPascalCase].ts`

---

## Quick reference — official docs

| Topic | URL |
|---|---|
| SWR getting started | https://swr.vercel.app/docs/getting-started |
| useSWR API | https://swr.vercel.app/docs/api |
| useSWRMutation | https://swr.vercel.app/docs/mutation |
| SWR conditional fetching | https://swr.vercel.app/docs/conditional-fetching |
| SWR pagination / useSWRInfinite | https://swr.vercel.app/docs/pagination |
| postgrest-swr useQuery | https://supabase-cache-helpers.vercel.app/postgrest/queries/postgrest-swr |
| @supabase-cache-helpers/postgrest-swr npm | https://www.npmjs.com/package/@supabase-cache-helpers/postgrest-swr |
| Supabase JS select | https://supabase.com/docs/reference/javascript/select |
| Supabase JS insert | https://supabase.com/docs/reference/javascript/insert |
| Supabase JS update | https://supabase.com/docs/reference/javascript/update |
| Supabase JS delete | https://supabase.com/docs/reference/javascript/delete |
| Supabase browser client (@supabase/ssr) | https://supabase.com/docs/guides/auth/server-side/creating-a-client |
| Supabase TypeScript types | https://supabase.com/docs/reference/javascript/typescript-support |
