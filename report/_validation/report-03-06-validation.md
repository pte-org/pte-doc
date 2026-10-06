# Reports 3–6 Cross-Report Validation

**Product:** PTE Prep  
**Validation date:** 2026-10-06  
**Scope:** English Markdown Reports 3–6 under `pte-doc/report/`  
**Owner:** Ngô Đăng Quang — Project Leader  
**Method:** section-map comparison, UTF-8/placeholder/secret scan, ID/reference/link scan, role/scope/status review, asset-directory review, and vertical-flow traceability review.

## 1. Gate summary

| Gate | Result | Evidence |
|---|---|---|
| DOCX section structure and order | **PASS** | `_foundation/section-map.md`; 22 expected report files plus four covers/changes and four mandatory asset directories. |
| Canonical product and scope | **PASS** | Report 3 overview/appendix; Report 4 design boundary; Report 5 scope; Report 6 package boundary. |
| Actor model | **PASS** | Exactly Platform Admin, Platform Author, Host, Proctor, Examiner, Student, and External Integration Services. Explicit exclusions are recorded as exclusions, not actors. |
| Encoding and placeholder scan | **PASS** | All final Markdown reads as UTF-8; no replacement character in final report prose; generic template tokens absent. |
| Identifier and reference scan | **PASS** | Cross-report prefixes and requirement links are present; foundation ledger owns namespace rules. |
| Relative links and assets | **PASS** | Structural validator resolved all Markdown links; each report has `assets/README.md`. |
| Status/evidence honesty | **PASS** | Evidence matrix and `EVD-*` catalog are used; numeric NFRs are targets/baselines; unverified behavior is Partial/Planned/Future/TBD. |
| Secrets and sensitive data | **PASS** | No credentials, tokens, private keys, `.env` values, or unmasked production data were added. |
| Vertical-flow consistency | **PASS with low notes** | Four flow reviews below; remaining items are named TBD decisions, not hidden contradictions. |

**Gate counts:** `PASS: 9` · `WARN: 0` · `BLOCK: 0`  
**Overall verdict:** **PASS — documentation bundle is ready for review/handoff.**

## 2. Section and file validation

The original DOCX document-level sections map as follows:

| Report | Required order | Result |
|---|---|---|
| Report 3 | Record of Changes → Software Requirement Specification → Product Overview → User Requirements → Functional Requirements → Non-Functional Requirements → Requirement Appendix | PASS |
| Report 4 | Record of Changes → Software Design Document → System Design → Database Design → Detailed Design | PASS |
| Report 5 | Record of Changes → Testing Documentation → Scope of Testing → Test Strategy → Test Plan → Test Cases → Test Reports | PASS |
| Report 6 | Record of Changes → Release Package & User Guides → Deliverable Package → Installation Guides → User Manual | PASS |

Each `II.` document-level heading is represented by a `00-project-report.md` file. Each `I. Record of Changes` heading is represented by a `00-record-of-changes.md` file. Nested DOCX headings remain inside their mapped parent file. Original DOCX/template files were not modified by this work package.

## 3. Structural and encoding evidence

- Final bundle validator: `python pte-doc/projects/plans/pte-prep-report-documents/tests/validate_report_bundle.py` → `GREEN/PASSED`; 31 Markdown files validated.
- Phase 01 TDD result: [`phase-01-documentation-foundation-and-section-map-test-report.json`](../../projects/plans/pte-prep-report-documents/tests/results/phase-01-documentation-foundation-and-section-map-test-report.json).
- Phase 02 TDD result: [`phase-02-report-03-srs-test-report.json`](../../projects/plans/pte-prep-report-documents/tests/results/phase-02-report-03-srs-test-report.json).
- Phase 03 TDD result: [`phase-03-report-04-design-test-report.json`](../../projects/plans/pte-prep-report-documents/tests/results/phase-03-report-04-design-test-report.json).
- Phase 04 TDD result: [`phase-04-report-05-testing-test-report.json`](../../projects/plans/pte-prep-report-documents/tests/results/phase-04-report-05-testing-test-report.json).
- Phase 05 TDD result: [`phase-05-report-06-user-guides-test-report.json`](../../projects/plans/pte-prep-report-documents/tests/results/phase-05-report-06-user-guides-test-report.json).
- Phase 06 TDD result is created after this report and confirms this file exists and all gates pass.
- The only source-extraction normalization is documented in `_foundation/section-map.md`; no replacement character appears in final report prose.
- The complete task catalog has exactly 23 rows: 22 scored task types plus unscored Personal Introduction.

