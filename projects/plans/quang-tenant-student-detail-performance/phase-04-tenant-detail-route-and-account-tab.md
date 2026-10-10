# Phase 04: Tenant detail route and account tab

**Status:** Implemented; tenant-web typecheck/build passed; manual UI review pending
**Surface:** `pte-web/apps/tenant-web` and shared UI only if required
**Depends on:** Phase 03 API client/state
**Blocks:** Overview and history tabs

## Superseding decisions (2026-10-10)

Same-tab client navigation replaces every new-tab requirement below. Overview is first/default, Account information is second, and Exam history is third. Account uses the same read-only layout for inline editing. Default common ActionMenu has ellipsis only; student-code copy is beside the code. No password notice, Home breadcrumb or redundant back link. Fresh tenant/vendor/shared-package typechecks passed; manual UI and component/E2E checks remain unverified. The original checklist below is retained as historical planning context, not current acceptance criteria where it conflicts with this section.

## Goal

Create the durable student route and make account information the first, default, operational tab. Migrate the roster's view-details action to a new browser tab while retaining the existing list actions.

## Work items

1. Add the route under the existing tenant dashboard route group using the project's current Next.js conventions.
2. Add a new-tab link/action from the roster row without breaking modifier-key/context-menu behavior or existing list state.
3. Build the page shell: breadcrumb/back context, student header, status badge, student code, and contextual actions.
4. Render tabs in the approved order with `Thông tin tài khoản` selected by default.
5. Build the account tab with `DescriptionList`/form primitives and clear read-only versus editable field treatment.
6. Support save, cancel/reset, validation, loading, stale conflict/error, forbidden, and success feedback states.
7. Reuse suspend/reactivate confirmation and one-time credential-generation UX. Keep credential secrets out of persistent page state.
8. Retire the old student roster `AccountDetailsModal` as the primary detail path after references are migrated; do not remove a shared component still used elsewhere.
9. Verify light/dark tokens, long text wrapping, keyboard focus, and supported responsive widths.

## Account layout contract

- First visual block: student name, code, status, and actions.
- Main information block: full name, email, phone, date of birth, username, role, current class, and current program.
- Editable fields are visibly distinguished from read-only identity/relationship fields.
- The account tab never renders a password or hash.
- Assignment context is informational and links to its existing workflow only if a current route already exists; it is not edited here.

## Design Constraints

- Use the existing `@pte/ui` primitives and design tokens; do not introduce a second detail-card system.
- Keep the account tab first even if the user refreshes or arrives from a deep link without a tab query.
- The new route must be independently loadable and must handle an invalid/forbidden student ID.
- Preserve the original roster filters, pagination, and unsaved list state in the old tab.
- Keep status/credential actions server-authorized and make their result visible in the header/account tab.
- Do not delete unrelated modal or table components without proving they have no other consumers.
- Use accessible labels, focus order, keyboard tab navigation, and clear destructive-action confirmation.

## Quality and Testing State

Implementation evidence: tenant-web `tsc --noEmit` and production build passed. The following planned checks were skipped or remain pending by explicit user request:

- component tests for tab order, field editability, submit/cancel/error states, and action feedback;
- tenant-web lint, `tsc --noEmit`, and build;
- manual UI inspection by the user that roster detail opens a new tab/route and the source list remains unchanged;
- manual UI inspection by the user for forbidden/not-found and long-text layouts;
- `git diff --check` and inspection of unrelated worktree changes.

## Blocking gate

Phase 05 cannot start until the route, default tab, account read/edit flow, status actions, and new-tab navigation are stable.

## Acceptance criteria

- Clicking `Xem chi tiết` opens the dedicated page in a new tab.
- `Thông tin tài khoản` is the first/default tab.
- Approved profile fields can be edited and saved; read-only fields cannot be changed through the form.
- Suspend/reactivate and credential actions retain their current semantics.
- No existing roster search/filter/pagination state is lost when the new tab is opened.
