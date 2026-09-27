# Phase 10: Screen adoption

## Objective

Replace duplicated row action presentation with the shared menu on the audited
tenant/vendor CRUD and lifecycle screens.

## Acceptance criteria

- No suitable audited CRUD row keeps a bespoke three-dot/inline action cluster
  when the common menu can express it.
- Contextual assignment/review exceptions are documented and intentional.
- Existing action callbacks, confirmation dialogs, links, and query invalidation
  retain their behavior.

## Quality/testing state

- Typecheck/lint/build: passed for tenant-web and vendor-web.
- Manual action-menu interaction check: implemented; a fresh deployed smoke is
  still pending.
- Code review: manual security and callback review passed with no blocker.
