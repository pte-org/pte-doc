# Exam Staff workspace — handoff

Ngày: 2026-10-11. Implementation hoàn tất; manual UI/live API/PostgreSQL còn chờ người dùng. Final integration quality verdict nằm trong `quality/phase-07-verification-and-handoff-quality-report.json`, không suy approval từ build.

## Delivered

- Host mở chi tiết nhân sự cùng tab qua `/host/exam-staff/[staffPublicId]`; default Overview, lịch Proctor/theo dõi Examiner tùy đầy đủ role array, Account cuối cùng.
- Shared ProfileHeader/ProfileLayout/ProfileAccountPanel được dùng bởi Learner và staff; shared Board chỉ trình bày. Không đổi font/size/token/ellipsis trigger của common.
- Staff xem thông tin trước, chỉnh inline fullName/email/phone/dateOfBirth. Username/roles read-only. Server whitelist, canonical email uniqueness trong tenant, dirty/discard/pending handling; phản hồi save là nguồn canonical trong đúng cache tenant/target.
- Tạm khóa/kích hoạt lại và tạo/gửi credentials theo flow staff gửi email hiện có, không dùng flow Student. Xác nhận trước command, không đưa mật khẩu tạm vào query cache.
- Proctor: counts theo phân công còn tồn tại, lifecycle phân biệt upcoming/ongoing/ended/cancelled/preparing/awaiting-open/unscheduled. Date-grouped schedule hoặc table, API filters/pagination, Host session detail. Không giả chứng cứ attendance.
- Preview giới hạn ba ca SCHEDULED chưa hết giờ; gồm ca quá giờ mở. Mốc hiện tại được tính lại mỗi request, độc lập bộ lọc Overview.
- Examiner: overview riêng ca/lượt/batch/câu trả lời, progress server-derived. Board ba status với trang/request riêng, ngoại lệ UNAVAILABLE có danh sách riêng; table ALL gồm ngoại lệ. Published vẫn hiển thị; publication khác work/lifecycle status. Không grading/DnD/assignment command.
- Apply/Clear reset page, kể cả query không đổi. Date overlap UTC half-open từ ngày hiển thị Asia/Ho_Chi_Minh. Ca thiếu lịch không được tự suy thời gian.
- Nullable progress không biến thành zero/100%; zero eligible ghi rõ không có câu cần chấm, coverage chưa đủ hiển thị partial verified counts riêng.

## Verification evidence

Tất cả lệnh dưới đây exit 0, không chạy tests:

| Scope | Command / observed result |
| --- | --- |
| API client | `corepack pnpm --filter @pte/api-client typecheck` |
| Shared UI | `corepack pnpm --filter @pte/ui typecheck` |
| Vendor | `corepack pnpm --filter vendor-web exec tsc --noEmit` |
| Tenant | `node node_modules/typescript/bin/tsc --noEmit` trong apps/tenant-web |
| Tenant feature/routes | `node node_modules/eslint/bin/eslint.js features/examStaff features/studentDetail 'app/(dashboard)/host/exam-staff/[staffPublicId]'` trong apps/tenant-web |
| Shared changed UI/API | ESLint với `--config packages/config/eslint.config.mjs`, các Profile/Board và API-client workspace request/types/listSessions |
| Tenant production build | `corepack pnpm --filter tenant-web build`; generated 28 static pages, dynamic staff route được đăng ký |
| Backend compile | `.\mvnw.cmd -pl app -am '-Dmaven.test.skip=true' compile`; fresh run BUILD SUCCESS, classes up to date (Phase02 đã compile sources trước đó) |
| Whitespace | `git diff --check` ở pte-web/pte-api/pte-doc |

Warnings: existing relative turbopack.root được Next resolve absolute; root common ESLint báo không có pages directory; Git LF/CRLF conversion warnings. Không đổi config ngoài scope để giấu warning. Một lần lint external-path sai và một lần outside-base ignored đã được chạy lại bằng đúng root config; không dùng lần ignored làm bằng chứng lint shared.

