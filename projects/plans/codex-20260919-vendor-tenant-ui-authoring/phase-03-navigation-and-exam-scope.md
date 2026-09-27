# Phase 3: Navigation, branding, and exam scope

## Admin versus tenant responsibility

- Platform admin manages tenants, applications, plans, license codes, platform
  settings, question bank, question types, and question templates.
- Tenant host/admin users manage learners, exam staff, programs, and exams for
  their organization.
- The admin navigation does not expose the former exam-blueprint workflow as a
  tenant exam-creation screen.
- No new Active subscriptions/Active access navigation item was added.

## Navigation and branding changes

- Tenant navigation is grouped into Home, Users, Delivery, Account, and Data.
- Home links clear the tenant session before returning to the public home.
- Billing and Audit Log visibility is restricted to the appropriate host role.
- Tenant dashboard branding uses the logo/brand link and has keyboard-focus and
  hover states.
- Dashboard navigation labels distinguish Dashboard from the public Home page.

## Main files

- `pte-web/apps/tenant-web/features/auth/components/DashboardChrome.tsx`
- `pte-web/apps/tenant-web/lib/navigation.tsx`
- `pte-web/apps/vendor-web/lib/navigation.tsx`
