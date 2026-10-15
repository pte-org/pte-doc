# Plan review: Quang platform-user CRUD

Review mode: manual red-team fallback for `ck:plan --hard`  
Date: 2026-10-15  
Native `plan-reviewer` agent: unavailable in this session; findings below were
checked against the workspace reviewer checklist.

## [HIGH]: Archive must revoke every authentication path

Category: Failure / Security  
Location: Phase 2, archive and token invalidation  
Issue: Soft-delete alone would not be sufficient if password login or refresh
does not check the deleted flag, or if existing refresh sessions remain valid.  
Fix: Require both login and refresh guards, target-wide refresh invalidation and
tests before marking archive complete.  
Verdict: ACCEPTED

## [HIGH]: Self/admin protection must be repeated in every mutation

Category: Security  
Location: Permission matrix and Phase 2  
Issue: Frontend disabled state cannot protect an administrator from a crafted
request or a stale row.  
Fix: Lock and authorize the target in each backend write and cover direct API
deny cases.  
Verdict: ACCEPTED

## [HIGH]: Email mutation can split login identity

Category: Assumption  
Location: Product decisions and profile contract  
Issue: The current platform username is tied to email; allowing a simple profile
email edit could update display data without updating the login key.  
Fix: Keep email/username immutable in V1 and require a separate verified identity
change flow later.  
Verdict: ACCEPTED

## [MEDIUM]: Existing functionality could be duplicated

Category: Scope  
Location: Overview and research summary  
Issue: Rebuilding list/create/role/suspend/reactivate would duplicate the earlier
platform-role implementation.  
Fix: Preserve the current contract and scope new work to missing lifecycle,
auth-guard and UX behavior.  
Verdict: ACCEPTED

## [MEDIUM]: Runtime evidence can be overstated

Category: Quality Gate  
Location: Phase 4  
Issue: Static checks cannot prove live role authorization, refresh invalidation or
browser action behavior.  
Fix: Report static, local HTTP/browser and production evidence as separate
boundaries; do not mark unavailable runtime checks as passed.  
Verdict: ACCEPTED

## Review Summary

| Category | Findings | ACCEPTED | NOTED |
|---|---:|---:|---:|
| Security | 2 | 2 | 0 |
| Assumption | 1 | 1 | 0 |
| Failure | 1 | 1 | 0 |
| Scope | 1 | 1 | 0 |
| Quality Gate | 1 | 1 | 0 |

Verdict: WARN — no unresolved critical finding; product decisions in the plan
must be answered before cook.
