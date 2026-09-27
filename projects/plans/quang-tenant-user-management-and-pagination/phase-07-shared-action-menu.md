# Phase 07: Shared action menu

## Objective

Extend the existing `@pte/ui` `Dropdown` into a stable common row-action
primitive for tenant and vendor CRUD/lifecycle screens.

## Contract

- item label and callback are required;
- icon, danger tone, disabled state, hidden state, and divider are optional;
- accessible trigger label and alignment remain configurable;
- selection closes the menu unless the item is disabled/hidden.

## Design constraints

- Keep the component domain-neutral.
- Preserve existing consumers with backwards-compatible defaults.
- Keep portal positioning, viewport collision handling, and focus-visible
  styles.

## Quality/testing state

- Component/typecheck tests: passed through `@pte/ui` typecheck and tenant/vendor
  typechecks.
- Tenant/vendor builds: passed.
- Visual browser smoke: pending for the new menus; prior deployed smoke remains
  non-mutating and did not exercise persisted row actions.
