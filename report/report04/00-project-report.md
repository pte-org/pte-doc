# Report 4 - Software Design Document

**Product:** PTEPrep
**Registered title:** PTEPrep: An AI-Powered PTE Practice Platform and Realistic Exam Simulator
**Document-level DOCX section:** II. Software Design Document
**Version:** 1.1 scope revision draft
**Status:** Draft - source-backed and proposed design separated; D01-D03 and selected policy items remain open
**Owner:** Ngo Dang Quang - Project Leader
**Revision date:** 2026-10-22
**Source:** Report 3 revision, registration v1.2, current Compose/source inventory and reviewed design plans

This report translates the revised requirements into a business-readable design. It keeps the deployed backend as a modular monolith, adds the Student practice web boundary, preserves the Windows exam client boundary, and distinguishes observed source contracts from proposed practice/AI components that still require implementation.

## Section navigation

1. [System Design](01-system-design.md)
2. [Database Design](02-database-design.md)
3. [Detailed Design](03-detailed-design.md)

## Design status rule

**Source observed** means a path, contract, configuration or class was found in the reviewed workspace. **Proposed** means the design is required by Report 3 but is not yet evidenced as complete. **TBD** means the design depends on an unresolved product or policy decision. These labels appear next to the design element; a diagram is not proof of implementation.

## Shared references

- [Report 3 SRS](../report03/00-project-report.md)
- [Actor and feature catalog](../_foundation/actor-feature-catalog.md)
- [Identifier ledger](../_foundation/id-ledger.md)
- [Status and evidence matrix](../_foundation/status-evidence-matrix.md)
- [Evidence catalog](../_foundation/evidence-catalog.md)
