# Plan review: Tenant Home and Dashboard Navigation

**Review mode:** Manual red-team review  
**Research status:** Research agents timed out; review grounded in the supplied
spec/brainstorm and read-only inspection of the tenant codebase  
**Verdict:** APPROVED FOR IMPLEMENTATION

## Findings and adjudication

### ACCEPTED — client boundary for session-aware Home header

`PublicHeader.tsx` is currently a non-client component, while
`useSessionManager()` is a client hook that hydrates from local storage. The
plan requires either making the header a client component or isolating the
conditional action in a client child. Hydration gating with `isReady` is
required so `/` stays public and does not redirect during the first render.

### ACCEPTED — preserve account-menu logout

Removing every `clearToken` reference from `DashboardChrome.tsx` would break
the intentional account-menu logout. The plan explicitly removes it only from
brand/sidebar navigation and retains it in `HeaderActions.logout`.

### ACCEPTED — no `replace` on brand navigation

The old implementation uses `replace` together with logout. The spec requires
normal browser history for brand-to-Home navigation. The plan distinguishes the
login success redirect, which may continue using `router.replace`, from the
brand link, which must use ordinary `Link` history behavior.

### ACCEPTED — one responsive Dashboard action

Rendering separate desktop and mobile Dashboard links could violate the
"exactly one" acceptance criterion. The plan requires one semantic action with
responsive placement/classes rather than duplicated markup.

### NOTED — expiry semantics are inherited

The existing session store exposes `expiresAt`, but `ProtectedRoute` currently
primarily receives a token-presence boolean. The plan does not introduce a new
authentication policy in this navigation feature. Verification must record any
observed expired-session behavior instead of silently treating it as fixed.

### NOTED — dirty worktree and unrelated navigation edits

`navigation.tsx` already contains unrelated working-tree changes. The cook
phase must establish a baseline and edit only the Home/Overview entries. No
unrelated changes should be reverted.

### REJECTED — vendor/admin implementation phase

The user's clarified scope and spec explicitly exclude `vendor-web/admin`.
Vendor/admin is therefore a verification boundary, not an implementation
phase.

## Review conclusion

The two-phase plan is sufficiently bounded: implementation first, then static
and browser verification. No blocking clarification remains.

