# PTE Prep Status and Evidence Matrix

**Purpose:** keep the English Report 3–6 set honest about what is implemented, partly implemented, planned, outside scope, or still undecided.

## Status definitions

| Status | Meaning in this report set | Evidence that may support the label | Wording rule |
|---|---|---|---|
| **Current** | The behavior is available in the reviewed product baseline and is supported by a source, configuration, verified interface, or executed result. | Source code/configuration plus a reproducible route, client behavior, API contract, or dated test/operation result. | Use present tense. Name the evidence record and verification date. |
| **Partial** | A real slice exists, but the complete user journey, safeguard, channel, or integration is not yet supported. | At least one implementation/configuration/UI/API slice, plus a clear missing slice. A plan or ADR alone is not enough. | Say what works and what remains. Do not describe the whole feature as available. |
| **Planned/Future** | An approved direction or design exists, but the reviewed baseline does not provide implementation evidence. | Approved SRS, plan, ADR, or backlog item. | Use future or planned language. Do not turn the design into a current user instruction. |
| **Out of scope** | The capability is deliberately excluded from the current PTE Prep boundary. | Approved scope or out-of-scope decision. | State the boundary and point to the requirement or decision. |
| **TBD** | A decision, evidence item, contract detail, or acceptance rule is still required. | An open decision record with owner, impact, due point, and affected IDs. | Explain the current safe assumption and the decision needed. |

## Evidence record minimum

Every material status claim in Reports 3–6 uses an `EVD-*` record. Each record contains:

1. a stable ID;
2. the status being supported;
3. a source path, route, configuration key, test result, plan, ADR, or decision;
4. verification date;
5. related actor, feature, and report section;
6. owner or reviewer;
7. limitations and missing evidence.

The evidence catalog is a map, not a substitute for the source. A reviewer should be able to follow the path and understand why the status was assigned.

## Evidence-to-status rules

| Claim pattern | Allowed status | Not sufficient by itself |
|---|---|---|
| Existing controller, service, route, screen, or client behavior is observed | Current or Partial | A filename without a route or behavior description |
| An approved design/implementation plan describes a future slice | Planned/Future | Calling it Current because a plan is detailed |
| A feature has an implemented slice but a required end-to-end step is missing | Partial | Marking it Current because one API succeeds |
| A product boundary intentionally excludes a capability | Out of scope | Treating the exclusion as a backlog commitment |
| Retention period, provider threshold, or recovery rule is not agreed | TBD | Choosing a number without owner approval |
| Numeric NFR target appears in the SRS | Target/baseline only | Presenting it as a measured result without `TEST-*` evidence |

## Review checklist

- Does the sentence use the exact status vocabulary?
- Is an `EVD-*` record linked close to the claim?
- If status is **Partial**, does the evidence include an implemented slice and the missing slice?
- If status is **Current**, can a reviewer reproduce it from the cited source or result?
- If status is **Planned/Future** or **TBD**, is the owner and impact visible?
- Are target numbers clearly labelled as targets, baselines, or acceptance thresholds?

