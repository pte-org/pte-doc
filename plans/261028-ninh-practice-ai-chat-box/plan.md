# Plan: Chat box AI cho PTE Practice (Task 76)

**Status:** In Progress  
**Date:** 2026-10-28  
**Mode:** Hard  
**Owner/slug:** Ninh — `261028-ninh-practice-ai-chat-box`  
**Scope:** Backend `pte-api` (module `chat` mới) + Frontend `pte-practice` (`features/chat`). Không làm Flutter `pte-app`.  
**Related:** [spec.md](./spec.md) · [research.md](./research.md) · [phase-01](./phase-01-be-foundation.md) · [phase-02](./phase-02-be-gemini-chat-client.md) · [phase-03](./phase-03-be-chat-service-endpoints.md) · [phase-04](./phase-04-fe-chat-panel.md) · [phase-05](./phase-05-verification-and-handoff.md)  
**Nhánh Git:** `Ninh/feat/Chat-Bot-AI` (người dùng tự commit/push; plan không có bước git)  

---

## Overview

Thêm chat box AI cho học viên PTE Practice: chỉ trả lời chủ đề tiếng Anh/PTE, trung lập không khen suông, quota 20 tin/ngày/student (reset 00:00 giờ VN), lưu toàn bộ hội thoại. Mọi quyết định trong `spec.md` là cố định; plan này chỉ chia việc, chốt cách làm và liệt kê điểm cần xác nhận.

**Lưu ý về cơ chế (không đổi hành vi spec):** spec yêu cầu bảng/`pre` bọc `overflow-x-auto` và nội dung `break-words`. Codebase gần như không dùng Tailwind utility và `app/globals.css` không import `tailwindcss`, nên plan giữ **đúng hành vi** đó nhưng đổi **cơ chế**: viết CSS tay có phạm vi riêng cho panel chat (xem AD-13); `@tailwindcss/typography` chỉ dùng cho kiểu chữ văn xuôi nếu spike nạp được mà không kéo theo preflight.

---

## 1. Phases Overview

- [ ] **Phase 1: BE foundation** (~1–1.5 ngày) — [phase-01-be-foundation.md](./phase-01-be-foundation.md)
  - Khung module `chat`, cấu hình `chat.ai.*` (mọi bean chat chỉ tạo khi `chat.ai.enabled=true`), migration V7 (`chat_usage`, `chat_session`, `chat_message` có cột `status`, `chat_answer_cache`), cập nhật `ModuleStructureTest`, chốt ranh giới module cho entitlement và Gemini client, hồ sơ test Postgres.
- [ ] **Phase 2: BE Gemini chat client + system prompt** (~1–1.5 ngày) — [phase-02-be-gemini-chat-client.md](./phase-02-be-gemini-chat-client.md)
  - Client Gemini riêng cho chat (structured output `{is_on_topic, markdown_content}`, nhiều lượt, `maxOutputTokens`, không retry), system prompt có phiên bản, làm sạch/parse/validate đầu ra, unit test với fake.
- [ ] **Phase 3: BE chat service + endpoints** (~3–4 ngày) — [phase-03-be-chat-service-endpoints.md](./phase-03-be-chat-service-endpoints.md)
  - Luồng một tin end-to-end: entitlement, validate, kiểm tra chủ phiên, khoá 1 request/user, semaphore, cache, quota UPSERT/hoàn quota, lịch sử 6 tin, lưu DB (OK/REFUSED/FAILED), 3 endpoint, ánh xạ lỗi 429/409/503, test song song trên Postgres thật.
- [ ] **Phase 4: FE `features/chat`** (~2.5–3.5 ngày) — [phase-04-fe-chat-panel.md](./phase-04-fe-chat-panel.md)
  - Side panel đẩy nội dung (overlay trên màn nhỏ), hook quota/phiên, render markdown an toàn bằng CSS tay có phạm vi, "Đoạn chat mới", disclaimer, i18n en/vi, gắn vào màn làm bài, test.
- [ ] **Phase 5: Verification & handoff** (~1–1.5 ngày) — [phase-05-verification-and-handoff.md](./phase-05-verification-and-handoff.md)
  - Bộ test prompt (off-topic, injection, nịnh, ngôn ngữ) với `is_on_topic` kỳ vọng rõ cho từng ca, kiểm tra tải/đồng thời, đo token thật để chốt `max-tokens`, tài liệu budget alert, handoff Privacy/ToS, release checklist.

