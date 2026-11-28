# Plan: Defense 1.1 unhappy-path hardening

Status: 🟡 In Progress
Date: 2026-11-27
Mode: Hard

**Tác giả:** phat · **Spec:** [spec.md](spec.md) · **Báo cáo gốc:** [261127-defense-unhappy-path-brainstorm.md](../../../plans/reports/261127-defense-unhappy-path-brainstorm.md)

## Overview

Đưa số kịch bản ngoại lệ BM04 chạy đúng từ khoảng 6/13 lên 13/13 trước Defense 1.1, bằng cách chặn ở backend những gì hiện chỉ chặn ở UI (hạn nộp bài, temp password, tự duyệt, publish thiếu điểm), thêm các trạng thái BM04 ghi mà code chưa tạo ra (practice Expired, template Approved), đủ audit log theo NFR-06, và thêm công tắc AI theo năng lực (platform setting) cùng TTL đơn hàng chỉnh được lúc chạy cho DS-01e, DS-02e, DS-03c, DS-04c.

## Quyết định đã chốt (từ spec)

| # | Quyết định |
|---|---|
| D1 | Chặn tự duyệt hoàn toàn, kể cả Platform Admin. Rubric chỉ activate từ PENDING. |
| D2 | Chấm objective trong kỳ thi vẫn do Host bấm Score. Chặn publish nếu còn objective chưa có điểm. BM04 v1.2 sửa F-13, DS-03a. Practice giữ chấm tức thì. |
| D3 | Demo chạy trên prod VPS. Công tắc AI và TTL đơn hàng là platform setting, seed bằng migration. |
| D4 | Sửa câu đã qua trong bài thi (3-6) giữ nguyên, ngoài phạm vi plan này. |
| D5 | FR-10 là bốn công tắc AI theo năng lực (sinh đề, chấm exam, chấm practice, chat), hiệu lực = env AND setting, mặc định bật, chỉ PLATFORM_ADMIN đổi, có audit và banner. Không còn cờ force-failure. |

## Phases

- [x] Phase 1: Bảo mật xuyên suốt — temp password claim + filter (FR-07), tự duyệt và rubric activate (FR-04) [quality: skipped_by_user; decision: user_confirmed_skip]
- [x] Phase 2: WF-01 tài nguyên — exam definition approvedAt/approvedBy (FR-05), PUBLISH chạy submitApproval (FR-06), validator option/blank, Host template remove-only [quality: skipped_by_user; decision: user_confirmed_skip]
- [x] Phase 3: WF-02 onboard — lớp INACTIVE (FR-08), TTL đơn hàng + cron + Host hủy đơn (FR-13), bulk staff, chuẩn hóa mã số thuế [quality: skipped_by_user; decision: user_confirmed_skip]
- [x] Phase 4: WF-03 kỳ thi — hạn nộp server + grace + sweeper (FR-01), offset giờ pte-app (FR-02), blocker OBJECTIVE_NOT_SCORED (FR-03), re-assign class (FR-15), RF-18, RF-20 [quality: skipped_by_user; decision: user_confirmed_skip]
- [x] Phase 5: Công tắc AI theo năng lực (FR-10) — 4 platform setting, retryable, practice rate-limit/max-retries thành setting, vendor-web settings UI [quality: skipped_by_user; decision: user_confirmed_skip]
- [x] Phase 6: WF-04 luyện tập — deadline + Expired + progress (FR-11), assertUnlocked (FR-12), entitlement reason [quality: skipped_by_user; decision: user_confirmed_skip]
- [x] Phase 7: Audit log NFR-06 (FR-09) — payment, license, import, rubric, chọn điểm, publish, đổi công tắc AI [quality: skipped_by_user; decision: user_confirmed_skip]
- [ ] Phase 8: Kiểm chứng và tài liệu — suite, attack checklist, prod env check, BM04 v1.2, báo cáo, AGENTS.md

## Bảng phase

| Phase | Workflow | Owner gợi ý (BM04) | Ưu tiên | Trạng thái | Phụ thuộc | File |
|---|---|---|---|---|---|---|
| 01 | Cross-cutting | Hùng (FR-07), Quang (FR-04) | P1 | Xong (tests GREEN) | — | [phase-01](phase-01-cross-cutting-security.md) |
| 02 | WF-01 | Quang; Phát (RF-19, template) | P1 + P2 | Xong (tests GREEN, V61) | 01 | [phase-02](phase-02-wf01-resource-preparation.md) |
| 03 | WF-02 | Ninh, Hùng | P1 + P2 | Xong (tests GREEN, V62; bulk staff API, no bulk UI) | 01 | [phase-03](phase-03-wf02-tenant-onboarding.md) |
| 04 | WF-03 | Phát | P1 | Xong (tests GREEN, V63; pte-app 73+ tests) | 01; kiểm DS-03c cần 05 | [phase-04](phase-04-wf03-exam-operation.md) |
| 05 | AI switches | Quang (sinh đề, chấm exam), Hùng (practice), Ninh (chat) | P1 | Xong (tests GREEN, V64) | 01 | [phase-05](phase-05-ai-capability-switches.md) |
| 06 | WF-04 | Hùng | P1 + P2 | Xong (tests GREEN; no migration) | 01; kiểm DS-04c cần 05 | [phase-06](phase-06-wf04-practice.md) |
| 07 | Audit | Quang (rubric, chọn điểm), Ninh (billing, import) | P1 | Xong (tests GREEN) | song song 02–06 sau phase 01 | [phase-07](phase-07-audit-log.md) |
| 08 | Verify + docs | Cả nhóm | P1 | Một phần (test cục bộ, báo cáo, AGENTS.md xong; kiểm prod, tấn công thử, BM04 v1.2 chờ người vận hành) | 01–07 | [phase-08](phase-08-verification-and-docs.md) |


