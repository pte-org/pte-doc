# Plan: PTEPrep Report 3–6 scope update

Date: 22 October 2026
Mode: Hard
Test mode: Default; no `--tdd` requested or inherited.
Status: **In progress — Phases 01–06 drafted; DOCX publication remains pending. D01–D03 are still pending for dependent finalization.**
Spec: [spec.md](spec.md)
Canonical output: `pte-doc/report/`

## Immediate work package — sửa báo cáo trước

**User direction confirmed on 22 October 2026:** prepare the documentation plan first and revise Reports 3–6 before revising practice application code. The plan was prepared first; Phases 01–06 have now drafted the foundation and Reports 3–6. Business recommendations D01–D03 remain pending and are not implicitly accepted by this sequencing instruction.

The first reviewable output during execution is the revised English Report 3 and shared foundation. Continue with Reports 4–6 derived from that requirement baseline, then perform cross-report review. Word publication follows stable Markdown content. Application implementation begins in a separate later work package using the report requirements and gap handoff.

### Nội dung cần sửa theo báo cáo

| Hạng mục | Kết quả cần có |
|---|---|
| Foundation | Tám role, các kênh sử dụng, thuật ngữ, danh mục yêu cầu và các quyết định còn mở thống nhất. |
| Report 3 — SRS | Yêu cầu chi tiết của role mới, Student practice, AI giải thích, Progress và hai flag câu hỏi; quy tắc tự chọn câu theo kênh; luồng chính, ngoại lệ và tiêu chí chấp nhận. |
| Report 4 — Design | Kiến trúc, ERD, ma trận quyền và sequence/state diagrams bám theo SRS; phân biệt thiết kế hiện có và thiết kế cần triển khai. |
| Report 5 — Testing | Kế hoạch và test case cho phạm vi mới, gồm lọc câu theo flag, AI lỗi/chờ/thử lại và ranh giới dữ liệu; ghi đúng trạng thái chưa thực thi. |
| Report 6 — Guides | Hướng dẫn theo role và hai hành trình Student; mô tả chức năng dự kiến rõ ràng khi code chưa đáp ứng. |
| Đối chiếu cuối | Các report không mâu thuẫn; mã yêu cầu, hình, bảng và liên kết nhất quán; danh sách công việc code sau có căn cứ từ report. |
| Word | Xuất bốn DOCX sau khi nội dung Markdown ổn định; giữ mục lục mẫu, logo trường, tên đề tài và style. |

### Execution checklist

- [x] Phase 01: shared foundation and decision tracking. Drafted 2026-10-22.
- [x] Phase 02: detailed Report 3 revision — first substantive review checkpoint. Drafted 2026-10-22.
- [x] Phase 03: Report 4 design and diagrams. Drafted 2026-10-22.
- [x] Phase 04: Report 5 test documentation. Drafted 2026-10-22.
- [x] Phase 05: Report 6 user and installation guides. Drafted 2026-10-22.
- [x] Phase 06: cross-report validation and later implementation gap handoff. Drafted 2026-10-22; product/runtime checks remain separate.
- [ ] Phase 07: Word export and visual inspection.

Application code, database migrations, runtime role policies, practice feature implementation and production changes are outside this checklist. Documentation-tool changes, if necessary for validation/export, occur only in their designated later phases and do not become prerequisites for starting report prose.

## Scope challenge

| Check | Finding |
|---|---|
| Exists? | Reports and Word exports exist; six-role baseline and missing practice scope are stale. |
| Minimum? | Revise existing foundation and Report 3–6 in place, propagate diagrams/traces, validate/export and hand off gaps. |
| Complexity? | Hard: four reports, new role responsibilities, practice lifecycle, scope decisions and Word publication. |
| Scope limit | Documentation and its tooling only during later execution. Practice product code follows a separate plan. |

## Governing baseline and supersession

This new plan governs the next active report revision. It supersedes the old plan's six-human-role, Platform Author, three-channel and fixed 23-task constraints only for the active revision where changed by an accepted scope decision. Fixed task-count rules are replaced by the chosen version/channel catalog, never silently removed as a validation shortcut.