Phase 1→2→3 tuần tự (BE). Phase 4 (FE) chỉ cần hợp đồng API đã chốt ở Phase 3 nên chạy song song được với Phase 2/3 bằng mock; tách repo nên không xung đột file. Các Open Decision (a), (b), (c), (e) cần được xác nhận **trước bước 6 của Phase 1**.

---

## 2. Phase → Spec Mapping

| Phase | Story / FR / NFR (spec.md) | Repo · vùng chính |
| :--- | :--- | :--- |
| **1** | FR-01, P3 (cấu hình `chat.ai.*`), NFR-04 (nền UNIQUE) | `pte-api` · `chat/`, `db/migration/V7__chat_*.sql`, `ModuleStructureTest`, `application.yml`, `practice/` (cổng entitlement) |
| **2** | FR-03, FR-05, P1 (từ chối chủ đề, không chiều ý), P1 (lỗi/JSON hỏng → không retry), P3 (model ghim, `finishReason`, token) | `pte-api` · `chat/internal/client`, `chat/internal/prompt` |
| **3** | FR-02, FR-04, FR-07, P1 (quota, đồng thời), P2 (phiên, lịch sử, cache), NFR-01, NFR-02, NFR-04 | `pte-api` · `chat/internal/{controller,service,repository,domain,dto,exception}` |
| **4** | FR-06, FR-07, P1 (UI quota/giới hạn), P2 (side panel, markdown, disclaimer), NFR-02 (không `dangerouslySetInnerHTML`) | `pte-practice` · `features/chat/`, `common/i18n/`, `app/globals.css`, `PracticeSessionView.tsx` |
| **5** | P1 (test prompt injection / sycophancy), P3 (budget alert), NFR-01, NFR-03 | `pte-api` test, `pte-doc` tài liệu vận hành |

---

## 3. Architecture Decisions

- **AD-01 (Một chiều phụ thuộc):** `chat` chỉ phụ thuộc `practice` (để kiểm tra entitlement) và `shared`; `practice` không được biết `chat`. Không để `chat` đi vào `scoring.internal`.
- **AD-02 (Cổng entitlement ở gốc package `practice`):** thêm một interface công khai nhỏ ở gốc `practice` (kiểm tra student được mở khoá Practice), `PracticeEntitlementService` hiện có (`practice/internal/service/`) implement nó. Không sao chép logic entitlement vào `chat`. `assertUnlocked` fail-closed khi `practice.strict-entitlement.enabled=false` (mặc định `false`) nên chat sẽ trả 403 — **mọi môi trường chạy chat (dev, test thủ công, staging, production) phải đặt `practice.strict-entitlement.enabled=true`**.
- **AD-03 (Chat client Gemini riêng, trong `chat`):** khuyến nghị chat có client HTTP Gemini riêng (xem Open Decision a). Lý do: `GeminiRestClient` ép `temperature 0` + JSON, không có `maxOutputTokens`/nhiều lượt, bỏ `finishReason`/`usageMetadata`; `ProviderGuard.standard` có retry xung đột với spec. Dùng lại cách đặt header `x-goog-api-key` (key không nằm trong URL) và cách phân loại lỗi HTTP.
- **AD-04 (Quota nguyên tử trong DB, transaction ngắn):** trừ quota bằng một câu `INSERT ... ON CONFLICT DO UPDATE ... WHERE used < limit` qua `NamedParameterJdbcTemplate`, kiểm tra "0 dòng = hết lượt". Không mở transaction qua lời gọi Gemini. Hoàn quota dùng đúng `usage_date` đã trừ.
- **AD-05 (Ngày/giờ do server tính, qua `Clock` duy nhất):** `NoDirectClockAccessTest` cấm `LocalDate.now(zone)` trực tiếp và cũng không chấp nhận `now(clock.withZone(...))` viết liền. **Không đăng ký bean `Clock` thứ hai** (`ClockConfig` giữ đúng một bean `Clock.systemUTC()`). Trong constructor của bean quota/service: nhận `Clock` được inject, gán `this.vnClock = clock.withZone(ZONE)` với `ZONE = Asia/Ho_Chi_Minh` đặt trong `ChatConstants`, rồi dùng `LocalDate.now(vnClock)` (tên biến phải kết thúc bằng "clock" không phân biệt hoa thường để regex của test chấp nhận).
- **AD-06 (Thứ tự xử lý một tin):**
  1. entitlement;
  2. validate (độ dài, UUID v4, `taskType` thuộc whitelist);
  3. **SELECT** kiểm tra chủ phiên (phiên đã tồn tại mà khác student → 404; chưa tồn tại thì chưa ghi gì);
  4. khoá 1 request/user (409);
  5. tra cache nếu phiên rỗng (hit: lưu tin `from_cache=true`, không trừ quota, không giữ semaphore);
  6. semaphore (đầy: 503, chưa trừ quota);
  7. trừ quota (UPSERT);
  8. **sau khi trừ thành công**: chèn `chat_session` bằng `ON CONFLICT DO NOTHING` rồi kiểm lại chủ phiên (lệch → hoàn quota + 404);
  9. gọi Gemini, làm sạch/parse/validate;
  10. lỗi/JSON hỏng/off-topic → hoàn quota;
  11. lưu tin (status OK / REFUSED / FAILED);
  12. ghi cache (best-effort, sau khi đã lưu tin OK);
  13. trả lời với `remaining`/`resetAt` tính theo **ngày đã trừ**.

  Không lưu được tin sau khi đã có câu trả lời tốt → hoàn quota + 503. Hoàn quota chạy trong `try/catch` riêng (lỗi hoàn quota chỉ log + metric, không che lỗi gốc); khoá và semaphore luôn được nhả trong `finally` **sau** bước hoàn quota.
