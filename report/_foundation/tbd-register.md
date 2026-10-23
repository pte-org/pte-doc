# PTEPrep Open and TBD Register

These items are deliberately visible. They must not be hidden by writing a precise-looking value into a requirement, design, test result, or user instruction.

| ID | Open decision or missing evidence | Safe interim statement | Owner / decision area | Impacted reports and IDs | Resolution evidence needed |
|---|---|---|---|---|---|
| `TBD-RETENTION-001` | Exact retention period and deletion process for attempts, scores, and audit logs | Retention follows the contract with each organization; the exact period and deletion workflow are not fixed in this report set. | Product owner + organization contract owner | Reports 3–6; `NFR-DATA-001`, `BR-REPORT-006` | Approved policy and deletion/audit evidence |
| `TBD-AI-001` | AI provider, supported task types, quality threshold, timeout, and fallback | AI scoring is an integration boundary. A pending or failed provider result must remain visible; no quality guarantee is claimed. | Platform Admin + scoring owner | Reports 3–5; `FR-SCORE-006`, `NFR-INT-002` | Provider contract, adapter behavior, and measured acceptance results |
| `TBD-AI-002` | Whether an AI score requires Examiner review for each task type | Report 3 defines Host score-source review and keeps unresolved task-level policy visible. | Scoring policy owner | Reports 3–6; `BR-SCORE-004` | Approved rubric and workflow evidence |
| `TBD-PROCTOR-001` | Exact synchronization behavior for violation events during a connectivity interruption | The Proctor workspace must show pending/error state and preserve a retryable record; exact delivery timing is not promised. | Integrity policy owner | Reports 3–5; `FR-INTEGRITY-004`, `SEQ-PROCTOR-AUDIT` | Client/API event contract and recovery test |
| `TBD-GENERATION-001` | Recovery and idempotency behavior when form generation stops halfway | The exam remains a draft or generation-error state until a safe retry or cancellation is completed; no partial form is published. | Exam workflow owner | Reports 3–5; `FR-EXAM-006`, `BR-EXAM-012` | State transition and duplicate-generation test evidence |
| `TBD-VERSION-001` | Audience snapshot and per-Student form policy for every exam mode | The selected mode is recorded before delivery and the generated content is treated as a fixed version. | Host product owner | Reports 3–5; `FR-EXAM-007`, `DB-EXAM-VERSION` | Approved mode matrix and generation records |
| `TBD-CLIENT-001` | Complete exam-client device matrix and minimum microphone/audio/network configuration | Windows-first delivery is the baseline; unsupported or failed device checks block or clearly warn before timed work. | Exam client owner | Reports 3–6; `NFR-COMPAT-001`, `WF-STUDENT-DEVICE-CHECK` | Supported-device matrix and client verification |
| `TBD-DATA-001` | Applicable jurisdiction, privacy notice, export/delete rights, and data residency | Reports describe tenant isolation and safe handling without asserting legal compliance for an unconfirmed jurisdiction. | Platform Admin + privacy owner | Reports 3–6; `NFR-SEC-004`, `NFR-DATA-002` | Approved privacy/legal decision and operational controls |

## Decision handling rules

- A TBD entry stays open until the owner supplies a decision or reproducible evidence.
- Resolving a TBD requires updating the ledger, the affected report sections, and the cross-report validation report in one change.
- A test case may verify that a TBD-safe behavior is visible, but it must not invent the final policy.
- User guides may give an escalation instruction for a TBD item; they must not present it as a guaranteed product behavior.



## Scope revision decisions

| ID | Decision | Safe interim statement | Affected artifacts |
|---|---|---|---|
| `TBD-D01-TASK-CATALOG` | RESOLVED by user, 2026-10-22: existing Academic task families; no separate Core expansion | Verify each task's actual content/media/runtime readiness; the scope decision does not prove availability | Reports 3-6, task catalog, `FR-PRACTICE-003` |
| `TBD-D02-IDENTITY-CONTEXT` | RESOLVED by user, 2026-10-22: verified email identity with explicit choice among authorized organization memberships | Membership and Student data remain organization-scoped; verification alone does not grant membership or merge profiles | Reports 3-6, `FR-PRACTICE-002`, `DB-PRACTICE-SESSION` |
| `TBD-D03-STUDY-PACK` | RESOLVED by user, 2026-10-22: quick grouped practice with real task filters | No ordered curated-pack domain, separate pack completion or LMS in this scope | Reports 3-6, `FR-PRACTICE-003`, `FR-PRACTICE-008` |
| `TBD-FEEDBACK-001` | Who may report a question/content/lesson issue, target object, handler and response visibility | Existing Host support tickets do not automatically cover Student content feedback | Reports 3-6, `FR-PRACTICE-009` |
| `TBD-AI-POLICY-001` | PARTIALLY RESOLVED: Gemini; Vietnamese default with English option; rubric feedback before calibrated AI numeric scores, confirmed 2026-10-22. Academic rubric approval, task evidence, quality thresholds, budget/timeouts/retry remain to close | Preserve answers independently of AI state; persist language variants; do not treat confirmation as quality/runtime evidence | Reports 3-6, `FR-PRACTICE-007`, `NFR-AI-001` |
| `TBD-RETENTION-002` | Contract-specific retention, export, deletion and legal hold for attempts, scores, media and audit | Retention follows the organization contract until a detailed policy is approved | Reports 3-6, `NFR-DATA-001` |

Resolution source: [user-confirmed Practice decisions](../../projects/plans/quang-pte-practice-completion/decisions.md). Keep resolved IDs for historical traceability; do not reopen D01–D03 or count them as outstanding decisions. Confirmation does not constitute supervisor approval or executed tests.
