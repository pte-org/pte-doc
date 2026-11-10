# Practice common toast parity

Date: 2026-11-07

The Practice ToastProvider was wired correctly, but still used an older port's
CSS: gray raised surface, dark message text, circular status/dismiss icons,
different padding, typography and viewport placement.

Updated the shared Practice Toast component to match pte-web/packages/ui's
Toast.tsx and design-tokens.css. Removed its old styles from app/globals.css;
the component now owns common/components/toast.css and ToastIcon.tsx.
Queue limits, timeouts, dismiss options and toast API remain unchanged.
This applies to all Practice toasts, not a login-only override.

Verification:

- Scoped ESLint: passed.
- Typecheck: passed.
- Full unit suite: 77 files / 681 tests passed.
- Production build: passed.
- git diff --check: passed.
- Browser parity passed at light 1440px, light 375px, dark 1440px.
- Computed surface, border, radius, padding, gap, effective shadow, message
  color, font size, line height, icon size and icon path matched Web common.
  Transparent Tailwind ring-shadow layers were excluded from shadow comparison.
- Dismiss buttons worked; no horizontal overflow at tested widths.

The Vendor dev server on 3001 currently returns 500 because of an unrelated
new QuantityStepper.tsx import of @/lib/cn. Existing concurrent generation/UI
work was preserved. The previously built Vendor application was started
temporarily on 3101 for comparison, then stopped after verification.

Screenshots:

- [Practice light desktop](assets/261107-common-toast-parity/practice-light-1440.png)
- [Web common light desktop](assets/261107-common-toast-parity/vendor-light-1440.png)
- [Practice light mobile](assets/261107-common-toast-parity/practice-light-375.png)
- [Practice dark desktop](assets/261107-common-toast-parity/practice-dark-1440.png)