- **AD-07 (Phiên):** bảng `chat_session (session_id PK, student_id)` ép quyền sở hữu bằng PK. Client đề xuất UUID v4; server **không ghi gì trước khi trừ quota** (chỉ SELECT để chặn IDOR), chỉ chèn phiên sau khi trừ thành công (AD-06 bước 8), nên request không hợp lệ/hết lượt không tạo rác trong `chat_session`. "Phiên gần nhất" = phiên có **tin nhắn mới nhất** (theo `chat_message`, mọi status). "Phiên rỗng" và "6 tin gần nhất" do server đếm từ DB, chỉ tính tin `status=OK`; không nhận cờ từ client. Khi server không trả phiên gần nhất (student mới), **client tự sinh UUID đầu tiên** — đây không phải nút "Đoạn chat mới".
- **AD-08 (Cache):** khoá = SHA-256 của (câu hỏi chuẩn hoá NFKC/trim/gộp khoảng trắng/lowercase + `language` + `task_type` + phiên bản system prompt); chỉ ghi khi `is_on_topic=true` và qua validate; đổi phiên bản prompt thì cache tự vô hiệu. Ghi cache là best-effort: `ON CONFLICT DO NOTHING`, mọi exception bị nuốt (log) và không ảnh hưởng response. Đổi model phải tăng phiên bản prompt.
- **AD-09 (Lỗi không retry):** timeout / 429 / 5xx / JSON hỏng / `finishReason != STOP` / `candidates` rỗng / bị chặn an toàn → hoàn quota → 503 "hệ thống bận". Không có retry ở bất kỳ tầng nào của chat.
- **AD-10 (Thinking & max-tokens):** thinking tính vào `maxOutputTokens`; ghim thinking ở mức thấp nhất của model đã chọn và chốt `max-tokens` theo số đo thật ở Phase 5 (xem Open Decision c). Lưu `finishReason`, token vào/ra (và token thinking nếu có) vào `chat_message`, kể cả dòng FAILED.
- **AD-11 (Cờ bật/tắt riêng, gate toàn bộ bean):** `chat.ai.enabled` mặc định `false`. **Mọi** bean chat (client, service, quota, gate đồng thời, cache, controller) đều gắn cùng một điều kiện thuộc tính này; khi tắt, không bean nào của chat tồn tại và validate cấu hình `chat.ai.*` **được bỏ qua** (khởi động không cần key). Khi bật mới kiểm tra: key riêng `CHAT_AI_GEMINI_API_KEY`, từ chối model có `-latest`, `daily-limit >= 1`. Entity chat phải tương thích H2 (không `jsonb`, không `columnDefinition`) vì ngữ cảnh test dùng `create-drop` trên H2.
- **AD-12 (Chỉ gửi task type, whitelist):** FR-07 chỉ mang `taskType` kèm tin (tránh lộ đề, giảm token, giảm bề mặt prompt injection, hợp quy tắc "không làm hộ bài thi thật"). Vì `taskType` đi vào prompt, server chỉ chấp nhận giá trị thuộc **enum whitelist** các dạng bài PTE hiện có (đối chiếu `LocaleDict.tasks`/catalog), không nhận chuỗi tự do. Xem Open Decision f.
- **AD-13 (Render markdown an toàn, CSS tay có phạm vi):** `react-markdown` + `remark-gfm`, không `rehype-raw`, không `dangerouslySetInnerHTML`, `skipHtml`, chặn `img`, link `target=_blank rel=noopener noreferrer` và chỉ cho `href` có scheme `http`/`https`/`mailto` (giữ `urlTransform` mặc định); `prose` (nếu dùng) đặt ở div bọc ngoài vì react-markdown ≥ v9 bỏ prop `className`. Bảng và `pre` có wrapper cuộn ngang, chuỗi dài ngắt dòng — viết bằng **CSS tay có phạm vi** của panel (hành vi tương đương `overflow-x-auto` + `break-words`), không phụ thuộc Tailwind utility. Typography chỉ cho kiểu chữ văn xuôi; phương án dự phòng nêu rõ ở Phase 4 (CSS tay cho cả prose nếu spike thất bại).
- **AD-14 (Lỗi 429 mang dữ liệu):** `DomainException` có hàm tạo 3 tham số mang `data`, `GlobalExceptionHandler.handleDomain` đã trả `data` ra ngoài → 429 kèm `resetAt` không cần sửa handler. FE phải đọc được `data` (hiện `PracticeApiError` bỏ `data`) — xem Phase 4.
- **AD-15 (Trạng thái tin nhắn):** `chat_message.status` ∈ {`OK`, `REFUSED`, `FAILED`}. `OK` = trả lời hợp lệ on-topic (kể cả cache hit); `REFUSED` = `is_on_topic=false`, trả câu từ chối cố định, đã hoàn quota; `FAILED` = lỗi sau khi đã trừ quota (provider/JSON hỏng/`MAX_TOKENS`…), đã hoàn quota, `answer` rỗng, vẫn lưu `finish_reason`, token vào/ra/thinking để quan sát chi phí. Chỉ `OK` được dùng làm lịch sử 6 tin và để tính "phiên rỗng". Màn hình nạp lại hiển thị `OK` + `REFUSED`, không hiển thị `FAILED`.

