# Phase 17: Đóng chính sách thương mại & release gate

Owner: **Quang**
Status: **Implemented — local release evidence passed; rollout/deploy not executed**
Depends on: **Phases 14–16**
Maps to: [ADR-006](../../architecture/ADR-006-commercialization-and-exam-templates.md) §3, §7, §9

## Requirements

Các behavior từng chưa có quyết định business thống nhất nay đã được owner Quang chốt trong master plan: renewal tính từ activation, suspended tenant được capability giới hạn, re-suspend là idempotent no-op, và student-capacity/refund/chargeback giữ ngoài release. Phase này biến các quyết định đó thành ADR/API/UI contract và release evidence; không để chúng chỉ tồn tại như assumption trong service hoặc test.

## Design Constraints

- Mọi decision phải có một canonical source trong ADR/plan và có acceptance test; không để code hiện tại tự trở thành business policy.
- Đã chốt giữ mô hình đã ghi trong master plan: mỗi purchase là một `Subscription` lane độc lập và `expiresAt = activationTime + durationDays`. Implementation hiện tại đã tính hạn độc lập từ `startsAt`; acceptance test không còn phụ thuộc `latestExpiry`.
- Suspension không tự gia hạn subscription theo ADR. Nếu deadline/rule re-suspend thay đổi, phải giữ nguyên nguyên tắc không tạo “free time” ngoài policy.
- Refund/chargeback, license revoke và capacity ledger phải có trạng thái/owner/audit rõ ràng. Nếu chưa làm trong release, phải ghi “unsupported” trong API/UI thay vì giả vờ đã xử lý.
- Release evidence phải phân biệt focused test, local/mock test, Postgres integration và full regression. Một test bị skip vì Docker không có không được ghi là passed.

## Steps

1. Ghi decision table đã được owner Quang chốt:

   | Policy | Decision đã chốt |
   |---|---|
   | Renewal expiry | Mỗi activation tính từ `startsAt`, không nối sau lane cũ; khớp ADR/multi-instance |
   | Suspended login/refresh | Cho phép report và ongoing attempt, không mở lại command forward-moving |
   | Re-suspend | Idempotent no-op; đổi deadline cần command/policy riêng, impact preview mới và audit |
   | Student-capacity revoke | Không tự giảm quota trong release nếu ledger chưa có reversal invariant |
   | Refund/chargeback | Không hỗ trợ trong release hiện tại; trả lỗi có machine code `unsupported` rõ ràng |

2. Cập nhật ADR-006, master plan, phase 13 notes và API/UI copy theo các quyết định đã chốt. Mọi thay đổi expiry phải cập nhật test `SubscriptionActivationServiceTest` và contract của cả PayOS/license activation.

3. Implement đúng policy đã ký: expiry calculation, suspended auth matrix, re-suspend behavior, unsupported refund/revoke behavior và audit. Không mở thêm scope billing khác trong phase này.

4. Chạy release-gate checklist:

   - API focused business-rule suite và Postgres migration/concurrency suite;
   - tenant-web/vendor-web typecheck và route contract checks;
   - full app regression, ghi riêng các opt-in PostgreSQL suites bị skip trong profile mặc định;
   - kiểm tra report quality/test evidence của Phase 14–16;
   - xác nhận không có generated artifact, secret hoặc migration chưa review trong commit groups.

5. Ghi handoff với trạng thái từng gate: `passed`, `skipped_by_user`, `blocked_by_environment` hoặc `failed`; owner Quang quyết định có rollout hay giữ plan ở `In progress`.

## Success Criteria

- Renewal behavior khớp một ADR duy nhất và có test cho activation mới, lane đang active, PayOS, license redeem và expiry.
- Suspended auth, re-suspend, refund/revoke đều có response contract và UI copy không gây hiểu sai.
- Mỗi skipped/failed release check có lý do, scope và người chịu trách nhiệm; không dùng focused pass để tuyên bố production-ready.
- Master plan chỉ chuyển trạng thái hoàn tất sau khi các release gate và evidence được ghi nhận.

## Quality and Testing State

- Quality gate: **approved for policy implementation** — report: `quality/phase-17-commercial-policy-and-release-gate-quality-report.json`.
- Testing: **focused, full regression, and supplemental PostgreSQL evidence passed** — report: `tests/phase-17-commercial-policy-and-release-gate-test-report.json`.
- The full API regression ran 2,157 tests with 0 failures, 0 errors, and 61 opt-in tests skipped by the default profile. The 61 skipped tests were then executed on isolated scratch PostgreSQL containers with 0 failures/errors/skips.

## Release Boundary

- [x] Stabilize the full-suite baseline: `ModuleStructureTest`, notification listener regressions, and the UUID-order assertion in `UserRepositoryTest`.
- [x] Run PostgreSQL migration verification for the Phase 2 partial index and all opt-in integration suites: 61/61 passed.
- Production rollout, deployment, browser verification, and owner approval remain outside this local evidence record; Quang decides that next step.
