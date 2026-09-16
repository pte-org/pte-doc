# Brainstorm: Tenant commercial onboarding and gated dashboard

**Date:** 2026-09-16

## Ideas Explored

1. **Linear gated onboarding:** public home → tenant application → approval status → package activation → dashboard. This keeps the pre-tenant state separate from the actual tenant workspace.
2. **Package-first activation:** show two clearly separated products: time-limited exam packages and permanent student-capacity add-ons. Unlock the workspace after either product is successfully activated.
3. **Quota-first dashboard:** make free quota, permanent capacity grants, and each exam license visible before a tenant creates an exam.
4. **Calendar-first exam management:** use a license-colored calendar to make same-license overlap restrictions visible before the create action.
5. **Conflict-aware enrollment:** show enrollment results as enrolled, already enrolled, and skipped because of an overlapping exam, with the conflicting exam named.

## User's Direction

The tenant web should have a public Home page before the dashboard. A tenant registers and waits for admin approval. After approval, the tenant must successfully activate any package type before the Dashboard button becomes available. The tenant workspace then manages quotas, subscriptions, exams, students, and conflicts.

## Open Questions

- Whether the Free entitlement is automatically activated on approval or must be explicitly selected/activated.
- Exact organization fields and copy for the tenant application form.
- Whether payment status should be shown as a dedicated page or as a reusable checkout status state.

## Risks

- A pending or rejected application must never look like an active tenant workspace.
- Two package types can be confused if they are shown as one generic subscription tier.
- The UI must explain that overlap rules apply per exam license, while student conflicts apply across overlapping exams within the same tenant.
- The server remains authoritative; client-side validation is guidance and must not imply that a request is guaranteed to succeed.
