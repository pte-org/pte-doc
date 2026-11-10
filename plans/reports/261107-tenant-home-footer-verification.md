# Tenant homepage footer verification

Date: 2026-11-07

Replaced the homepage's closing registration call-to-action and white
sign-in/slogan strip with one compact navy footer containing only the
existing PTE Prep brand/home link and copyright.

Removed the unused HomeClosing component and its English/Vietnamese copy.
Other homepage sections, header controls, plan actions and non-home public
footers remain unchanged. Existing concurrent work was preserved.

Verification:

- Scoped ESLint on the five modified public-home files passed.
- Tenant typecheck passed.
- Public copy tests: 2 passed.
- Tenant production build passed.
- Whitespace check passed.
- Browser at 1440px: one footer with brand/copyright, no buttons or
  sign-in/register links in it, and no closing-title CTA section.
- Browser at 375px: footer stacks cleanly with no horizontal page overflow.

Screenshots:

- [Footer desktop](assets/261107-tenant-home-footer/footer-desktop.png)
- [Page bottom desktop](assets/261107-tenant-home-footer/desktop.png)
- [Page bottom mobile](assets/261107-tenant-home-footer/mobile.png)
