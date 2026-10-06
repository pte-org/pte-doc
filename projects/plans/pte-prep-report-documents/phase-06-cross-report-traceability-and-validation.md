# Phase 06 — Cross-report review and validation

## Objective

Review the completed English Report 3–6 Markdown set as one documentation system. Verify that the original DOCX structure, PTE Prep scope, actor model, IDs, status labels, assets, links, evidence claims, and high-risk vertical flows remain consistent across requirements, design, tests, and user guides.

## Inputs / Outputs

### Inputs

- All outputs from Phases 01–05.
- Original Report 3–6 DOCX files.
- Approved PTE Prep SRS/brainstorm and referenced plans/ADRs.
- Relevant current source/configuration/UI/API evidence used by the reports.

### Outputs

- `pte-doc/report/_validation/report-03-06-validation.md` containing the cross-report traceability matrix and gate results.
- Section-map validation result.
- ID/reference/link validation result.
- UTF-8, placeholder, secret, scope, and status validation result.
- Vertical-flow review notes for onboarding, exam preparation/generation, delivery/proctoring, and scoring/publication.
- Findings list with severity, affected file/ID, evidence, and recommended correction.
- Final handoff note for `/ck:cook` completion or a follow-up correction phase.

## Dependencies

- Reports 3–6 must exist in the canonical output root.
- All report and asset names should be stable before the final link scan.
- Validation findings may require returning to an earlier phase; do not waive a broken scope/traceability gate silently.

## Detailed Steps

1. Compare the original DOCX document-level and child headings with the report-to-file map and generated files. Confirm every section appears once, in order, including one `00-project-report.md` per report, without altering source DOCX.
2. Read all Markdown explicitly as UTF-8 and reject invalid bytes, U+FFFD replacement characters in final headings/content, suspicious mojibake, malformed headings, and broken tables. The only permitted replacement character is inside the documented raw-source heading field of `_foundation/section-map.md`; normalized headings and all report prose must be clean. Confirm raw malformed DOCX headings are retained only in that field with normalized headings and reasons.
3. Scan all report files for generic template tokens and sample-domain prose, including `[Project name]`, `[Describe ...]`, `<<...>>`, “insert diagram”, “Cafeteria”, “Patron”, and unrelated sample roles. Review remaining `TBD` entries for owner, impact, and decision/evidence description.
4. Collect all stable IDs and detect duplicates. Resolve every internal ID reference or classify it as an intentional external/TBD reference with explanation. Confirm material status claims reference `EVD-*` records containing source, date, owner, related scope, and limitations.
5. Resolve every relative Markdown/asset link. Check that every report has a mandatory `assets/` directory and every asset has ID, caption, status, source/evidence note, and related requirement IDs (or a manifest/TBD explanation when no binary evidence exists).
6. Verify scope vocabulary:
   - product name PTE Prep;
   - independent practice/mock-exam disclaimer;
   - exactly six human roles plus External Integration Services;
   - no Lecturer/Program Coordinator/Tenant Owner/extra Applicant role;
   - organization registration separate from package/payment activation;
   - Windows-first delivery;
   - Report 7/Vietnamese copies deferred;
   - research-based learning, official certification, and unsupported anti-cheat excluded.
7. Verify status/evidence discipline. Flag Current claims without source/config/UI/API/test evidence and numeric NFR values without target/baseline language.
8. Review the four vertical flows across Reports 3–6:
   - **Onboarding:** registration → Platform Admin review → organization/Host activation → login/package readiness.
   - **Exam preparation:** content/media/Score Template → Host exam draft → Student selection/conflicts/capacity → validation → fixed form/version → schedule/publish.
   - **Delivery/proctoring:** Student device check → timed tasks → local save/outbox → synchronization/retry → Proctor monitoring/violation/audit → final submission.
   - **Scoring/publication:** objective/AI/Examiner sources → Examiner assignment/marking → Host score-source review → report readiness → publication → Student visibility/audit.