---

## 4. Open Decisions (cần người dùng xác nhận)

Các mục (a), (b), (c), (e) cần chốt trước bước 6 của Phase 1.

**(a) Cách `chat` lấy HTTP Gemini / guard / entitlement qua ranh giới Modulith**

| Phương án | Mô tả | Công sức | Nhận xét |
| :--- | :--- | :--- | :--- |
| **A1 (khuyến nghị)** | Entitlement: mở interface ở gốc `practice`. Gemini: `chat` có client riêng (`chat/internal/client`) + guard một lần gọi, tự phân loại lỗi HTTP. | S + M (~1–1.5 ngày) | Không đụng `scoring`, không rủi ro hồi quy chấm điểm, không kéo theo retry. Chấp nhận trùng ~100 dòng mã HTTP. |
| A2 | Chuyển `ProviderGuard`/`VendorHttp`/`AiProviderException`/`AiFailureReason` sang package dùng chung (named interface hoặc `shared`) rồi chat dùng lại. | L (~2–3 ngày) | Sạch về lâu dài nhưng sửa nhiều import trong `scoring`, test `ModuleStructureTest`/`PackageDensityTest` dễ vỡ; vẫn phải thêm `maxOutputTokens`, nhiều lượt, `finishReason`. |
| A3 | `scoring` mở một service công khai ở gốc package cho chat gọi. | M–L | Làm phình API công khai của `scoring` chỉ để phục vụ chat, vẫn phải mở rộng client. |

