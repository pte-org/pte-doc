# Phase 01 route matrix

**Status:** PASS (static inventory); authenticated browser evidence remains
outside this fast cook run.

The route scan covered the current App Router page files in both web apps. The
route target and role gates are unchanged by the UI refactor.

## Vendor web

| Route group | Routes | Primary actor | Owner |
|---|---|---|---|
| Public/auth | `/`, `/login` | Anonymous | Auth/public |
| Vendor core | `/admin`, `/admin/tenants`, `/admin/tenants/[publicId]`, `/admin/applications`, `/admin/applications/[applicationId]`, `/host` | `PLATFORM_ADMIN`, `HOST_ADMIN` | Dashboard/tenancy |
| Commercial | `/admin/plans`, `/admin/license-codes`, `/admin/licenses`, `/admin/settings` | `PLATFORM_ADMIN`, `HOST_ADMIN` | Commercial/licensing/settings |
| Notifications/support | `/admin/notifications`, `/admin/notifications/[publicId]`, `/admin/announcements`, `/admin/announcements/[publicId]`, `/admin/support-tickets`, `/admin/support-tickets/[publicId]` | `PLATFORM_ADMIN`, `HOST_ADMIN` | Notifications/support |
| Content/authoring | `/admin/questions`, `/admin/questions/new`, `/admin/questions/[publicId]`, `/admin/questions/[publicId]/edit`, `/admin/question-types`, `/admin/exam-template`, `/admin/exam-template/[publicId]`, `/admin/exam-template/[publicId]/edit`, `/admin/score-template`, `/admin/score-template/[publicId]`, `/admin/score-template/[publicId]/edit` | `PLATFORM_ADMIN`, `HOST_ADMIN` | Question bank/templates |

## Tenant web

| Route group | Routes | Primary actor | Owner |
|---|---|---|---|
| Public/auth | `/`, `/login`, `/register` | Anonymous | Public/auth |
| Host operations | `/host/dashboard`, `/host/students`, `/host/exam-staff`, `/host/programs`, `/host/programs/[publicId]`, `/host/programs/[publicId]/classes/[classPublicId]`, `/host/classes`, `/host/roster` | `HOST_ADMIN` | Host operations |
| Host finance/data | `/host/billing`, `/host/subscriptions`, `/host/checkout`, `/host/orders`, `/host/payment-status`, `/host/quota`, `/host/redeem-license`, `/host/audit-log` | `HOST_ADMIN` | Commercial/audit |
| Host exam/support | `/host/exams`, `/host/exams/[publicId]`, `/host/notifications`, `/host/notifications/[publicId]`, `/host/support-tickets`, `/host/support-tickets/[publicId]` | `HOST_ADMIN`, `EXAMINER`, `PROCTOR` | Exam operations/support |
| Role surfaces | `/examiner/work`, `/student/results` | `EXAMINER`, `STUDENT` | Examiner/student |

## Matrix columns maintained during later phases

Every route row is extended with: role gate, visible navigation, feature view,
shared primitives, locale coverage, theme coverage, 320/390px status, density
classification, failure-state owner, and behavior-manifest reference.
