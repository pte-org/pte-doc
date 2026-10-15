# Behavior preservation manifest

**Status:** Baseline established for the first migration surfaces.

| Surface | URL/state | Gate | Queries/mutations | Validation/callbacks | Modal/action entry points | Owner |
|---|---|---|---|---|---|---|
| Vendor shell and `/admin/tenants` | Existing pathname and filters | `PLATFORM_ADMIN`/existing admin roles | `useTenants`, lifecycle, quota, create flow | Existing tenant validators and callbacks | Create, suspend, quota, history | `vendor-web` tenancy |
| Vendor tenant detail | `/admin/tenants/[publicId]` | Existing admin roles | Tenant, organization, login, branding mutations | Existing conflict/reset/branding handling | Login, reset password, branding, organization actions | `vendor-web` tenancy |
| Tenant create-exam wizard | Existing modal/form URL | Existing host roles | Existing plans/subscriptions/audience queries and submit callback | `validateCreateExamWorkflow` | Existing modal and step back/next | `tenant-web` exams |
| Tenant dashboard shell | Existing dashboard routes | Existing role arrays | Current-user and notification queries | Existing logout/session lifecycle | Notification/account actions | `@pte/ui` + owning app |

Before/after review must compare pathname/query/hash, role gates, API request
shape, validation, callback ownership, and modal reachability. Presentation
tabs/steps/drawers are allowed; business state is not.