**(b) Khoá 1 request/user và semaphore: một instance hay lưu trong DB?**
- Khuyến nghị cho bản đầu: **một instance, trong JVM** (nhẹ, đúng với 70 req/phút), ghi rõ giả định trong tài liệu vận hành và log cảnh báo khi cấu hình nhiều instance (nếu phát hiện được; cần xác minh).
- Nếu scale ngang: chuyển sang khoá TTL trong DB (cột `in_flight_until` hoặc bảng khoá nhỏ), công sức M (~1 ngày). Không dùng advisory lock theo session vì giữ connection suốt 20 giây. Quota luôn đúng ở mọi trường hợp vì nằm trong DB.
- Cần biết: môi trường production chạy mấy instance?

**(c) Model Flash-Lite ghim, mức thinking và `max-tokens`**
- Khuyến nghị bắt đầu: bản **2.5 Flash-Lite ổn định** (thinking mặc định tắt) với `max-tokens` 800 (tiếng Việt tốn token hơn; ~600 chỉ đủ khi câu trả lời ngắn). Tên model chính xác và trường cấu hình thinking: **cần xác minh** trên ai.google.dev ngày làm.
- Nếu chọn 3.x Flash-Lite: bắt buộc ghim thinking `minimal` và nâng `max-tokens` lên ~1200–1500, chi phí cao hơn (xem khoảng 105–510 USD/tháng ở NFR-01).
- Phase 5 đo `usageMetadata` thật với bộ prompt tiếng Việt để chốt số cuối. Không dùng alias `-latest` (mặc định hiện tại của `scoring.ai.gemini.model` là `gemini-flash-lite-latest`; chat không được thừa hưởng).

**(d) Gắn side panel ở đâu**
- Màn làm bài là `app/(student)/practice-tests/session/page.tsx` → `features/practice/PracticeSessionView.tsx`; `StudentShell` (`features/shell/StudentShell.tsx`) khi ở route phiên chỉ trả `<main className="session-page">{children}</main>` (không rail/top bar).
- **D1 (khuyến nghị):** gắn trong nhánh render chính của `PracticeSessionView`, bọc nội dung hiện tại bằng layout 2 cột; có sẵn task hiện tại để lấy `taskType`. Công sức M (~1 ngày kể cả responsive overlay và bắt phím).
- D2: gắn ở nhánh route phiên của `StudentShell` + context truyền `taskType`. Phủ cả trạng thái loading/lỗi của view nhưng thêm một context và một lớp phụ thuộc chéo. Công sức M+.
- Layout cuối cùng chốt với UI/UX Designer (hẹn 15 phút) trước khi làm CSS ở Phase 4.

**(e) Test UPSERT: giả lập hay Testcontainers** (còn mở cho người dùng)
- Test hiện dùng H2 (`@DataJpaTest`, `src/test/resources/application.yml`, `create-drop`), `pom.xml` chưa có Testcontainers; H2 không hỗ trợ `ON CONFLICT ... DO UPDATE ... WHERE`. Test giả lập (H2 hoặc mock) **không chứng minh được** NFR-04.
- **Khuyến nghị:** thêm `org.testcontainers` (postgresql + junit-jupiter, scope test) với một **hồ sơ test Postgres riêng** (Flyway bật, `ddl-auto: validate`, nạp URL qua `@DynamicPropertySource`, tách khỏi cấu hình H2 mặc định) cho test đồng thời và test migration V7. Công sức S–M (~0.5–1 ngày); cần Docker ở máy dev/CI (cần xác minh CI có Docker).
- **Khi không có Docker:** test Testcontainers được bỏ qua trong build, nhưng **một lần chạy `psql` đồng thời thủ công, có ghi lại kết quả, là cổng BẮT BUỘC của release checklist** (Phase 5), không được "bỏ qua im lặng".

**(f) Hai điểm nhỏ cần chốt**
- Lưu tin theo trạng thái (AD-15): mọi tin sau khi đã trừ quota đều được lưu vào `chat_message` với `status` OK / REFUSED / FAILED. FAILED lưu `answer` rỗng + `finish_reason` + token; REFUSED lưu `on_topic=false`. Chỉ `OK` vào lịch sử 6 tin và tính "phiên không rỗng". Tin bị chặn **trước** khi trừ quota (độ dài, 409, semaphore đầy, hết lượt) không lưu, chỉ metric. Cần xác nhận cách hiểu "lưu mọi hội thoại" này.
- FR-07 "câu đang luyện": chỉ gửi `taskType` (whitelist, AD-12), không gửi nội dung đề. Cần xác nhận.

