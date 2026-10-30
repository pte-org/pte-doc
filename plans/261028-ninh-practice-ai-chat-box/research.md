# Research: Chat box AI cho PTE Practice (task 76)

**Date:** 2026-10-28 · **Plan:** `261028-ninh-practice-ai-chat-box` · **Mode:** Hard  
Hai researcher chạy song song. Quyết định trong `spec.md` là cố định; báo cáo chỉ nói CÁCH làm.

---

## A. Primary — quy ước sẵn có trong codebase

### Backend `pte-api` (`app/src/main/java/com/pte/`)
- **Module `practice` là mẫu.** `practice/package-info.java` chỉ có `@org.springframework.modulith.ApplicationModule(displayName = "Practice")`. API công khai nằm ở gốc package; mọi thứ khác ở `internal/{controller,service,domain,dto/{request,response},exception,config,constant,mapper,messaging}`. Tên lớp có tiền tố module (`PracticeSessionController`, `PracticeEntitlementService`). `chat` dùng cùng khuôn: `chat/internal/{controller,service,domain,dto,exception,config,constant,client}` + `ChatConstants`. Chưa kiểm `practice/internal/repository`.
- **Controller** (`PracticeSessionController`): `@RestController`, `@RequestMapping(Constants.PATH)`, `@PreAuthorize("hasRole('STUDENT')")` ở cấp lớp, có `@ConditionalOnProperty(name = PracticeConstants.PRACTICE_WEB_ENABLED_PROPERTY, havingValue = "true")`. Lấy người gọi bằng `CurrentUserContext.required()` (`shared/security/`), bọc kết quả `ApiResponse.success(...)` (`shared/web/ApiResponse.java`), body `@Valid @RequestBody`. Lỗi: `shared/exception/DomainException` + `GlobalExceptionHandler` (có `GlobalExceptionHandlerResponseStatusTest`); cần đọc trước khi thêm 429 kèm `resetAt` và 409.
- **Ranh giới module (chặn lớn):** `PracticeEntitlementService` nằm trong `practice/internal`, nên `chat` không gọi trực tiếp (Modulith cấm). Cần `practice` mở một service/port ở gốc package, hoặc `chat` tự kiểm tra.
- **Clock/timezone:** `shared/config/ClockConfig` cung cấp `Clock.systemUTC()`. Dùng `LocalDate.now(clock.withZone(ZoneId.of("Asia/Ho_Chi_Minh")))`. Chưa có chỗ nào dùng `Asia/Ho_Chi_Minh`; đặt hằng số trong `ChatConstants` hoặc property.
- **Migration:** Flyway `app/src/main/resources/db/migration/` có V1..V6; file kế tiếp là **V7__chat_*.sql** (kiểm tra trùng V7 ở nhánh khác). `application.yml:56` có `ddl-auto: validate` nên entity phải khớp DDL. Test `application.yml` dùng `create-drop`; `ON CONFLICT` cần Postgres thật trong test (chưa kiểm Testcontainers).
- **Gemini client sẵn có:** `scoring/internal/vendor/gemini/GeminiRestClient.java` là `public` nhưng nằm trong `scoring.internal` → `chat` không dùng được. Cứng `temperature 0` + `responseMimeType application/json` (dòng 85-88), cần `responseSchema` (đã hỗ trợ), **không có** `maxOutputTokens`, không có `contents` nhiều lượt, bỏ `finishReason` và `usageMetadata`. API key đi qua header `x-goog-api-key`.
- **`ProviderGuard`/`VendorHttp`/`AiProviderException`** cũng ở `scoring.internal.vendor`, không dùng chéo module được. Lựa chọn: (a) chuyển sang package dùng chung với named interface (`shared` đang OPEN), (b) mở một service nhỏ ở gốc package `scoring`, (c) `chat` có client riêng. **`ProviderGuard.standard` có retry**; spec yêu cầu chat KHÔNG retry → cần guard không retry (`passThrough`) hoặc cấu hình riêng.
- **Cấu hình mẫu:** `AiProviderProperties` (`@Validated @ConfigurationProperties(prefix = "scoring.ai")`, `@Min/@Max`), `AzureGeminiProviderConfig` (HttpClient HTTP_1_1, validate gộp, ném `IllegalStateException`, base `https://generativelanguage.googleapis.com`). YAML dùng `${SCORING_AI_GEMINI_API_KEY:}`. Chat cần `ChatAiProperties` + khối `chat:` với `${CHAT_AI_GEMINI_API_KEY:}`; từ chối tên model có `-latest`. Dùng `JsonMapper` của `tools.jackson` (Jackson 3); không để key trong URL.
- **Test ranh giới:** `ModuleStructureTest` chạy `ApplicationModules.of(PteApplication.class).verify()` và có test khẳng định **đúng danh sách module** (`containsExactlyInAnyOrder`, tên "fifteen") → thêm `"chat"` và sửa tên/comment. Đọc `architecture/PackageDensityTest` (có thể giới hạn số file/package).
- **Chưa có:** pattern semaphore/khoá per-user (dự kiến code mới, in-memory); `shared/web/RateLimitConfig.java` chưa đọc.

