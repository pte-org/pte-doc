# PTEPrep Report 3-6 Scope Revision Validation

**Date:** 22 October 2026
**Owner:** Ngo Dang Quang - Project Leader
**Scope:** English Markdown report revision only
**Result:** Draft validation passed within the documented static boundary; final publication remains pending

## 1. Files checked

- `pte-doc/report/_foundation/` shared catalogs and registers.
- `pte-doc/report/report03/` Software Requirement Specification.
- `pte-doc/report/report04/` Software Design Document.
- `pte-doc/report/report05/` Testing Documentation.
- `pte-doc/report/report06/` Release Package and User Guides.

The original DOCX templates and generated submission exports were not changed in this pass.

## 2. Static results

| Check | Result | Evidence/limit |
|---|---|---|
| UTF-8 decoding and replacement-character scan | Passed | 35 Markdown files scanned; no replacement character found |
| Relative Markdown links | Passed | No broken local links in the foundation and Report 3-6 roots |
| Mermaid inventory | Recorded | 18 Mermaid blocks found; required scope diagrams have IDs and status notes |
| Diff whitespace | Passed | `git -C pte-doc diff --check` clean |
| JSON manifest | Passed | `validation-manifest.json` is valid JSON |
| Role vocabulary | Passed for active scope | Eight human roles plus External Integration Services are in the foundation and revised sections; old Platform Author wording is compatibility/history only |
| Practice and channel flags | Passed for documentation presence | `pte-practice`, `available_for_practice` and `available_for_exam` are traced across requirements, design, tests and guides |
| Product behavior | Not run | No runtime or application test was authorized by this drafting pass |
| DOCX layout/logo/TOC | Not run | Phase 07 remains pending |

## 3. Scope review findings

The revised documents now separate:

- Platform Admin governance from Platform Manager operational work.
- Academic Staff drafting from Academic Manager approval/publication.
- Student self-practice from Host-created organization exams.
- Practice activity/progress from organization exam scores/reports.
- Practice and Exam question eligibility flags from approval, readiness and entitlement.
- AI explanation status from answer ownership and score publication.
- Current source evidence from proposed later implementation.

## 4. Remaining gates

1. Record decisions for D01 task-family catalog, D02 identity/context and D03 Study-Pack depth before finalizing dependent requirements.
2. Resolve feedback ownership/target, AI provider/rubric policy and contract-based retention details.
3. Review the report body with the supervisor and preserve the pending confirmation state until a real decision record exists.
4. Regenerate and visually inspect the four DOCX files using the source templates, school logo, original section order and the revised metadata.

## 5. Conclusion

The Markdown drafting phase is internally consistent within its static boundary. It is not a claim that `pte-practice`, AI explanation, channel flags or any other planned workflow is fully implemented or runtime verified.
