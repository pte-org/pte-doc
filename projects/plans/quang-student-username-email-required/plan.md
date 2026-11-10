# Student accounts: generated username, required e-mail

**Author:** quang · **Created:** 2026-11-09 · **Status:** Done (2026-11-09)

## Goal

Every Student account belongs to exactly one organization and signs in with a username the system generates
(`{tenantCode}.{8 random chars}`). An e-mail address is required for every Student: it receives the published scores
and the account details. The same e-mail may appear in several organizations, each time as a separate account.

## Decisions (2026-11-09)

| # | Decision |
|---|---|
| D1 | Student username is always generated as `{tenantCode}.{random}` (current `UsernameGenerator`, random part kept for non-guessability), for single add and Excel import alike. Students never sign in with their e-mail. |
| D2 | E-mail is required and valid for every Student. It must be unique **within one organization**; the same e-mail in another organization creates a separate account (no shared account, no `joinExisting`). |
| D3 | Host, Proctor, Examiner and platform accounts are unchanged: username = e-mail, globally unique. |
| D4 | Students keep no self-service password reset; the Host resets it (existing `POST /users/{id}/reset-password`). |
| D5 | Excel import accepts only the PTEPrep template: exact headers, row-level validation in a preview, all-or-nothing on format errors. |
| D6 | After import the Host can choose to e-mail each Student their username and temporary password (existing credentials e-mail); the credentials file is always downloadable. |
| D7 | The unused legacy endpoint `POST /api/v1/students/import` is removed; `POST /api/v1/users/bulk` is the only create path. The normative docs are rewritten to match (user approved the contract change). |
| D8 | Existing Student accounts whose username is their e-mail keep working; no data migration. |
| D9 | **Deferred:** automatic class placement from the file. For now the template keeps Program Name and Class Name columns for the Host's own reference; import does not validate them and does not place Students in a class (class placement stays as today: importing inside a class page assigns everyone to that class). Placement by these columns is a later plan. |
| D10 | The Students sheet has one sample row right under the header (row 2), clearly marked as an example and carrying the notes (for example "Leave Program Name and Class Name blank if the Student is not in a program or class yet"). The parser always skips that row, so an untouched template never creates an account. |

## Phases

| Phase | Scope | Repos | Status |
|---|---|---|---|
| [01](phase-01-backend-student-account-rules.md) | Generated username, required e-mail, per-organization e-mail uniqueness | pte-api | Done |
| [02](phase-02-backend-import-validation.md) | Server-side row validation, remove legacy import endpoint, optional credentials e-mail | pte-api | Done |
| [03](phase-03-tenant-web-template-and-preview.md) | Template (Email required), strict header check, preview with row errors, credentials file | pte-web | Done |
| [04](phase-04-sign-in-copy.md) | Sign-in labels and hints on Practice Web and exam app | pte-practice, pte-app | Done |
| [05](phase-05-docs-and-bm.md) | Normative docs, IAM test scenarios, BM01/BM03/BM04 | docs, pte-doc, BM | Done |

## Out of scope

Shared accounts across organizations, organization picker at sign-in, Student self-service password reset,
human-readable usernames.

## Standards gate

`docs/CODING_STANDARDS_API.md` (phases 1–2), `docs/CODING_STANDARDS_WEB.md` (phases 3–4),
`docs/CODING_STANDARDS_APP.md` (phase 4), plus `docs/HOST_STUDENT_IMPORT_FLOW.md`, `docs/TEST_SCENARIOS_IAM.md`,
`docs/API_RESPONSE_SETUP.md` and `docs/COMMON_EXCEPTION_SETUP.md` (new error codes).
