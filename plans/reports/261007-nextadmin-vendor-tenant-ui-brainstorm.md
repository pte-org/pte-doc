# Brainstorm: NextAdmin visual skin for vendor tenant management

**Date:** 2026-10-07  
**Status:** Direction selected; implementation started after this record

## Ideas Explored

1. **Copy the whole NextAdmin dashboard page.** Rejected because it would pull
   page-specific markup, mock data, and behavior into `pte-web`.
2. **Common-first visual foundation.** Selected: translate the NextAdmin
   surface system into `@pte/ui`, then let the tenant screen compose the shared
   shell, cards, filters, table, menus, and motion primitives.
3. **Global CSS overlay only.** Fast for a screenshot, but brittle because
   existing component classes would win or conflict across vendor and tenant
   screens.
4. **Screen-local restyling only.** Rejected because it would repeat styles in
   small components and violate the user's common-first rule.
5. **Subtle common motion layer.** Selected: use shared reveal, dropdown, modal,
   and hover transitions with `prefers-reduced-motion` support.
6. **Pilot then expand.** Selected: first apply the system to
   `vendor-web /admin/tenants`; other vendor/admin screens remain out of scope
   for this cook.

## User's Direction

- Start with vendor/admin tenant management.
- Build common UI primitives and visual tokens before screen-specific work.
- Use the visual style of `nextjs-admin-dashboard`.
- Keep the existing PTE logo.
- Change UI and animation only; preserve API calls, auth, routes, state,
  validation, actions, and business logic.

## Open Questions

None blocking. Animation defaults to short, subtle transitions and is disabled
for users who request reduced motion.

## Risks

- Changing shared `@pte/ui` styles can affect other screens; changes must stay
  presentation-only and be verified with the vendor build.
- Adding wrappers for motion can accidentally change table or flex layout;
  wrappers must be layout-neutral.
- The existing design-token file already contains a PTE-adapted palette, so
  the implementation should refine and reuse it rather than introduce a
  second token system.
