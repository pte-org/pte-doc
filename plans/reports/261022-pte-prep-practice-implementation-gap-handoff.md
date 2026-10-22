# PTEPrep Practice Implementation Gap Handoff

**Date:** 22 October 2026
**Owner:** Ngo Dang Quang - Project Leader
**Purpose:** hand the revised report requirements to the later practice implementation plan

This handoff does not implement product code. It identifies the work that remains after the English Reports 3-6 revision and gives each gap a stable requirement/design/test/guide reference.

## Gap register

| Gap | Current evidence | Required outcome | References | Later owner | Priority |
|---|---|---|---|---|---|
| Practice email challenge and recovery | Practice routes/source slices exist; complete expiry/reuse/throttle contract is not verified | One-time code, safe resend, expiry/reuse handling and no account disclosure | `FR-PRACTICE-001`, `SEQ-PRACTICE-LOGIN`, `TC-PRACTICE-001`, `WF-STUDENT-PRACTICE-001` | Identity/practice owner | P1 |
| Context and entitlement resolution | Organization membership/entitlement concepts exist; final D02 policy is open | Explicit context selection/default policy, locked/revoked/unavailable states and ownership checks | `FR-PRACTICE-002`, `DB-PRACTICE-SESSION`, `TC-PRACTICE-002`/`003` | Identity/tenant owner | P1 |
| Channel-aware catalog | Task/content source exists; independent consumer flags are a confirmed requirement | Store and audit both flags; filter practice and exam pools independently; no fallback | `FR-PRACTICE-003`, `FR-CONTENT-006`, `DB-CONTENT-USAGE`, `TC-CONTENT-003`-`006` | Academic/content owner | P1 |
| Practice session lifecycle | Practice session/progress slices exist; complete fixed-item and idempotent lifecycle is not evidenced | Create, begin, save, exit, resume, submit, discard and expire with stable ownership | `FR-PRACTICE-004`/`005`, `DB-PRACTICE-SESSION`, `SEQ-PRACTICE-SESSION`, `TC-PRACTICE-005`-`008` | Practice owner | P1 |
| Media binding | Media integration boundary exists; practice ownership/retry path is not complete | Signed grant, upload, binding, retry and ownership validation | `FR-PRACTICE-006`, `DB-PRACTICE-MEDIA`, `TC-PRACTICE-009` | Media/practice owner | P1 |
| AI explanation | Registration requires AI-assisted feedback; complete UI/provider result is not evidenced | Eligible task policy, provider adapter, pending/success/failure/retry states, provenance and answer preservation | `FR-PRACTICE-007`, `NFR-AI-001`/`002`, `DB-AI-FEEDBACK`, `SEQ-AI-FEEDBACK`, `TC-PRACTICE-010`/`011`, `WF-STUDENT-PRACTICE-002` | AI/scoring + Academic Manager | P1 |
| Truthful progress | Recent activity/progress mapping exists; final score/progress distinction needs product contract | Separate activity, confidence, pending feedback and scored performance | `FR-PRACTICE-008`, `TC-PRACTICE-008`/`012` | Practice/reporting owner | P1 |
| Content feedback | Host support tickets exist; Student question/lesson feedback target and handler are unresolved | Decide reporter, target, handler, visibility and closure states | `FR-PRACTICE-009`, `TBD-FEEDBACK-001` | Product + Academic Manager | P2 |
| Study-Pack depth | Grouped navigation exists; D03 is open | Choose quick groups or persisted curated packs; do not silently build an LMS | `TBD-D03-STUDY-PACK`, `FR-PRACTICE-003`/`008`, `TC-PRACTICE-004` | Product owner | P2 |
| Retention and deletion | Contract-based retention is the interim policy | Define contract fields, export/delete/legal-hold behavior and provider retention | `TBD-RETENTION-002`, `NFR-PRACTICE-006` | Product/privacy owner | P1 |

## Implementation acceptance gate

The later practice implementation is ready for review only when every P1 gap has a source/API/UI path, ownership checks, migration/default policy where needed, automated or manual cases, and a dated verification result. A successful build alone does not close a gap. The implementation must preserve organization exam behavior and the fixed content selected for existing sessions/exams.

## Explicit non-goals for the later handoff

- No official PTE Academic integration or certification.
- No Student personal payment or public registration payment flow.
- No open chatbot, model training, personalized learning-plan engine or LMS unless a new approved scope decision adds it.
- No mobile organization exam client redesign.
- No advanced anti-cheat beyond the approved policy.
