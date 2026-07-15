# Quality Standards — APTIS LMS

## Confirmed NFR Targets

| ID | Characteristic | Target | Status |
|----|---------------|--------|--------|
| NFR-03 | Availability — Exam Sessions | ≥ 99.9% during any active exam session window (≤ 43s downtime/session) | **Confirmed — #1 priority** |
| NFR-05 | Auto-score latency (Reading / Listening) | ≤ 2 minutes from exam submission to results available | **Confirmed** |
| NFR-12 | Security — password hashing | bcrypt, cost factor ≥ 12 | **Confirmed** |
| NFR-13 | Security — token expiry | Access token ≤ 15 minutes; Refresh token ≤ 7 days rotating | **Confirmed** |
| NFR-X | Exam continuity (exam data loss prevention) | Zero data loss when student disconnects during exam window; resume must work in 100% of cases within window | **Confirmed — #1 priority** |

## TBD NFR Targets (9 items — all block testing / architecture)

| ID | Characteristic | Suggested Target | Blocking | Resolve-by |
|----|---------------|-----------------|---------|------------|
| NFR-01 | API response time (p95 REST) | p50 < 200ms, p95 < 500ms, p99 < 1s | Load test pass/fail criterion; infrastructure tier sizing | TechLead — Architecture session (OI-05) |
| NFR-02 | Availability — overall (non-exam) | ≥ 99.5% monthly uptime (≤ 3.6 h/month) | Tenant SLA commitment by Sales | TechLead + PM — align with contract terms |
| NFR-04 | Concurrent exam takers | ≥ 500 simultaneous across all tenants | DB write tier sizing; WebSocket server sizing | Vendor Business (tenant count input) → TechLead (OI-05) |
| NFR-06 | Exam state write latency (p95) | p95 < 300ms | "Saved" indicator responsiveness | TechLead — derives from NFR-01 load model (OI-05) |
| NFR-07 | Speaking audio upload — max file size / upload time | 5–15 MB per student, ≤ 5 min upload on 10 Mbps | Audio format selection; STT evaluation | Content Manager (Speaking part durations) → TechLead (OI-01, OI-02) |
| NFR-08 | Listening audio CDN latency (TTFB) | TTFB ≤ 500ms from Vietnam client | CDN provider selection; edge node placement | TechLead — CDN benchmark (OI-07 → cloud region first) |
| NFR-09 | AI scoring pipeline end-to-end | ≤ 15 minutes total (STT + LLM + queue) | Teacher notification timing; student expectation | TechLead — OI-02 proof-of-concept benchmark |
| NFR-10 | Data retention — exam records | [TBD — Legal / NĐ 13/2023] | Purge job implementation; cloud storage budget; region | PM + Legal — OI-07 (initiate immediately — longest lead time) |
| NFR-11 | Data retention — Speaking audio | [TBD — Legal / NĐ 13/2023] | Storage cost estimate; budget approval | PM + Legal — OI-07 |

## Validation Status

**Validator verdict:** COMPLIANT (0 ERRORs, 7 WARNings)
**Date:** 2026-06-16
**Validator:** `scripts/srs_validator.py`

**Warning summary:**

| Warning type | Count | Location | Urgency |
|-------------|-------|----------|---------|
| `unresolved-tbd` | 10 tags | `03-03-performance.md` | Mixed — NFR-07/08 block F-03 dev; NFR-10/11 block architecture |
| `unresolved-tbd` | 8 tags | `03-04-database.md` | Must resolve before architecture (OI-07 retention periods) |
| `unresolved-tbd` | 4 tags | `03-07-other-requirements.md` | Should resolve before QA |
| `unresolved-tbd` | 2 tags | `appendix-b-open-issues.md` | Must resolve before architecture (load model inputs) |
| `unresolved-tbd` | 1 tag | `02-overall-description.md` | Resolve after OI-01 |
| `unresolved-tbd` | 1 tag | `03-02-functional-requirements.md` | Must resolve before F-04 dev (FR-28 band mapping format) |
| `open-items-count` | 8 items | `appendix-b-open-issues.md` | See session-notes.md for resolution order |

**To promote SRS from DRAFT to FINAL:** Resolve all 8 open items (OI-01 through OI-08), then re-run `/sr:validate`.