## Research Summary

Không dùng researcher riêng; plan dựa trên báo cáo brainstorm (đối chiếu file:line) và đã kiểm lại đường dẫn bằng Glob/Grep ngày 2026-11-27. Cách tiếp cận chọn: phương án B của báo cáo (sửa theo mức ưu tiên, phần còn lại chuẩn bị câu trả lời), kết hợp ý D (một filter chung cho các lỗ hổng "bỏ qua UI") ở phase 01.

### Chênh lệch giữa code hiện tại và báo cáo

- Migration cao nhất hiện là `V60__question_generation_batch_pause.sql`, nên migration mới bắt đầu từ V61. Phân bổ dự kiến: V61 (phase 02), V62 (phase 03), V63 (phase 04), V64 (phase 05), V65 (phase 06). Phase 01, 07, 08 không cần. Khi bắt đầu mỗi phase phải kiểm lại số cao nhất vì nhóm khác có thể thêm trước.
- NFR-06 đã có audit ở nhiều chỗ hơn báo cáo nêu: `LicenseGrantService` (grant), `LicenseCodeIssuer` (issue), `LicenseCodeService` (reveal), `UserService`, `ClassStudentService`, `SessionStateService`, `SnapshotPublishService`. Còn thiếu thật: `PayOsWebhookService`, `LicenseCodeRedeemer`, `LicenseCodeRevoker`, `UserAccountProvisioner`, các service rubric, chọn điểm (`ScoreSourceSelectionService`), `ReportPublishService`. Phase 07 xác minh từng chỗ trước khi thêm.
- `AI_RUBRIC_SCORER_UNAVAILABLE` hiện ném tại `AiScoringWorker.java:179` và `PracticeAiScoringService.java:175` (báo cáo trỏ `PracticeScoringStateService.java:222-236`, là nơi map lỗi chứ không phải nơi ném).
- Đã có `PracticeSessionExpiredException` trong `practice/internal/exception`; phase 06 kiểm nó đang dùng ở đâu trước khi thêm trạng thái EXPIRED.
- Không có lớp `JwtAuthenticationFilter` riêng: JWT dựng ở `identity/internal/security/AccessTokenIssuer.java`, `identity/internal/config/JwtConfig.java`, xác thực qua `identity/internal/config/SecurityConfig.java` và `shared/security/ResourceServerJwt.java`. Filter FR-07 gắn vào chuỗi này.
- Sweeper đã có mẫu: `SessionAutoCloseWorker` (60 giây), `OrderExpirationService` (cron), `BatchPausedExpiry`.
- Env bật năng lực AI đã tồn tại: `QUESTION_GEN_ENABLED` (mặc định false), `CHAT_AI_ENABLED` (mặc định false); practice rate-limit/max-retries ở `application.yml` dòng 53-54. Công tắc FR-10 chỉ thu hẹp, không bật được năng lực mà env đang tắt, nên phase 08 phải kiểm env prod.

## Dependencies

- Phase 01 xong trước các phase 02–06 vì thay đổi `SecurityPolicy` và chuỗi lọc JWT mà các phase sau dùng lại.
- Phase 05 (công tắc AI) phải xong trước phần kiểm demo của phase 04 (DS-03c), phase 06 (DS-04c) và phase 08; phần code của 04 và 06 không phụ thuộc phase 05 ngoài việc dùng chung lỗi retryable.
- Phase 07 chạy song song được với 02–06, nhưng audit rubric nên sau phase 01; audit hủy đơn (phase 03) và đổi công tắc AI (phase 05) nhập vào phase 07.
- Phase 08 chờ tất cả.
- Prod VPS: cần quyền SSH để kiểm env (không in giá trị) và PLATFORM_ADMIN để bật/tắt platform setting lúc demo.

## Risks

