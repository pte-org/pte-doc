# Tech Stack — APTIS LMS

## Confirmed Stack

| Layer | Technology | Constraint type |
|-------|-----------|----------------|
| Client framework | Flutter (Dart) — cross-platform | Hard constraint (DC-01) |
| Vendor Portal / Tenant Portal | Flutter Web | Confirmed (OI-01 baseline) |
| Exam Client | Flutter Desktop (Windows primary, macOS secondary) + Flutter Web | Confirmed baseline — Flutter Mobile deferred to v1.5 (OI-01 baseline) |
| Auth | Email + password; bcrypt cost factor ≥ 12; JWT access ≤ 15 min / refresh ≤ 7 days rotating | Hard constraint (DC-02, NFR-12, NFR-13) |
| Multi-tenancy | Subdomain routing (`{slug}.aptis-lms.vn`); tenant_id column strategy; row-level enforcement | Hard constraint (DC-02) |
| API style | REST (primary) + WebSocket/SSE (live exam monitor) | Product requirement (CI-01, CI-02) |
| Backend language/framework | TBD — TechLead decides | Soft |
| Database type | Relational (ACID, JSON/JSONB, row-level security) | Product requirement (DC-04) |
| Database host | Managed cloud (RDS / Cloud SQL / Azure Database) | Soft |
| File / object storage | Cloud object storage (S3 / GCS) for audio, images, exports | Product requirement |
| CDN | Required for Listening audio delivery (low latency critical); Vietnam/SEA edge nodes preferred | Hard constraint (SI-01, NFR-08) |
| Async job queue | Cloud queue (SQS / Pub-Sub / Azure Service Bus) for AI scoring and notification jobs | Product requirement |
| Cloud provider | AWS / GCP / Azure — TechLead decides; **Vietnam region may be required pending OI-07 / NĐ 13/2023** | Soft pending Legal |
| Deployment model | Containerised backend (Docker + orchestration); no on-premise in v1 | Hard constraint |
| HTTPS | Mandatory everywhere; no public HTTP endpoints | Hard constraint (DC-03) |

## Integration Points

| System | Protocol | Direction | Auth | Notes |
|--------|----------|-----------|------|-------|
| SI-01: CDN (audio/image) | HTTPS | Outbound (upload) / Inbound to client (delivery) | Presigned URLs (time-limited, ≤ exam session window) | Pre-warm 15 min before session start; NFR-08 TTFB target TBD |
| SI-02: Email service (SendGrid / AWS SES / TBD) | SMTP / HTTP API | Outbound only | API key | 10 trigger types; bilingual templates (Vi/En); delivery webhooks for notification_log |
| SI-03: Firebase Cloud Messaging (FCM) | HTTPS | Outbound only | Service account | **Conditional** — only if Flutter Mobile ships (OI-01) |
| SI-04: STT API (Whisper / Google STT / Azure — OI-02) | HTTPS | Outbound (audio file) / Inbound (transcript) | API key | Async queue; Vietnamese-accented English accuracy is primary selection criterion |
| SI-05: LLM API (Claude / GPT-4o / Gemini — OI-02) | HTTPS | Outbound (prompt) / Inbound (JSON score) | API key | Provider switch must be possible via config change only; structured JSON output required |

## Compliance Requirements

| Regulation | Applicability | Technical obligation |
|------------|--------------|---------------------|
| NĐ 13/2023/NĐ-CP (Vietnamese PDPA) | **TBD — Legal (OI-07)** | May require: data localization (servers in Vietnam), consent flow at account creation, right-to-deletion workflow for students |
| APTIS / British Council | Not applicable (no authorized partnership) | Disclaimer required in UI: "This is a practice simulation, not an official APTIS exam" (OR-LGL-01, DC-11) |
| General data security | Confirmed | HTTPS everywhere, bcrypt ≥ 12, JWT expiry, no credentials in logs, presigned URLs for audio |