Keep `projects/plans/quang-pte-prep-report-documents/`, its completed status, tests, quality receipts and `report/_validation/` historical. Do not reuse their GREEN/APPROVED receipts as validation of this revision. Keep canonical report paths and supplied original DOCX unchanged. Mark previous exports stale when Markdown revision starts; acceptance requires new inspected exports.

Full registered title: **PTEPrep: An AI-Powered PTE Practice Platform and Realistic Exam Simulator**.
English report content; Vietnamese planning is permitted. No word limit; every material flow gets project-specific detail and rejection/recovery cases.

### Confirmed clarification: question usage flags

On 22 October 2026 the user confirmed separate question flags for Practice Web and Windows Exam Client, with automatic question selection by the appropriate flag (D04 in spec). This is a question-pool rule, independent of the pending D01 Academic/Core task-family choice. Academic authoring/review, selection filters, generation failures, frozen content, diagrams, tests and guides must all cover it. Flags supplement publication/content readiness and access checks; they never authorize cross-channel fallback. Default values, legacy data migration and both-enabled reuse policy are not silently decided by this clarification.

## Inputs and research synthesis

Prior discovery: `pte-doc/projects/plans/reports/261007-quang-pte-practice-student-web-brainstorm.md`, `pte-doc/plans/reports/261008-platform-role-expansion-brainstorm.md`, `pte-doc/projects/pte-org-srs/brainstorm.md` and `pte-doc/projects/plans/quang-pte-practice-student-web/spec.md` provide inherited discovery context; apply only decisions still consistent with latest instructions. The original report plan references a 261006 brainstorm not found in this workspace; do not imply that missing file was read. Current scope audit/research supplements these rather than silently inheriting outdated roles.

- [Current scope review](../../../plans/reports/261022-pte-prep-current-scope-review.md).
- [Primary research](../../../plans/reports/261022-pte-prep-report-scope-primary-research.md).
- [Alternative research](../../../plans/reports/261022-pte-prep-report-scope-alternative-research.md).
- Latest registration v1.2, original Report3–6 DOCX, current foundation/reports.
- Existing `pte-doc/tools/generate_report_docx.py` and `pte-doc/report/docx/README.md`.

Research recommends in-place revision, stable IDs, explicit source/proposal distinction and a successor validation policy. Existing source supports eight canonical roles and practice lifecycle slices but does not establish finished AI explanations. Existing generator preserves shell/logo but hardcodes old metadata and can fall back to diagram source text.

## Execution sequence

| Phase | File | Main result | Stories |
|---|---|---|---|
| 01 | [phase-01-baseline-and-foundation.md](phase-01-baseline-and-foundation.md) | Section map, role/action catalog, decisions, status axes, ID migration | US-01,02,04,06 |
| 02 | [phase-02-report03-requirements.md](phase-02-report03-requirements.md) | Detailed desired SRS with acceptance/error flows | US-01,02,03,04 |
| 03 | [phase-03-report04-design.md](phase-03-report04-design.md) | Source-backed and proposed design, ERD/sequences | US-03,04,06 |
| 04 | [phase-04-report05-testing.md](phase-04-report05-testing.md) | Planned test suite and honest execution records | US-03,04,06 |
| 05 | [phase-05-report06-guides.md](phase-05-report06-guides.md) | Release, installation and current/pending workflows | US-01,04,06 |
| 06 | [phase-06-validation-and-gap-handoff.md](phase-06-validation-and-gap-handoff.md) | Successor validation and later-practice gap handoff | US-04,06,07,08 |
| 07 | [phase-07-docx-publication.md](phase-07-docx-publication.md) | Four visually inspected template-style DOCX | US-05,08 |

Execute phases in order; draft independent sections while D01–D03 are open. No final baseline/export acceptance while dependent statements remain unresolved. Writing drafts does not require fabricated supervisor approval. Readiness for execution and supervisor approval of registration are different states.

## Acceptance gates