- HIGH: Filter temp-password chặn nhầm API mà app/web cần sau khi đổi mật khẩu, hoặc làm hỏng refresh token — mitigation: danh sách cho qua nhỏ, test, claim được cấp lại sau change-password.
- HIGH: Sweeper tự submit và deadline server làm mất bài hợp lệ khi lệch giờ hoặc restart — mitigation: grace cấu hình được (mặc định 30 giây), `Clock` inject, test ranh giới, đo thực tế một lần trước demo.
- HIGH: Migration lỗi trên prod (không reset DB) — mitigation: toàn bộ additive, backfill an toàn (template ACTIVE hiện có coi là đã duyệt), thử trên bản sao local trước.
- MEDIUM: Đọc platform setting chưa seed làm transaction rollback-only — mitigation: seed trong cùng migration, test kiểm dòng seed.
- MEDIUM: Công tắc AI bị bỏ quên ở trạng thái tắt sau demo, hoặc env tắt khiến công tắc vô tác dụng — mitigation: banner admin, audit, kiểm env prod ở phase 08.
- MEDIUM: Chạm nhiều file gần giới hạn 300 dòng hoặc package 15 lớp (`practice`, `scoring`, `enrollment`) — mitigation: tách lớp/package con từ đầu, chạy ratchet test cuối mỗi phase.
- MEDIUM: Bật `PRACTICE_STRICT_ENTITLEMENT_ENABLED` trên prod sau khi thêm `assertUnlocked` có thể khóa học viên thật — mitigation: kiểm ở phase 08, báo trước cho team.
- LOW: BM04 v1.2 lệch so với code cuối — mitigation: sửa tài liệu sau khi phase 01–07 chốt.

## Tiêu chuẩn bắt buộc

- pte-api: `docs/CODING_STANDARDS_API.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`.
- pte-web, pte-practice: `docs/CODING_STANDARDS_WEB.md`. pte-app: `docs/CODING_STANDARDS_APP.md`.
- Phase đụng IAM/auth/role: đọc thêm `docs/TEST_SCENARIOS_IAM.md`. Phase import: `docs/HOST_STUDENT_IMPORT_FLOW.md`.

## Ngoài phạm vi

Anti-cheat nâng cao, sửa câu đã qua trong bài thi (3-6), resend email kết quả, transactional outbox, khóa NFR-02, giới hạn chat history, signed URL Cloudinary, provider AI riêng theo kênh (P3).

## Red-team review (2026-11-27): REVISE → đã xử lý

| ID | Mức | Phase | Kết luận |
|---|---|---|---|
| B1 | BLOCK | 01 | ACCEPTED: Student import có `mustChangePassword=true`, pte-app không xử lý. Phạm vi filter chờ quyết định (Validation) |
| H1 | HIGH | 04 | ACCEPTED: grace mặc định 120s, sweeper tránh attempt còn đang sync; xử lý submit muộn chờ quyết định (Validation) |
| H2 | HIGH | 02 | ACCEPTED: backfill `approved_by` NULL, runbook DS-01a 2 tài khoản, kiểm UI trước khi chặn re-activate RETIRED |
| H3 | HIGH | 01 | ACCEPTED: null author được duyệt, chỉ chặn khi tác giả trùng; prod cần M1 và M2 |
| H4 | HIGH | 04 | ACCEPTED: định nghĩa chưa chấm, test hồi quy session cũ, nút Chấm điểm trong blocker |
| H5 | HIGH | 06 | ACCEPTED: sweeper lọc `deadline_at IS NOT NULL`, không backfill |
| H6 | HIGH | 05 | ACCEPTED: cổng `shared.ai.AiCapabilityGate`, đọc ngoài transaction, fallback = enabled, chỉ Admin sửa, tập dượt trên prod |
| M1–M4 | MED | 02/03/04 | ACCEPTED (PUBLISH được giữ và chặn qua cùng bộ kiểm tra; CHECK dùng NOT VALID; TTL tính theo phút và reset sau demo) |
| M5 | MED | 08 | ACCEPTED: thứ tự cắt và runbook prod |
| L1 | LOW | spec | ACCEPTED: sửa câu chữ về mặc định trong spec |
| L2, L3 | LOW | 06/01 | NOTED |
| FR-14 P2 | Gap | spec | NOTED → P3 (gắn thiết bị, device check network/screen), chuẩn bị câu trả lời Q&A |

## Validation (2026-11-27): quyết định đã chốt

- **B1, phạm vi filter temp password:** chỉ áp cho role **không phải STUDENT**. Học viên dùng mật khẩu do tổ chức cấp; pte-practice vẫn nhắc đổi như hiện tại; không sửa pte-app.
- **H1, deadline server:** sau `examEndTime + grace` (120s) thì **từ chối `answers/save`**, nhưng **`submit` vẫn hoàn tất** attempt với các câu đã lên server.
  Câu còn kẹt ở máy bị bỏ, kèm ghi incident `LATE_SYNC_REJECTED` (mỗi attempt một lần) để Host/Proctor xử lý.
- **Cách cook:** tuần tự 01 → 08, gate chất lượng theo từng phase, owner xem lại sau.
