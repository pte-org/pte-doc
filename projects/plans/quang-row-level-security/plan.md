# Plan: Row-Level Security

Status: 🔵 Not started
Date: 2026-09-16
Mode: Hard
Created by: Quang
Specs: [ADR-003](../../architecture/ADR-003-tenant-isolation-and-infrastructure.md)

## Overview

Bảo vệ dữ liệu tenant-scoped bằng RLS ở tầng DB, di chuyển kiểm soát truy cập từ tầng app (chỉ APP_DB_USER) sang tầng cơ sở dữ liệu (role `pte_app` + policy). Khôi phục khoá truy cập bằng transaction-local GUC, test được việc áp dụng, rồi kích hoạt policy trên 33 bảng tenant-scoped. **Phase 0 của commercialization** — mỗi bảng mới mà Phase 2+ thêm phải có policy; nếu quên, build sẽ fail.

## Phases

- [ ] Phase 1: Cơ sở hạ tầng vai trò & quyền — Tạo role `pte_app`, grant quyền đọc-ghi, ALTER DEFAULT PRIVILEGES, RLS chưa bật
- [ ] Phase 2: Chuẩn hoá schema — sửa BIGINT→UUID (2 bảng đã có), denormalize `tenant_id` lên 12 bảng con, cập nhật 12 JPA entity
- [ ] Phase 3: Đường ống GUC & chẩn đoán — Override `JpaTransactionManager.doBegin()`, `set_config()` với bind parameter, test fail-closed
- [ ] Phase 4: Sóng 1 — Class A (23 bảng strict) + proof-of-activation test (bắt buộc)
- [ ] Phase 5: Sóng 2 — Class B (10 bảng nullable/global) + view `security_invoker`
- [ ] Phase 6: Workers — `AiScoringWorker`, `EmailWorker` truyền GUC từ message header
- [ ] Phase 7: Kiểm thẩm — Catalog-driven: mọi bảng `tenant_id` có policy, build fail nếu quên

## Thứ tự và phụ thuộc

```
P1 ──> P2 ──┬──> P3 ──┬──> P4 ──┐
            │         │         ├──> P7
            └─────────┴──> P5 ──┤
                             │
                             └──> P6
```

**P1 chặn tất cả** — nếu role chưa có, không app khác chạy được.

**P2 sửa V2–V13 thẳng** (không thêm V14) → cả đội `docker compose down -v` trước P3 (một lần duy nhất).

**P3 phải làm xong trước P4** — GUC chưa set → policy eval false → 0 dòng. Proof-of-activation ở P4 buộc phải chứng minh.

**P4/P5 có thể song song** — Class A và B độc lập; P6 độc lập.

**P7 phải cuối cùng** — chứng thực 33 bảng + 2 exempt.

## Quyết định đã chốt (không mở lại trong lúc code)