### Frontend `pte-practice`
- `features/practice/` phẳng: `api.ts`, `constants.ts`, `contracts.ts`, `session-*.ts`, `PracticeProvider.tsx`, `*View.tsx`, helper thuần `.ts` + `*.test.ts` cạnh nguồn; thư mục con `media/`, `mode/`. Khuôn cho `features/chat`: `api.ts`, `constants.ts`, `contracts.ts`, `ChatPanel.tsx`, `useChatQuota.ts`, `useChatSession.ts`, helper thuần + test.
- **API/auth:** `api.ts:191` `Authorization: Bearer ${session.accessToken}`; `api.ts:245` base URL `process.env.NEXT_PUBLIC_API_BASE_URL ?? DEFAULT_API_BASE_URL` (`"http://localhost:8080"` ở `constants.ts:230`). Có `token-refresh.ts` (chưa đọc) → quyết định dùng lại helper request của practice hay viết riêng.
- **Gắn panel:** `app/(student)/layout.tsx` = `<PracticeProvider><StudentShell>{children}</StudentShell></PracticeProvider>`. Trang làm bài `app/(student)/practice-tests/session/page.tsx` → `features/practice/PracticeSessionView.tsx`. Layout "đẩy nội dung sang bên" nằm ở `PracticeSessionView` hoặc wrapper trong page; `StudentShell` nếu muốn panel toàn cục. Chưa đọc hai file này.
- **Test:** Vitest, `*.test.ts(x)` cạnh nguồn; chủ yếu test hàm thuần, ít test component (`task-action-buttons.test.tsx`).
- **i18n:** chưa tìm thấy `LocaleDict`; cần `Grep LocaleDict` toàn repo trước khi làm chuỗi cho chat. Chưa có `react-markdown`, `remark-gfm`, `@tailwindcss/typography` trong `package.json`.

### Rủi ro/lỗ hổng
Ranh giới module cho Gemini client/guard/entitlement; test danh sách module; xung đột retry; `GeminiRestClient` thiếu `maxOutputTokens`/lịch sử/`finishReason`/token usage → chat client phần lớn là code mới; V7 có thể trùng; cần Postgres cho test UPSERT; đọc `node_modules/next/dist/docs` và `AGENTS.md` trước khi viết code Next.

---

## B. Alternative — thực hành bên ngoài và đánh đổi

### Gemini structured output
- Trường request: `generationConfig.responseMimeType = "application/json"` + `responseSchema` (hoặc `responseJsonSchema`), đặt thêm `maxOutputTokens`, `temperature`. *(chưa xác minh từ trang Google, chỉ nguồn thứ ba — người làm cần đối chiếu ai.google.dev với model đã ghim trước khi code.)*
- Giữ `is_on_topic` đứng đầu: khai báo đầu tiên trong schema và trong `propertyOrdering`. Thứ tự không ảnh hưởng đúng/sai khi parse đủ JSON.
- **Chính thức:** `minLength`, `maxLength`, `uniqueItems`… bị bỏ qua âm thầm → bước kiểm tra "nội dung không rỗng khi `is_on_topic = true`" của FR-03 là **bắt buộc**. Giữ schema nhỏ (một boolean + một string), schema lớn có thể trả 400 INVALID_ARGUMENT.
- **Cắt cụt:** `finishReason = MAX_TOKENS` có thể cắt JSON giữa chừng. Kiểm `finishReason == STOP` trước khi parse; coi `SAFETY`, `RECITATION` hoặc `candidates` rỗng (prompt bị chặn) là lỗi provider → hoàn quota. Bổ sung vào FR-03.
- **Thinking (chính thức, ai.google.dev/gemini-api/docs/thinking):** `gemini-2.5-flash-lite` mặc định tắt thinking; `gemini-3.5-flash-lite` mặc định bật mức "minimal" (các mức minimal/low/medium/high, không có "off"). Thinking tính vào `max_output_tokens` và bị tính tiền; có thể trả rỗng/cắt khi chạm giới hạn. **`max-tokens ~600` không an toàn trên Flash-Lite 3.x trừ khi ghim thinking ở `minimal`** — hoặc nâng giới hạn (~1200–1500). Ghi lại token thinking.
- Tiếng Việt tốn token hơn tiếng Anh (không có số chính thức) → đo `usageMetadata` thật với prompt tiếng Việt.

