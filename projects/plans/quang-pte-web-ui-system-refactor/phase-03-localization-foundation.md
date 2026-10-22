# Phase 03: Vietnamese-first bilingual locale foundation

## Objective

Introduce `vi`/`en` UI localization with Vietnamese as the clean-profile
default, while keeping shared generic labels separate from app/domain copy.

## Files and Areas

- New `pte-web/packages/ui/src/i18n/**` locale type/provider/hook/switcher
- New app dictionaries under `pte-web/apps/vendor-web/**` and
  `pte-web/apps/tenant-web/**`
- `pte-web/apps/*/app/layout.tsx`
- `pte-web/apps/*/app/providers.tsx`
- `pte-web/apps/*/lib/navigationConstants.ts`
- `pte-web/apps/*/features/**/constants*`
- Locale-aware shared formatter utilities in `@pte/ui` or app utilities

## Inputs

- Phase 01 route/actor matrix and raw-string/formatting inventory.
- Phase 02 theme contract and provider ordering decision.
- Existing vendor and tenant navigation/domain constants.

## Outputs

- `locale-contract.md`: supported values, `pte-web.locale` storage key,
  fallback, `html[lang]`, interpolation, formatter, and missing-key rules.
- `phase-03-verification.md`: clean-profile, switch, reload, fallback, and
  changed-surface translation evidence.

## Steps

1. Define supported locales, fallback behavior, message-key conventions, and
   interpolation typing.
2. Add a client-safe locale provider and browser persistence under
   `pte-web.locale`; accept only `vi`/`en`, fall back to `vi` for missing or
   invalid values, and keep `html[lang]` synchronized with the active locale.
3. Add a common language switcher and migrate shared header/sidebar/control
   labels and accessibility names.
4. Migrate vendor/admin navigation and tenant/host/examiner/student navigation
   constants to message keys or locale-aware label resolution.
5. Migrate all strings touched by the first pilot; use a raw-string audit for
   new/refactored JSX.
6. Replace hard-coded date/number/currency formatting in changed surfaces with
   locale-aware formatters.

## Design Constraints

- `vi` is the default; `en` is the only second locale in this plan.
- `@pte/ui` must not own vendor/tenant business vocabulary.
- Missing translations must not change API error codes or mutation behavior.
- Do not translate user-created names, question content, plan names, or API
  data unless separately approved.

## Quality and Testing State

- Quality: not evaluated.
- Testing: not started; verify clean-profile default, switch, reload, fallback,
  `html[lang]`, and changed navigation labels.

## Blocking Gate

- **PASS** when a clean browser defaults to `vi`, switching to `en` updates all
  changed labels and accessibility names, reload preserves the locale,
  invalid storage falls back to `vi`, and changed date/number/currency output
  uses the selected locale.
- **UNVERIFIED** when a route cannot be loaded with local data; list the route
  and missing evidence in `phase-03-verification.md`; this blocks phase 04
  unless a written waiver follows the master-plan gate policy.
- **BLOCKED** when a changed surface has a missing translation key, new raw UI
  string, incorrect `html[lang]`, or domain/API behavior change.

## Exit Criteria

- Common shell and pilot labels are available in both locales.
- Locale selection survives reload and does not require a server/API change.
- Date/number formatting in the pilot follows the selected locale.
- The changed-surface raw-string audit reports zero new untranslated UI
  strings and zero missing locale keys; intentional domain data is listed
  separately.

## Cook Record 2026-10-07

- Implementation: completed for the shared `vi`-default/`en` runtime, common
  shell labels, pilot labels, persistence, and `html.lang` integration.
- Verification: typechecks and builds passed; full raw-string audit, browser
  reload persistence, and date/number browser checks were not run.
- Blocking Gate: **UNVERIFIED** because the mandatory browser and quality
  evidence was skipped at the user's request.
