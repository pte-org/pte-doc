# PTEPrep Report Scope Revision Validation Policy

**Revision:** 1.1
**Date:** 2026-10-22
**Scope:** Foundation and English Report 3-6 Markdown bundle

## Purpose

This policy checks the document package without treating source inspection as a product test. It protects the original report file boundaries, stable identifiers, current role names, channel rules, links and status language.

## Required checks

1. Read every Markdown file under `pte-doc/report/_foundation` and `pte-doc/report/report03` through `report06` as UTF-8.
2. Reject replacement characters and empty report files.
3. Resolve relative Markdown links from the file that contains them.
4. Confirm the exact registered title and canonical role/actor vocabulary in the report-level files and foundation catalog.
5. Confirm the four channels and both question usage flags are present.
6. Confirm the practice requirements, design elements, test cases and workflows use the allocated IDs.
7. Confirm Mermaid blocks have a manifest entry or a clear source/status note.
8. Confirm Report 5 planned cases are not labelled Passed without dated execution evidence.
9. Keep D01-D03, AI policy, feedback ownership and retention visible as open decisions until accepted.

## Checks performed for this drafting pass

The read-only static scan was run from `D:\GitHub\pte-org\pte-doc` and checked UTF-8 decoding, replacement characters, relative Markdown links and the validation manifest. `git -C pte-doc diff --check` was also run from the workspace root.

The scan covered 35 report Markdown files, found 18 Mermaid blocks, reported zero replacement characters and zero broken local links. `git diff --check` was clean after removing trailing whitespace from newly written Markdown.

## Explicit non-checks

- No Java, TypeScript, Dart or Python application tests were run.
- No email provider, AI provider, media upload, payment, Windows audio, production or deployment check was run.
- No supervisor approval was inferred.
- No DOCX export or visual inspection was performed.

## Publication gate

The Markdown bundle can move to DOCX generation only after the dependent scope decisions are recorded or the affected statements remain visibly provisional. DOCX publication requires separate OOXML and visual inspection evidence; a passing Markdown check does not satisfy that gate.
