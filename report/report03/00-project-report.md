# Report 3 - Software Requirement Specification

**Product:** PTEPrep
**Registered title:** PTEPrep: An AI-Powered PTE Practice Platform and Realistic Exam Simulator
**Document-level DOCX section:** II. Software Requirement Specification
**Version:** 1.1 scope revision draft
**Status:** Draft - D01-D03 and practice language/feedback policy confirmed by user; supervisor confirmation and remaining academic/operational policies pending
**Owner:** Ngo Dang Quang - Project Leader
**Revision date:** 2026-10-22
**Source:** `template-doc/Report3_Software Requirement Specification.docx`, registration v1.2, reviewed source and the scope revision plan

## Purpose

This report defines the business requirements for PTEPrep before the later practice implementation work. It preserves the original DOCX section order and uses plain language so that a reviewer, business analyst, academic reviewer, developer, tester, or operator can follow the same rule. It separates required behavior from what the reviewed source currently proves.

PTEPrep is an independent PTE-style practice and realistic exam simulation product. It does not connect to, represent, certify for, or claim endorsement by PTE Academic. Its results are not official PTE Academic results.

## Section navigation

1. [Overall Description](01-overall-description.md)
2. [User Requirements](02-user-requirements.md)
3. [Functional Requirements](03-functional-requirements.md)
4. [Non-Functional Requirements](04-non-functional-requirements.md)
5. [Requirement Appendix](05-requirement-appendix.md)

## Revision boundary

This revision adds the `pte-practice` Student journey, four product channels, Platform Manager, Academic Manager and Academic Staff responsibilities, AI educational explanations, progress/history, and independent question usage flags for Practice Web and the Windows exam client. It keeps the existing organization exam lifecycle, Proctoring, Examiner scoring, Host report publication, external integrations and out-of-scope decisions.

The required product scope is not the same as implementation maturity. A capability can be in scope while the reviewed build is Partial or Planned/Future. No product code, database migration, deployment or production data is changed by this report revision.

## Scope status and shared foundation

The shared actor, feature, vocabulary, task, status, evidence and open-decision rules are maintained in:

- [Actor and feature catalog](../_foundation/actor-feature-catalog.md)
- [Task catalog](../_foundation/pte-task-catalog.md)
- [Identifier ledger](../_foundation/id-ledger.md)
- [Status and evidence matrix](../_foundation/status-evidence-matrix.md)
- [Evidence catalog](../_foundation/evidence-catalog.md)
- [Open/TBD register](../_foundation/tbd-register.md)

Numeric performance and recovery values remain acceptance targets until a dated Report 5 result proves them. Retention remains contract-based. D01-D03 and practice language/feedback policy were confirmed by the user on 2026-10-22; D04 independent question flags remain confirmed. See the shared TBD register and Practice decision record for the resolved policies; confirmation does not imply implementation or academic validation.
