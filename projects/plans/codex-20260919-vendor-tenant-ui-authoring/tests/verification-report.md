# Verification report

**Date:** 2026-09-19  
**Environment:** Local Docker-backed API and local Next.js dev servers

## Browser verification

Playwright ran with the local accounts `admin@test` and `host@test` and
confirmed each section opened, collapsed, and reopened:

### Vendor web (`http://localhost:3000`)

- `/admin`
- `/admin/tenants`
- `/admin/licenses`
- `/admin/applications`
- `/admin/plans`
- `/admin/questions`

### Tenant web (`http://localhost:3001`)

- `/host/billing`
- `/host/quota`

Observed state for every tested route:

```text
expanded: true -> false -> true
section visible: true
```

The Programs detail route was not included in the live click list because the
local tenant had no seeded program.

## Static and production verification

The following commands completed successfully:

```text
corepack pnpm --filter vendor-web exec tsc --noEmit
corepack pnpm --filter tenant-web exec tsc --noEmit
corepack pnpm --filter vendor-web lint       # 0 errors, 1 existing warning
corepack pnpm --filter tenant-web lint       # 0 errors
corepack pnpm --filter vendor-web build
corepack pnpm --filter tenant-web build
git diff --check
```

Both production builds generated their route tables successfully.

## Dev-server state after testing

The user requested that frontend ports not be killed after testing. They were
left running:

```text
localhost:3000  LISTENING  PID 5392
localhost:3001  LISTENING  PID 37032
```

No deploy, commit, or push was performed.