## 4. Scope and role consistency

| Scope rule | Report 3 | Report 4 | Report 5 | Report 6 | Result |
|---|---|---|---|---|---|
| Product named PTE Prep | Yes | Yes | Yes | Yes | PASS |
| Independent from PTE Academic | Yes | Linked boundary | Explicit test boundary | Explicit guide boundary | PASS |
| Organization-first package model | Yes | Billing boundary | Package/callback cases | Separate activation steps | PASS |
| Windows-first delivery | Yes | Client boundary | Compatibility/device cases | Client prerequisites/checks | PASS |
| Six human roles + integration actor | Yes | Package/visibility matrix | Test responsibilities kept distinct | Six workflows + integration boundary | PASS |
| Student self-payment excluded | Yes | Billing ownership | Out of scope | Package guide | PASS |
| Advanced anti-cheat excluded/deferred | Yes | Policy boundary | Test out-of-scope | Guide does not promise it | PASS |
| Contract-based retention/TBD | Yes | Data lifecycle | Data test objective | Installation/support boundary | PASS |

## 5. Identifier and traceability review

| Traceability chain | Coverage |
|---|---|
| `FR-*` → `UC-*`/`BR-*` → `SD-*`/`DB-*`/`SEQ-*` | Report 3 defines functional requirements/use cases/rules; Report 4 links the core flows and invariants. |
| `NFR-*` → `OBJ-*`/`TC-*` | Report 3 defines target/baseline quality requirements; Report 5 maps performance, security, recovery, compatibility, and integration objectives/cases. |
| `FR/BR/SD/DB/SEQ` → `WF-*`/`STEP-*`/`IMG-*` | Report 6 role workflows and installation steps link back to the requirement/design/test baseline; unavailable screenshots are `TBD` assets. |
| `EVD-*` → status claims | Foundation catalog contains source, date, owner, related scope, and limitation; reports preserve the limitation. |

The ID ledger at [`_foundation/id-ledger.md`](../_foundation/id-ledger.md) defines allocation and no-reuse rules. IDs are not independently renumbered in downstream reports.

## 6. Vertical-flow review

### 6.1 Organization onboarding

| Stage | Report 3 | Report 4 | Report 5 | Report 6 | Finding |
|---|---|---|---|---|---|
| Registration | `UC-ONBOARD-001`, `FR-ONBOARD-001` | `SEQ-ONBOARD-001` | `TC-ACCESS-001` | `WF-ADMIN-ONBOARD-001` | PASS |
| Platform Admin decision | `FR-ONBOARD-002` | Tenancy/identity ownership | `TC-ACCESS-002` | Admin workflow | PASS |
| Organization/Host creation | `FR-ONBOARD-003` | Idempotent materialization | `TC-ACCESS-002` | Result/visibility | PASS |
| Package readiness | `UC-PACKAGE-001`, `FR-PACKAGE-*` | Billing boundary | `TC-PACKAGE-001/002` | `WF-HOST-PACKAGE-001` | PASS; payment is separate from registration |

### 6.2 Exam preparation and generation

| Stage | Report 3 | Report 4 | Report 5 | Report 6 | Finding |
|---|---|---|---|---|---|
| Content/media/template | `FR-CONTENT-*`, `FR-TEMPLATE-*` | `SEQ-CONTENT-001`, package ownership | `TC-CONTENT-001/002` | Author/Admin workflows | PASS |
| Candidate selection | `FR-ENROLL-*` | Candidate snapshot entity | `TC-ROSTER-001`, `TC-EXAM-001` | Host roster/exam workflow | PASS |
| Validation | `FR-EXAM-003`, `BR-EXAM-023` | Validation contract | `TC-PACKAGE-001`, `TC-EXAM-001` | Host correction path | PASS |
| Fixed version/form | `FR-EXAM-004/005/009` | `SEQ-EXAM-001`, `DB-INV-001/002/003` | `TC-CONTENT-002`, `TC-EXAM-002/003` | Host generation/recovery | PASS; exact recovery remains `TBD-GENERATION-001`/`TBD-VERSION-001` |

