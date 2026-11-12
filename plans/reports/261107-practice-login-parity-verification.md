# Practice login visual parity verification

Date: 2026-11-07

## Reference and implementation

Compared Practice against the actual `pte-web/packages/ui/src/layouts/AuthBrandShell.tsx`,
`components/AuthFormControls.tsx`, `styles/design-tokens.css` and the tenant/vendor login views.
Read `docs/CODING_STANDARDS_WEB.md` and the installed Next.js CSS/font guides.

Practice now uses the portal's Inter font, neutral surfaces, action gradient, 50px controls,
input borders, focus styling, inline errors, validation ticks, password visibility icons,
responsive split-card sizing, toolbar and footer. Presentation remains scoped to sign-in.
The student account label, recovery guidance and AI Practice identity remain specific to Practice.
The locale control uses a native select; Practice retains its existing MDI icon renderer.

## Verification

- `npm run lint`: exit 0; two existing unused-locale warnings in unrelated recorder/device-check components.
- `npm run typecheck`: exit 0.
- Scoped ESLint on modified TypeScript files: exit 0.
- `npm run test:unit`: 76 files, 672 tests passed.
- `npm run build`: exit 0, including `/sign-in` prerender.
- `git diff --check`: no whitespace errors.
- Browser at 1440x900 and 375x812: no horizontal overflow.
- Browser checks: required-field errors, password reveal/conceal, VI/EN selection and dark-mode toggle.
- No browser page errors during the Practice smoke test.
- Measured Practice and Vendor controls: both input and submit button are 50px high;
  idle input border is `rgb(212, 212, 216)`; button gradient stops match exactly:
  `rgb(14,130,208)`, `rgb(11,112,192)`, `rgb(22,139,216)`, `rgb(14,130,208)`.
- Both pages render Inter and the same light-theme heading color, `rgb(24,24,27)`.

The first build identified a new footer date prerender violation. The copyright read now
has its own Suspense boundary; the subsequent production builds passed.

No authenticated login or password-change API request was performed. This verifies
presentation and local form interactions, not an end-to-end authenticated student session.

## Screenshots

- [Practice desktop](assets/261107-practice-login-parity/practice-light-desktop.png)
- [Vendor reference desktop](assets/261107-practice-login-parity/vendor-light-desktop.png)
- [Practice mobile](assets/261107-practice-login-parity/practice-light-mobile.png)
- [Practice dark mobile](assets/261107-practice-login-parity/practice-dark-mobile.png)
