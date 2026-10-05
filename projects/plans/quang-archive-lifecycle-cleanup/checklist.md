# User verification checklist

Backend must be rebuilt/restarted with V77 applied to your development DB to expose new capabilities and DELETE routes. Web changes alone are insufficient; no real development DB migration/restart was performed on your behalf.

## Admin

- [ ] Create a new Plan draft: menu has Edit, Activate, Delete draft; no Archive.
- [ ] Confirm Delete draft: name and soft-delete/audit wording are visible. After 204 it disappears; refresh/direct GET returns not found.
- [ ] Plan with historical order/subscription/license: Delete is blocked with reason, including expired/cancelled history.
- [ ] ACTIVE Plan with a valid issued code: Archive and entitlement changes are blocked; price/metadata edits follow existing validation.
- [ ] ACTIVE Plan without outstanding codes can Archive; existing subscription remains usable. ARCHIVED Plan is read-only.
- [ ] Create a new Question draft: Delete draft, no Archive. Pending approval: neither action. Published: Archive retained.
- [ ] Restored or revision-linked Question cannot Delete. Legacy unknown-history draft is protected rather than assumed unused.
- [ ] Simulate stale state/conflict: dialog stays open with meaningful error and refreshed list capabilities; no false success toast.
- [ ] During Delete/Archive, repeated Confirm, Cancel, X and Escape cannot interrupt/duplicate the operation.

## Tenant

- [ ] Program detail and Class row show Remove, not Archive. Program confirmation says history is retained.
- [ ] Existing active-child/member guards still reject Remove when required. Inactive status is not confused with deletion.
- [ ] Merge help says source classes are not removed automatically. Layout/brand remain unchanged.

## Remaining release gates

- [ ] Fix or explicitly resolve the 11 baseline regression failures in a separately approved task; rerun full backend suite.
- [ ] Run authenticated real API/browser tests for platform-admin, platform-author, tenant and forbidden roles. Standalone MVC/reflection/mock-browser checks do not replace this gate.
- [ ] User accepts lifecycle behavior; commit/push/deploy separately authorized.