### Quota UPSERT (PostgreSQL, nguồn: postgresql.org/docs/current/sql-insert.html)
```sql
INSERT INTO chat_usage AS u (student_id, usage_date, used)
VALUES (:sid, :today, 1)
ON CONFLICT (student_id, usage_date) DO UPDATE SET used = u.used + 1
WHERE u.used < :limit
RETURNING u.used;
```
- `WHERE` sai → dòng bị khoá nhưng không cập nhật và không trả về → **0 dòng = hết quota**. Trong Spring dùng `query`/`queryForObject` và kiểm danh sách rỗng; không dùng `update()` với RETURNING.
- Chặn `limit >= 1` trong cấu hình (nhánh INSERT không có WHERE).
- **Hoàn quota:** `UPDATE chat_usage SET used = GREATEST(used - 1, 0) WHERE student_id = :sid AND usage_date = :d` — dùng đúng `usage_date` đã bị trừ, không dùng "hôm nay" mới (request vắt qua nửa đêm).
- **Múi giờ:** tính ngày ở Java `LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh"))`, truyền làm tham số; không dùng `CURRENT_DATE`. `resetAt = today.plusDays(1).atStartOfDay(zone)`.
- **Transaction:** lệnh trừ quota chạy trong transaction ngắn riêng (hoặc autocommit), **không giữ mở qua lệnh gọi Gemini** (tới 20 giây) để khỏi khoá dòng và ghim connection. READ COMMITTED đủ, không cần SERIALIZABLE.
- **Nhiều instance:** quota trong DB vẫn đúng; nhưng khoá per-user trong JVM và `Semaphore(20)` chỉ đúng **mỗi instance** (N instance → N request/user, N×20 toàn hệ thống). Sửa tối thiểu khi scale ngang: khoá trong DB (`pg_try_advisory_lock`, hoặc cột `in_flight_until`/bảng khoá nhỏ có TTL); nếu không, chấp nhận một instance và ghi rõ trong plan. Luôn nhả khoá/semaphore trong `finally`.

### Frontend
- `react-markdown@10` + `remark-gfm` (dòng v4, chưa xác minh); chỉ ESM, nhận `children` là string; kiểm peer deps với React 19.
- Tailwind 4: `npm i -D @tailwindcss/typography`, thêm `@plugin "@tailwindcss/typography";` dưới `@import "tailwindcss";` trong CSS toàn cục, không cần `tailwind.config.js`. Dùng `prose prose-sm max-w-none dark:prose-invert` cho panel hẹp.
- `react-markdown` ≥ v9 bỏ prop `className` → đặt `prose` ở `div` bọc ngoài. Override: `table` bọc trong `div.overflow-x-auto`, `pre` có `overflow-x-auto`, `a` có `target="_blank" rel="noopener noreferrer"`; tách `node` ra khỏi props trước khi trải lên DOM.
- **Bảo mật:** HTML trong markdown mặc định bị escape; không thêm `rehype-raw`, không override `urlTransform`. Vì nội dung do LLM sinh, cân nhắc `skipHtml` và hạn chế ảnh (`img` override hoặc `disallowedElements`) để chặn tracking pixel/exfiltration từ prompt injection.

### Đánh đổi / điểm không an toàn
- Không an toàn nếu để nguyên: (a) `max-tokens ~600` + thinking mặc định trên Flash-Lite 3.x; (b) schema không ép được chuỗi không rỗng → cần FR-03; (c) khoá/semaphore chỉ đúng một instance (câu hỏi mở của plan); (d) giữ transaction DB qua lệnh gọi Gemini.
- Chỉ là đánh đổi: `is_on_topic` có thể bị prompt injection ép thành `true` — phòng thủ cứng là system prompt + bộ test; không khuyến nghị thêm một lệnh gọi phân loại (tốn chi phí). Trừ trước rồi hoàn sau đơn giản; nếu app sập giữa chừng người dùng mất một lượt, chấp nhận được ở mức 20 tin/ngày.

### Nguồn đã mở
ai.google.dev/gemini-api/docs/structured-output · ai.google.dev/gemini-api/docs/thinking · postgresql.org/docs/current/sql-insert.html · github.com/remarkjs/react-markdown · github.com/tailwindlabs/tailwindcss-typography · (chưa xác minh) discuss.ai.google.dev, thread về JSON hỏng khi `MAX_TOKENS`.