Việc ngoài code (Open Items trong spec, không chặn plan): hạn mức RPM/TPM key trả phí (Tech Lead/PM), layout với UI/UX, duyệt câu chữ disclaimer + Privacy Policy/ToS (pháp lý/PM).

---

## 5. Research Summary

Nguồn: [research.md](./research.md) (2 researcher: codebase + thực hành bên ngoài), đã đối chiếu lại mã nguồn khi viết plan.

- **Codebase (`pte-api`):** module mẫu là `practice` (`internal/{controller,service,domain,repository,dto,exception,config,constant}`). Flyway đang đến V6, kế tiếp V7. `ModuleStructureTest.all_fifteen_business_modules_plus_shared_are_detected` liệt kê chính xác 18 tên (17 module + `shared`) bằng `containsExactlyInAnyOrder` → phải thêm `chat`. Kiểm tra kiến trúc có thật: `PackageDensityTest` (tối đa 15 class mỗi package `internal`), `SourceFileSizeTest` (tối đa 300 dòng/file), `NoDirectClockAccessTest`. `PracticeEntitlementService`, `ProviderGuard`, `GeminiRestClient` đều ở `internal` → không gọi chéo được.
- **Codebase (`pte-practice`):** `features/practice` phẳng, `api.ts` có `practiceRequest` (Bearer + refresh token) nhưng `PracticeApiError` bỏ `data` của lỗi; i18n ở `common/i18n/{types,en,vi}.ts` (`LocaleDict`); Vitest chạy môi trường node, test component bằng `renderToStaticMarkup`; **`app/globals.css` không có `@import "tailwindcss"`** (CSS viết tay, chỉ có loader `@tailwindcss/turbopack` trong `next.config.ts`) và gần như không có Tailwind utility → CSS cho markdown viết tay có phạm vi. Repo dùng **npm** (`package-lock.json`); `pnpm-lock.yaml` cũng có mặt nhưng không được cập nhật.
- **Thực hành ngoài:** structured output bỏ qua âm thầm `minLength`… nên phải tự kiểm "nội dung không rỗng"; kiểm `finishReason == STOP` trước khi parse; thinking tính vào `maxOutputTokens`; UPSERT kèm `WHERE` trả 0 dòng khi hết quota; không giữ transaction qua lời gọi Gemini; khoá/semaphore trong JVM chỉ đúng một instance.
- **Hướng chọn:** A1 (entitlement qua interface gốc `practice`, chat client riêng không retry), quota UPSERT trong DB, tests Postgres thật bằng Testcontainers (hoặc cổng `psql` thủ công bắt buộc), panel gắn trong `PracticeSessionView`.

---

## 6. Dependencies

- Key Gemini trả phí riêng cho chat (`CHAT_AI_GEMINI_API_KEY`); key free chỉ để thử với dữ liệu giả (NFR-03). Cloud Project có billing + budget alert do Tech Lead/PM tạo.
- `practice.strict-entitlement.enabled=true` ở mọi môi trường dùng chat (mặc định `false` làm chat trả 403).
- Docker ở máy dev/CI cho Testcontainers (nếu chọn e); nếu không, cổng `psql` thủ công bắt buộc.
- Phase 4 cần hợp đồng API từ Phase 3 (tên endpoint, mã lỗi, dạng `data`); làm song song bằng mock được.
- Phase 4: thêm `react-markdown`, `remark-gfm`, `@tailwindcss/typography` (nếu spike nạp được) vào `pte-practice` bằng npm, cập nhật `package-lock.json` (kiểm peer deps với React 19.3, Next 16.4).
- UI/UX Designer (layout panel), PM/pháp lý (disclaimer, Privacy Policy/ToS) trước release.

---

## 7. Risks