1. Original DOCX section order and all existing granular report filenames preserved.
2. Eight human roles plus External Integration Services consistent across prose, diagrams, access matrix and guides. Legacy Author appears only in explicitly explained compatibility/history.
3. Desired requirements remain distinct from source maturity; AI explanation stays in scope and incomplete code stays a gap.
4. IDs stable, changed meanings mapped explicitly; all active requirement-to-design-to-test-to-guide references resolve.
5. New tests in Report 5 are Not executed unless genuine dated results exist. Historical evidence retains its baseline/date.
6. Catalog and identity/Study-Pack finalizations match actual user answers.
7. No template filler, invalid UTF-8, unsupported runtime/approval guarantees, secret values or missing required figures.
8. All four Word exports match the revised baseline; logo, full title, version/date/approval, TOC, tables and diagrams inspected.
9. Practice handoff lists missing code and acceptance without modifying product code.
10. Practice-only questions cannot enter organized exam generation, and exam-only questions cannot enter practice. Insufficient eligible content is explicit; later flag changes do not rewrite existing fixed exam/session content.

## Review and validation storage

All new audit/review/verification reports: `pte-doc/plans/reports/YYMMDD-<topic>-<report-type>.md`.
Their evidence: `pte-doc/plans/reports/assets/<report-name-without-extension>/`.
Do not write new verification reports into workstation Temp or historical `report/_validation/`.

## Risks and open decisions

- D01–D03 recommendations in spec are unaccepted. Track both options and affected artifacts.
- D04 channel-specific question eligibility is confirmed; both-enabled reuse, flag-change approval and migration/default policies need explicit design treatment. The earlier plan review predates D04; its approval does not certify the added behavior.
- v1.2 supervisor confirmation pending; no approval claim without receipt.
- New role names are not a global replacement for Author; approval responsibilities require resource/action review.
- Current source may drift during writing; date evidence and recheck changed dependencies.
- Existing document scripts enforce obsolete role/task assumptions and generator metadata. Plan successor changes, never weaken checks merely to pass.
- Numerical NFR targets require workload/method/owner; no invented measured capacity or contractual duration.
- Diagram renderer success alone does not prove every figure exists; inspect manifest and rendered Word pages.
- Student content reporting is distinct from Host support tickets; retain a bounded decision item when target/handler unresolved.

## Quality and Testing State

Spec Quality Check: structural PASS — prioritized stories and measurable acceptance are present. Business validation D01–D03 remains pending user answers; this structural result does not approve execution or publication. No ambiguity is disguised as an accepted recommendation.

Plan review: APPROVED for independent drafting; no BLOCKER/HIGH findings. See [red-team review](../../../plans/reports/261022-pte-prep-report-scope-plan-review.md). Phase implementation quality remains not evaluated.
Testing: no product tests started; documentation validation only. No application tests or new TDD commitment.
Documentation validation: PASS within the static boundary. See `validation-manifest.json`, `validation-policy.md`, and `pte-doc/plans/reports/261022-pte-prep-report-scope-validation.md`.
Execution: Phases 01–06 were drafted on 2026-10-22. No application source, database migration, deployment, production data or DOCX template was changed.

## Execution notes

The documentation work package drafted Phases 01–05 in place under `pte-doc/report/` while preserving the original Report 3–6 filenames and top-level section order. The revision adds the four application channels, eight canonical human roles, Student practice, AI explanation requirements, progress/history, and independent `available_for_practice` / `available_for_exam` selection rules. Source maturity remains separate from requirements.

The Markdown checks found no replacement characters or broken local links in the foundation and Report 3–6 bundle. No application tests, runtime checks, production checks or DOCX visual inspection were performed in this drafting pass. Phase 06 records the successor validation and practice gap handoff; Phase 07 remains pending until the dependent scope decisions and Markdown baseline are accepted.

Review adjudication: LOW handoff ambiguity **ACCEPTED** and corrected below. D01–D03 gate dependent finalization and publication, rather than all independent drafting. No findings rejected or left unaddressed.

## Handoff command

The reviewed plan supports independent documentation drafting with D01–D03 visibly pending. Record the user's answers before finalizing their dependent requirements, designs, cases, guides or submission exports. The handoff command is:

```text
/ck:cook --hard pte-doc/projects/plans/quang-pte-prep-report-scope-update/plan.md
```

This command is supplied for the next execution step; it has not been run in this planning turn. Per-phase optional checks follow ck:cook and session authorization; documentation validation remains a deliverable.