Dev servers chạy nền, trang `/login` HTTP 200 sau build:

- Vendor/admin: http://localhost:3000 (listener PID 12732 tại thời điểm kiểm tra).
- Tenant: http://localhost:3001 (listener PID 4872 tại thời điểm kiểm tra).
- Logs: `C:\Users\DELL\AppData\Local\Temp\codex-pte-fe\{vendor,tenant}-{out,error}.log`.
- Next16 installed CLI docs cho phép dev `.next/dev` và production build `.next` đồng thời; không kill servers để build.

## Limits / release follow-up

Testing: skipped by user. Không có unit/integration/Modulith/browser/E2E được chạy trong execution này; trước release hãy chạy test suite phù hợp. Static review, typecheck/build/compile và login HTTP 200 không chứng minh authorized API, security negatives, database migration hay rendered accessibility.

- V92 canonical-email uniqueness và V93 indexes chưa chạy trên DB. V92 preflight phải fail-safe nếu dữ liệu hiện tại có collision; không tự xóa/merge/normalize dữ liệu.
- Backend runtime đang chạy không được restart/rebuild bởi lượt này; cần dùng binary/image mới để kiểm API mới. Không tự áp migration.
- Không commit/push/deploy. Ba file ExamOverviewTab.tsx, ExamSettingsTab.tsx, SessionTable.tsx giữ nguyên ngoài scope.
- Các receipt Phase01–06 là snapshot tại thời điểm phase hoàn thành; final Phase07 receipt review/fingerprint source tích hợp hiện tại thay vì nói tất cả receipt cũ vẫn fresh sau phase sau sửa shared output.

Nếu local BE dùng Compose, command chỉ rebuild service `app` (người dùng chủ động chạy trong pte-api sau khi kiểm tra migration/data):

```powershell
docker compose --env-file .env -f docker-compose.yml -f docker-compose.services.yml up -d --no-deps --build app
```

Không chạy command này trong execution hiện tại; không restart toàn bộ infra.

## Manual acceptance checklist (user)

| Story | Manual check bổ sung cho source review |
| --- | --- |
| US-01 | Staff list View detail cùng tab; deep link; breadcrumb Exam Staff > name; không full reload/Home/back thừa |
| US-02 | PROCTOR-only, EXAMINER-only, dual-role; Overview đầu tiên, đủ tab, suspended target còn xem được |
| US-03 | Proctor ngày/ca/lifecycle Apply/Clear, timezone/boundary, thiếu lịch/cancelled/stale opening; từng page đúng API |
| US-04 | Supplemental batches một record mỗi ca; published ca vẫn xem được; details đi Host session; không scoring command |
| US-05 | Inline edit cùng vị trí field; readonly username/roles; email conflict; DOB invalid/future; save/cancel/discard; transient refetch không mất draft |
| US-06 | Common ellipsis actions; suspend/reactivate confirmation; staff email credential flow; không lộ password sau đóng modal |
| US-07 | Learner header/tabs/edit/actions/history giữ behavior; stock common font/size/light-dark/375px/long emails |
| US-08 | Board mỗi cột độc lập nhiều page; totals toàn filter; exceptions/ALL table; Apply/Clear reset; zero-work/unavailable không progress giả |
| US-09 | Route/query loading, refresh, error/retry/empty, hidden tab không gọi workload; logout/tenant/target đổi không hiện dữ liệu cũ |

Runtime security/database follow-up: HOST_ADMIN allow; non-Host/target tenant khác/Student-only/deleted/unknown ID deny without disclosure; PATCH extra forbidden fields rejected/ignored đúng whitelist; GET không ghi/expire assignment; concurrent email uniqueness và snapshot count/page trên PostgreSQL. Các scenario này chưa được chạy ở đây.