- **HIGH — Quota sai khi chạy đồng thời hoặc test không phát hiện được:** UPSERT chỉ đúng trên Postgres; H2 không chạy được câu lệnh. Giảm thiểu: Testcontainers với hồ sơ Postgres riêng (e); nếu không có Docker thì cổng `psql` thủ công bắt buộc trong release checklist.
- **HIGH — Câu trả lời bị cắt do thinking + `max-tokens` thấp:** JSON hỏng, user mất lượt rồi hoàn lại liên tục. Giảm thiểu: ghim model/thinking, `max-tokens` 800–1500 theo số đo thật, kiểm `finishReason`, đo ở Phase 5.
- **HIGH — Prompt injection ép `is_on_topic=true` / làm hộ bài thi / lộ system prompt:** Giảm thiểu: system prompt cứng + bộ test injection ở Phase 5 (mỗi ca có `is_on_topic` kỳ vọng, 3 lần chạy đều phải đạt); hiển thị chỉ qua markdown an toàn (chặn `img`, `skipHtml`, giới hạn scheme link); không thêm lời gọi phân loại thứ hai (tốn chi phí).
- **MEDIUM — Lượt "miễn phí" vẫn tốn token/dòng DB (F4):** tin được hoàn quota (off-topic, từ chối injection, lỗi provider) và cache hit không dùng quota nhưng vẫn tốn token (trừ cache hit) hoặc dòng DB; chỉ bị giới hạn bởi 1 request đang xử lý/user + `RateLimitFilter` toàn cục. Giảm thiểu: thêm bộ đếm metric + cảnh báo cho số lần hoàn quota; câu hỏi mở: có cần giới hạn số lần hoàn mỗi ngày mỗi student không (tuỳ chọn, chưa làm).
- **MEDIUM — Cache không có TTL/eviction (F10):** một câu trả lời on-topic sai/xấu sẽ được phát lại cho mọi người hỏi cùng văn bản; stampede khi nhiều người cùng hỏi một câu chưa có cache được chấp nhận. Giảm thiểu: đổi model/prompt luôn tăng phiên bản prompt (vô hiệu hoá cache); tuỳ chọn thêm cột `expires_at` nếu cần; có thể xoá tay bản ghi cache xấu.
- **MEDIUM — Khoá/semaphore chỉ đúng một instance:** Giảm thiểu: ghi giả định (b), nâng cấp khoá DB nếu scale.
- **MEDIUM — Thêm Tailwind typography làm vỡ CSS hiện có (preflight reset):** Giảm thiểu: bảng/`pre`/ngắt dòng đã là CSS tay có phạm vi; spike ở bước đầu Phase 4 quyết định cách nạp typography không kèm preflight; nếu thất bại dùng CSS tay cho cả prose; kiểm trang chủ/phiên bằng mắt.
- **MEDIUM — Vi phạm kiểm tra kiến trúc (`ModuleStructureTest`, 15 class/package, 300 dòng/file, `NoDirectClockAccessTest`):** Giảm thiểu: chia sub-package ngay từ đầu, `vnClock` suy ra từ `Clock` inject, chạy bộ test kiến trúc sau mỗi phase.
- **MEDIUM — V7 trùng với nhánh khác:** Giảm thiểu: kiểm `db/migration` trên `main` và nhánh đang mở trước khi đặt tên file, đổi số nếu cần.
- **MEDIUM — Dữ liệu cá nhân trong câu hỏi bị lưu (NFR-03):** Giảm thiểu: disclaimer cố định, không log nội dung tin, handoff Privacy Policy/ToS, ghi đề xuất thời hạn lưu.
- **MEDIUM — Link độc hại trong câu trả lời (F14):** Giảm thiểu: chỉ cho `href` scheme `http`/`https`/`mailto`, giữ `urlTransform` mặc định của react-markdown, link mở `noopener noreferrer`, chặn `img`.
- **LOW — Chi phí vượt dự kiến:** Giảm thiểu: quota 20/ngày, `max-tokens`, cache, budget alert (Phase 5).
- **LOW — Ước lượng công sức (F15):** Phase 1 ~1–1.5 ngày, Phase 3 ~3–4 ngày (tổng BE ~6–8 ngày, FE ~2.5–3.5 ngày). Giảm thiểu: chốt Open Decision (a), (b), (c), (e) trước bước 6 Phase 1; chạy Phase 4 song song bằng mock.
- **LOW — `session_id` trống sau "Đoạn chat mới" rồi tải lại trang (chưa gửi tin nào):** quay về phiên cũ có tin mới nhất; chấp nhận, ghi trong tài liệu.
- **LOW — `react-markdown` ESM-only trong Vitest:** Giảm thiểu: test bằng `renderToStaticMarkup`; nếu lỗi resolve thì cấu hình `server.deps.inline`.