### 6.3 Delivery and Proctoring

| Stage | Report 3 | Report 4 | Report 5 | Report 6 | Finding |
|---|---|---|---|---|---|
| Eligibility/device check | `FR-DELIVERY-001/002` | Attempt/client boundary | `TC-DELIVERY-001/002` | Student prerequisite/check workflow | PASS |
| Timed task/local save | `FR-DELIVERY-003/004/005` | `SEQ-ANSWER-SYNC`, `DB-INV-005/006` | `TC-DELIVERY-003` | `WF-STUDENT-TAKE-001` | PASS; client matrix remains TBD |
| Sync/retry/submit | `FR-DELIVERY-006/007/008` | Idempotency/error table | `TC-DELIVERY-004/005` | Offline recovery FAQ | PASS |
| Monitor/violation | `FR-INTEGRITY-*` | `SEQ-PROCTOR-AUDIT` | `TC-PROCTOR-001` | `WF-PROCTOR-MONITOR-001` | PASS; exact violation sync remains `TBD-PROCTOR-001` |

### 6.4 Scoring and publication

| Stage | Report 3 | Report 4 | Report 5 | Report 6 | Finding |
|---|---|---|---|---|---|
| Objective/AI/Examiner sources | `FR-SCORE-001`–`FR-SCORE-004` | `PKG-SCORING`, source separation | `TC-SCORE-001/002` | Examiner/Host procedures | PASS; AI provider policy TBD |
| Host source selection | `FR-SCORE-005` | `SEQ-SCORE-PUBLISH-001` | `TC-SCORE-002/003` | `WF-HOST-PUBLISH-REPORT` | PASS |
| Readiness/publication gate | `FR-SCORE-006`, `FR-REPORT-002/003` | Publication gate/`DB-INV-008` | `TC-SCORE-003`, `TC-REPORT-001` | Host/Student workflows | PASS |
| Student visibility/audit | `FR-REPORT-004/005` | Audit/publication ownership | Tenant/visibility cases | Result view/support | PASS |

## 7. Status, evidence, and open decisions

The following remain intentionally open and are not validation failures:

- `TBD-RETENTION-001`: exact contract period and deletion/export/legal hold;
- `TBD-AI-001`/`TBD-AI-002`: provider, thresholds, timeout/fallback, and task-level review;
- `TBD-PROCTOR-001`: exact violation synchronization/recovery;
- `TBD-GENERATION-001`: generation recovery/idempotency state machine;
- `TBD-VERSION-001`: audience snapshot and shared/unique form policy approval;
- `TBD-CLIENT-001`: Windows/browser/audio/microphone/device matrix;
- `TBD-DATA-001`: jurisdiction and data-protection decision.

These items have owner/impact/resolution evidence in [`_foundation/tbd-register.md`](../_foundation/tbd-register.md). A later decision must update the affected report, ID ledger, test cases, and this validation report together.

## 8. Safety review

- No credentials, tokens, private keys, real `.env` values, provider secrets, or unmasked production data were added.
- Installation/support guidance uses placeholders and an approved secret process.
- Screenshot/diagram assets are masked/TBD; no fabricated current UI evidence is presented.
- Internal application/database/queue ports are described as deployment boundaries, not user-facing instructions.
- Numeric NFR values are labelled targets/baselines; no product runtime pass is claimed by the documentation tests.

## 9. Handoff

The English Report 3–6 Markdown set is structurally complete for the approved scope and ready for reviewer feedback. Future changes should:

1. update Report 3 first when scope/IDs change;
2. update downstream design/test/guide links in the same change;
3. run the full validator and phase-specific TDD checks;
4. record new evidence or keep the claim Partial/Planned/Future/TBD;
5. preserve the original DOCX and generic templates.