9. For each flow, record requirement IDs, design/sequence IDs, test cases, user workflows, status, missing links, and contradictions.
10. Check retention and provider decisions: contract-based retention remains TBD; payment/media/AI/notification behavior includes failure/retry/idempotency boundaries; no unsupported quality guarantee appears.
11. Search for credentials, tokens, private-key markers, real `.env` values, unmasked production data, and unsafe URLs. Remove or replace any finding before handoff.
12. Produce a concise validation report with PASS/WARN/BLOCK per gate. A BLOCK finding must be corrected before the plan is considered ready for cook completion.

## Acceptance Criteria

- [ ] `pte-doc/report/_validation/report-03-06-validation.md` exists and records evidence, gates, findings, and corrections.
- [ ] Every original DOCX Report 3–6 document-level and child section is represented exactly once and in order, including all `00-project-report.md` files.
- [ ] All Markdown and assets are valid UTF-8 with no replacement characters or suspicious encoding artifacts.
- [ ] Generic template/sample-domain content and unsupported current claims are removed or explicitly marked TBD/Planned/Future.
- [ ] ID uniqueness and reference scans pass; cross-report links resolve; material status claims cite `EVD-*` records.
- [ ] All four mandatory asset directories, asset metadata, and relative links pass.
- [ ] Product, role, scope, channel, retention, and PTE Academic boundary checks pass.
- [ ] Every major requirement has design/test/guide coverage or an explicit documented dependency/TBD.
- [ ] The four vertical-flow reviews have no unresolved high-severity contradiction.
- [ ] No secrets or unmasked sensitive production data are present.
- [ ] Validation output records evidence, findings, corrections, and remaining low-severity warnings.

## Design Constraints

- Preflight: Read the completed Reports 3?6, the foundation ledgers, original DOCX section map, and all phase test outputs. Conventions carried forward are UTF-8-only final Markdown, explicit evidence limitations, no generic sample content, and one canonical ID meaning across reports. This phase writes only `pte-doc/report/_validation/` plus declared plan/test receipts.

- This phase reviews and corrects documentation; it does not change product code or original DOCX files.
- A validation warning cannot be “fixed” by changing a Current label to hide missing evidence; use Partial/Planned/Future/TBD with an explanation.
- Numeric NFR targets remain targets until an actual test/operations result exists.
- Cross-report consistency must not erase legitimate differences in audience: SRS business requirements, design implementation intent, test evidence, and user procedures.
- Report 7 and Vietnamese files remain out of scope.

## Quality and Testing State

- **Quality:** Not evaluated.
- **Testing:** Not started.
- **Planned checks:** section map, UTF-8, headings/tables, placeholder/sample-domain, ID/reference, relative links/assets, scope/role/status, secret scan, vertical-flow traceability.
- **Product runtime tests:** Not required; this phase validates documentation artifacts and evidence claims.

## Risks / Notes

- A clean structural scan does not prove that a Current claim is true; manual evidence review remains required.
- Cross-report duplication can hide contradictions; prefer one canonical requirement definition and links.
- Screenshots and UI labels may become stale; record capture/source dates and status.
- If a BLOCK finding changes Report 3 IDs or scope, repeat the affected downstream phase checks.

## Spec / User Story Mapping

- Spec: FR-01, FR-02, FR-03, FR-14, FR-15, FR-16, FR-17; NFR-02, NFR-03, NFR-05, NFR-06, NFR-07, NFR-10, NFR-12, NFR-13, NFR-18, NFR-19; SC-01 through SC-11.
- User stories: P1 reviewer structure/traceability; P1 tester coverage; P1 operator workflow consistency; P1 project owner status/scope confidence.


## Execution Notes

- Status: completed for cook Phase 06.
- RED/GREEN: `python tests/test_phase06_validation.py` initially failed because the final validation report was absent; after implementation it returned `GREEN/PASSED`.
- Build Gate: Python syntax compilation passed for the final validator/test scripts.
- Testing: passed under TDD verify; result at `tests/results/phase-06-cross-report-traceability-and-validation-test-report.json`.
- Quality: approved; report at `quality/phase-06-cross-report-traceability-and-validation-quality-report.json`.
- Outputs: cross-report validation, section/order gate, scope/role/status review, four vertical-flow matrices, safety review, and handoff note.