---

## 8. Verification Checklist

Backend (`pte-api`):
- [ ] `ModuleStructureTest` pass với `chat` trong danh sách; `PackageDensityTest`, `SourceFileSizeTest`, `NoDirectClockAccessTest` pass.
- [ ] Ngữ cảnh test H2 `create-drop` khởi động được khi `chat.ai.enabled=false` (không có bean chat, không cần key) và entity chat không dùng `jsonb`/`columnDefinition`.
- [ ] V7 chạy sạch trên Postgres thật (hồ sơ test Postgres: Flyway bật, `ddl-auto: validate`) và không báo lệch entity.
- [ ] Unit test client: `finishReason` khác `STOP`, `candidates` rỗng, JSON bọc ```json, JSON hỏng, thiếu trường, `is_on_topic=true` + nội dung rỗng → đều thành lỗi để hoàn quota.
- [ ] Test song song: 2 request cùng lúc với `limit=1` chỉ một thành công; N luồng với `limit=20` đúng 20 thành công; chỉ 1 dòng `chat_usage` mỗi (student, ngày); hoàn quota không âm; hoàn quota vắt qua nửa đêm trừ đúng ngày đã tính. Không có Docker: lần chạy `psql` đồng thời thủ công đã ghi lại (cổng bắt buộc).
- [ ] 429 trả `resetAt` + `limit` + `remaining`; 409 khi có request đang xử lý; 503 khi provider lỗi / semaphore đầy / không lưu được tin; quota được hoàn trong các trường hợp lỗi, không retry (đếm số lần gọi fake = 1).
- [ ] Test CI xác định (fake client): `is_on_topic=false` → hoàn quota + câu từ chối cố định + tin `status=REFUSED`.
- [ ] Tin `FAILED` có `answer` rỗng + `finish_reason` + token; `FAILED`/`REFUSED` không vào lịch sử 6 tin và không làm phiên "không rỗng".
- [ ] IDOR: dùng `session_id` của student khác bị từ chối (404) kể cả khi hai request tranh chấp cùng `session_id`; client không thể ép "phiên rỗng" hay gửi lịch sử; request bị từ chối không để lại dòng `chat_session`.
- [ ] Cache: chỉ tra khi phiên rỗng; hit không trừ quota và ghi `from_cache=true`; đổi phiên bản prompt → miss; lỗi ghi cache không làm hỏng response.
- [ ] `./mvnw test` xanh toàn bộ (lệnh test chuẩn của repo — cần xác minh).

Frontend (`pte-practice`, dùng npm):
- [ ] `npm ci` thành công; `npm run typecheck` 0 lỗi; `npm run lint` không lỗi mới; `npm run test:unit` xanh; `npm run build` thành công. `package-lock.json` đã cập nhật, `pnpm-lock.yaml` không bị sửa.
- [ ] Panel đẩy nội dung ở màn rộng, overlay ở màn nhỏ; input + nút gửi khoá khi đang xử lý và khi hết lượt (kèm "còn X giờ Y phút"); cảnh báo khi còn ≤ 3.
- [ ] Bảng/`pre` cuộn ngang trong panel (CSS tay có phạm vi); không có `dangerouslySetInnerHTML`; ảnh/HTML trong câu trả lời không render; link chỉ http/https/mailto.
- [ ] Disclaimer hiện cố định dưới ô nhập, đúng nguyên văn tiếng Việt.
- [ ] Tải lại trang nạp lại đúng phiên gần nhất (phiên có tin mới nhất); student mới (server không trả phiên) thì client sinh UUID đầu tiên; chỉ "Đoạn chat mới" đổi `session_id` về sau.

Tích hợp & vận hành:
- [ ] Bộ test prompt đạt tiêu chí ở Phase 5 (mỗi ca có `is_on_topic` kỳ vọng, 3 lần chạy đều đạt).
- [ ] `max-tokens` chốt theo số đo `usageMetadata` thật; không có `-latest` trong cấu hình.
- [ ] `practice.strict-entitlement.enabled=true` đã đặt ở môi trường release.
- [ ] Tài liệu budget alert + giả định một instance + key trả phí đã viết; PM/pháp lý nhận handoff Privacy Policy/ToS.
- [ ] Không có bước git trong plan; người dùng tự commit/push.
