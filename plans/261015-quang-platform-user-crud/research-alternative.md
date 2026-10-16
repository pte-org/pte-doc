# Research B: Reuse the generic tenant-user lifecycle

## Verdict

Rejected for this scope.

## Findings

- Generic user routes are tenant-scoped or use tenant-role management rules.
- Their target policy is designed for Host-created students/exam staff, not
  tenantless platform accounts.
- Reusing those routes would require broadening controller guards and role
  predicates, increasing the risk of cross-scope access and IDOR.
- Password/profile helper code may be reused only after the platform target policy
  is evaluated separately.

## Tradeoff

Reuse would reduce endpoint count, but the authorization contract would become
ambiguous and harder to audit. The apparent code reduction is not worth the scope
and security risk.

## Recommendation

Keep the resource boundary dedicated. Share only neutral primitives such as safe
password handling, response mapping and audit conventions where their existing
contracts allow it.