| | |
|---|---|
| Chiến lược vai trò | Role split: `pte_app` (đọc-ghi app data, chịu RLS), APP_DB_USER chỉ chạy migration. **`APP_DB_USER` là `POSTGRES_USER` của image `postgres:17` → nó là SUPERUSER, không chỉ là owner.** Superuser bypass RLS **vô điều kiện — `FORCE ROW LEVEL SECURITY` không vá được**. Nên tách sang `pte_app` không phải "cách gọn hơn", nó là cách **duy nhất**; chừng nào app còn connect bằng `APP_DB_USER` thì mọi policy viết ra đều vô hiệu. Vì `pte_app` không phải owner nên `ENABLE` trần là đủ, không cần `FORCE` |
| GUC plumbing | Override `JpaTransactionManager.doBegin()`, `set_config()` với 2-arg `current_setting(..., true)` + bind parameter. Transaction-local |
| Fail-closed là thiết kế | GUC = null → `NULLIF(..., '')` → NULL → `NULL = UUID` → false → 0 dòng, không error |
| Một policy per table | Nhiều permissive policy được **OR** với nhau, không bao giờ AND. Tách thành hai policy thì policy chỉ có `WITH CHECK` **thiếu mệnh đề `USING`**, và `USING` thiếu mặc định là cho phép → OR với policy kia → **mọi row hiện ra**. **Một CREATE POLICY per bảng, mang cả USING và WITH CHECK.** Cần AND thì phải `AS RESTRICTIVE` |
| Hai class policy | A (23 bảng strict): `tenant_id = NULLIF(current_setting('app.current_tenant', true), '')::uuid`. B (10 bảng nullable): `USING (NULL OR match)` nhưng `WITH CHECK` cấm write NULL |
| Platform escape | GUC `app.is_platform` từ `CurrentUser.isPlatformUser()`. Không `SET ROLE`, không `BYPASSRLS` |
| Tenants table | Có policy `public_id = NULLIF(current_setting(...), '')::uuid` — tenant chỉ đọc chính mình, platform đọc tất (không exempt, có policy) |
| Exempt tables | `flyway_schema_history` duy nhất (Flyway meta, không tenant scope) |
| Migration version | **RLS: V14–V20**. Commercialization đang dùng **V15–V26, tức 12 migration** → renumber thành **V21–V32**: V15→V21, V16→V22, V17→V23, V18→V24, V19→V25, V20→V26, V21→V27, V22→V28, V23→V29, V24→V30, V25→V31, V26→V32 |
| Đường đăng nhập | Bật RLS trên `users`/`login_hashes` **khoá cửa toàn bộ tenant user** nếu không mở đường tiền-xác thực. Chốt: hàm `SECURITY DEFINER` hẹp, nằm **cùng migration V16** với policy (tách phase là tạo khoảng hở sập login). Platform admin vẫn vào được kể cả khi làm sai → **phải test đăng nhập bằng tenant user thật**, không test bằng admin |
| Hàm `SECURITY DEFINER` | Mỗi hàm là một lỗ khoét xuyên RLS. Chỉ cho đường tiền-xác thực, hiện đúng **2 hàm**. P7 đếm số hàm trong schema và so danh sách cho phép — mọc thêm cái thứ 3 là **build fail** |
| Thứ tự deploy | Migration bật RLS (V15/V16) **không được merge khi code P3 chưa chạy**. GUC chưa có → mọi query 0 dòng. P3 và P4/P5 vào **cùng một lần deploy**; chạy migration xong phải đăng nhập thử từng vai trò ngay |
| Thứ tự merge với plan kia | Hai plan **cùng sửa `V3__tenancy.sql`** (RLS đổi kiểu cột; commercialization P1 thêm `Tenant.code`, `User.username`). Chốt: **RLS P2 merge trước** (đổi kiểu cột, ảnh hưởng sâu hơn), commercialization P1 rebase lên trên, rồi cả đội `docker compose down -v` **một lần cho cả hai** |
| Class A (23 bảng) | Đã có column (15): `exam_attempts`, `pinned_exam_snapshots`, `exam_sessions`, `enrollments`, `proctor_assignments`, `scoring_answers`, `proctor_sessions`, `violation_events`, `media_objects`, `attempt_reports`, `audit_logs`, `notification_logs`, `class_memberships`, `lecturer_assignments`, `program_coordinator_assignments`. BIGINT→UUID (2): `organizations`, `quota_transactions`. Denormalize NOT NULL (6): `pinned_items`, `attempt_answers`, `attempt_heartbeats`, `session_compositions`, `programs`, `student_classes` |
| Class B (10 bảng) | Đã có nullable (4): `users`, `questions`, `exam_blueprints`, `exam_snapshots`. Denormalize NULLABLE (6): `user_roles`, `login_hashes`, `refresh_tokens`, `question_options`, `blueprint_items`, `snapshot_items` |
| Denormalization constraint | 12 bảng thêm cột P2. Class A: NOT NULL. **Class B: NULLABLE** (cha có `tenant_id = NULL`). Mọi đường ghi phải điền tenant_id; cột sai lệch → RLS lọc sai, không báo lỗi (tệ hơn không RLS) |
| `identity_student_directory` | `WITH (security_invoker = true)` — view chạy với quyền gọi → RLS sinh hiệu lực |

## Dependencies

**Có sẵn:**
- `com.pte.shared.security.CurrentUserContext` — `current()` trả `Optional<CurrentUser>`, `required()` ném khi trống. **`doBegin()` dùng `current()`**; `required()` chỉ dùng ở đường ghi nơi thiếu tenant thật sự là lỗi
- Spring Data JPA, Hibernate `ddl-auto: validate`
- Postgres 17, Flyway, HikariCP

**Phải thêm:**
- Test: Testcontainers Postgres 17 + `@SpringBootTest` as `pte_app` role
- Test seam: `SecurityContextTestHelper` mock `SecurityContextHolder`

**Hạ tầng đã xác minh:**
- Flyway V1–V13, sửa `CREATE TABLE` thẳng (DB trống, không backfill)
- `APP_DB_USER` = `POSTGRES_USER` của image `postgres:17` → **superuser**. Superuser bypass RLS **vô điều kiện**, `FORCE` cũng không vá được → chuyển app sang `pte_app` là cách **duy nhất**

## Đường không bao giờ có GUC — chốt cách xử lý từng cái

`RlsJpaTransactionManager` chỉ phủ code chạy trong một Spring transaction có `SecurityContextHolder`. Những đường dưới đây **không** thoả điều đó. Xử lý sẵn, đừng để người viết sau tự nghĩ ra:

| Đường | Xử lý |
|---|---|
| **Xác thực** (login, refresh) | Hàm `SECURITY DEFINER` — P5. Đây là blocker, không phải edge case |
| **STOMP/WebSocket** (`proctoring`, `StompAuthChannelInterceptor`) | Message thread **không** đi qua filter chain HTTP; `SecurityContextHolder` có thể trống. Đường thật đang có trong repo — phải set GUC tường minh từ principal của STOMP session |
| **Rabbit worker** (`AiScoringWorker`, `EmailWorker`) | P6 — `tenantId` đi trong message header, set GUC tường minh |
| **`@Scheduled`** | Hiện **chưa có cái nào**, nhưng commercialization P4 (job Subscription hết hạn) và P13 (job gỡ đình chỉ) sẽ thêm. Chốt trước: job phải chạy qua helper `withTenantContext(...)` của P6, hoặc đọc dữ liệu cross-tenant thì phải đặt `app.is_platform = true` tường minh |
| **Flyway** | Chạy as owner (superuser) → không bị RLS. Nói ra để khỏi ai đi sửa nhầm |
| **Hibernate `ddl-auto: validate`** lúc khởi động | Đọc metadata, không đọc dữ liệu → không ảnh hưởng |
| **actuator `health`** | Nếu có DB probe thì chạy không GUC → phải là query không chạm bảng tenant-scoped |
| **Hikari connection validation** | Query rỗng, không chạm bảng nào |

## Rủi ro

| Rủi ro | Phase | Xử lý |
|---|---|---|
| **Bật RLS trên `users` → không tenant user nào đăng nhập được** | 5 | Hàm `SECURITY DEFINER` cùng migration V16. **Platform admin vẫn vào được kể cả khi làm sai** → bắt buộc test bằng tenant user thật, từng vai trò |
| `CurrentUserContext.required()` trong `doBegin()` → nổ mọi request chưa auth (login, `POST /api/applications`, health) | 3 | Dùng `current()` (`Optional`), không principal → GUC `''` |
| Policy USING/WITH CHECK riêng → OR → mở cửa | 4,5 | Một CREATE POLICY per bảng (BOTH clauses) |
| Không 2-arg form → crash "unrecognized parameter" | 3,4,5 | `current_setting('app.current_tenant', true)` luôn |
| Class B NOT NULL → platform user (`tenant_id = NULL`) bị RLS block | 2,5 | Denormalize Class B **NULLABLE** (6 bảng) |
| Quên điền `tenant_id` trên bảng Class B → ghi NULL → mọi tenant đọc được | 2,5 | `WITH CHECK` cấm ghi NULL → INSERT bị từ chối ngay. Phải áp đủ **cả 10** bảng |
| Migration bật RLS land trước khi code P3 chạy | 3,4,5 | Cùng một lần deploy; chạy xong đăng nhập thử ngay |
| Hai plan cùng sửa `V3__tenancy.sql` | Plan | RLS P2 merge trước, commercialization P1 rebase lên trên |
| Commercialization V15–V26 đụng RLS V14–V20 | Plan | Renumber commercialization thành **V21–V32** (12 migration) |
| Hàm `SECURITY DEFINER` mọc thêm theo thời gian → RLS rỗng dần | 5,7 | P7 đếm và so danh sách cho phép; cái thứ 3 làm build fail |
| P7 kiểm policy bằng regex → chỉ chứng minh policy *nhắc đến* `tenant_id`, không chứng minh *logic đúng* (một policy viết `!=` vẫn lọt) | 7 | Ghi nhận giới hạn. Bù bằng test hành vi ở P4/P5, không dựa vào regex |
| CI không có Docker → toàn bộ test bảo mật không chạy mà build vẫn xanh | 7 | Testcontainers cần Docker daemon. Nếu CI thiếu, phải để build **fail**, không được skip im lặng |

## Nợ kỹ thuật chạm phải (không giải trong plan này)

- **Bulk import P8 commercialization** — đồng bộ, tranh pool. Scope riêng
- **Replication/backup** — replica không RLS. Review riêng

## Test strategy

**P1:** grant + default privileges
**P3:** fail-closed (GUC not set → 0), GUC correct → >0, GUC wrong → 0 rows. Row count assertions, **không EXPLAIN message**
**P4:** proof-of-activation (row count, `pg_policies` catalog), Class A WITH CHECK
**P5:** read global, read own, prevent write NULL, platform write NULL, view
**P6:** worker with/without header, both GUCs
**P7:** catalog-driven (all `tenant_id` → has RLS), syntax sample
Coverage ≥80% on security-related tests
