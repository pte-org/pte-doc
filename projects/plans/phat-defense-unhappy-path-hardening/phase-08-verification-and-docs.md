# Phase 8: Kiểm chứng và tài liệu

**Owner gợi ý:** Phát (điều phối), cả nhóm · **Ưu tiên:** P1 · **Phụ thuộc:** phase 01–07

## Overview

Chạy toàn bộ gate, tấn công thử bằng Postman/curl theo Success Criteria của spec, kiểm env prod (không in giá trị), sửa BM04 lên v1.2, viết báo cáo kiểm chứng và cập nhật snapshot trong AGENTS.md.

## Spec stories covered

- Success Criteria: 13/13 kịch bản ngoại lệ chạy đúng trên môi trường demo; bộ tấn công 1-1, 1-3, 1-4, 2-1, 2-2, 3-1, 3-8, 4-1, 4-3; mỗi FR-01..FR-13 có ít nhất 1 test; BM04 v1.2.
- Điều kiện prod: `PRACTICE_WEB_ENABLED`, `PRACTICE_STRICT_ENTITLEMENT_ENABLED`, provider AI và các env bật năng lực (`QUESTION_GEN_ENABLED`, `CHAT_AI_ENABLED`) để công tắc FR-10 có tác dụng.

## Files to modify/create

Đọc trước: `AGENTS.md` (mục Deployment tracking), `docs/CODING_STANDARDS_API.md`, `CODING_STANDARDS_APP.md`, `CODING_STANDARDS_WEB.md` để chạy đúng lệnh validate.

- `pte-doc/plans/reports/261127-defense-unhappy-path-hardening-verification.md` — báo cáo mới (đổi tiền tố ngày nếu hoàn thành ngày khác); bằng chứng ở `pte-doc/plans/reports/assets/<tên-báo-cáo>/`, link tương đối.
- `pte-doc/projects/plans/phat-defense-unhappy-path-hardening/attack-checklist.md` — bảng lệnh Postman/curl (placeholder cho host, token; không ghi token thật).
- BM04: tệp BM04 v1.1 trong thư mục BM (xác minh bằng Glob "SEP490_FA26SE182_R2_Commitment*"); tạo v1.2, BM04 là bản chuẩn, đồng bộ BM01/02/03 nếu có tham chiếu.
- `AGENTS.md` — cập nhật "Current work snapshot": migration V61–V65 (số thực tế), setting mới (4 công tắc AI, TTL đơn, grace, practice rate-limit/max-retries), filter temp password, deadline server, practice EXPIRED, audit coverage.
- `pte-doc/projects/plans/phat-defense-unhappy-path-hardening/plan.md` — cập nhật trạng thái phase.

## Implementation steps

1. Backend: `.\mvnw.cmd -pl app -DskipTests compile`, rồi `.\mvnw.cmd -pl app test`; ghi số test, failure, skipped; lỗi file không liên quan phải báo, không bỏ qua.
2. Web: trong `pte-web` và `pte-practice` chạy tsc, eslint, vitest (lệnh theo `CODING_STANDARDS_WEB.md`); pte-app chạy `flutter analyze` và `flutter test`.
3. Soạn và chạy checklist tấn công: 1-1, 1-3, 1-4, 2-1, 2-2, 3-1, 3-8, 4-1, 4-3; mỗi mục ghi request, mã lỗi nghiệp vụ nhận được, kết quả mong đợi.
4. Chạy lại 13 kịch bản DS trên demo theo kịch bản đã sửa; DS-01e, DS-03c, DS-04c dùng công tắc phase 05 (tắt, quan sát, bật, Retry); đo một lần NFR-05 (≤ 30 giây) của DS-03b.
5. Kiểm env prod qua SSH read-only (theo AGENTS.md): chỉ báo `PRACTICE_WEB_ENABLED`, `PRACTICE_STRICT_ENTITLEMENT_ENABLED`, `QUESTION_GEN_ENABLED`, `CHAT_AI_ENABLED` bật hay tắt và provider AI; không in `.env` hay secret. Nếu tắt thì báo user quyết định, không tự đổi.
6. BM04 v1.2: F-13 và DS-03a thành "scored when the Host starts scoring"; DS-01b (theo hành vi cuối cùng); DS-04a (thêm bước bấm Chấm điểm); DS-02a (one/both students, thống nhất bước 9 và expected #5); mục 8.1 (107 so với 111, ghi rõ 4 test NFR); F-11 nếu device check chưa kiểm network/screen.
7. Viết báo cáo kiểm chứng (kết quả, ranh giới đã/chưa kiểm, rủi ro còn lại), cập nhật AGENTS.md, đánh dấu phase trong plan.md.

## Tests

- Không thêm test mới; chạy toàn bộ: `.\mvnw.cmd -pl app test` (gồm ratchet trong `app/src/test/java/com/pte/architecture`), vitest `pte-web`/`pte-practice`, `flutter test` `pte-app`.
- Postgres IT cần `lifecycle.test.db.url` (xem AGENTS.md); không chạy được thì ghi rõ trong báo cáo.
- Kiểm UI do user tự làm (không dùng Playwright); báo cáo chỉ liệt kê các bước user cần tự kiểm.

## Design Constraints

- Không in hay lưu secret, `.env`, token, mật khẩu thật vào báo cáo, checklist hay AGENTS.md.
- Kiểm prod chỉ đọc; không dispatch, rerun, commit, push nếu user không yêu cầu; không đổi env prod khi chưa được duyệt.
- Báo cáo lưu ở `pte-doc/plans/reports/` tên `YYMMDD-<topic>-<report-type>.md`, không để ở Temp hay repo ứng dụng.
- Không sửa code ở phase này trừ lỗi nhỏ phát hiện khi kiểm; lỗi lớn quay về phase tương ứng.
- Migration đã ra là bất biến; sai sót sửa bằng migration mới (số cao nhất hiện tại ở thời điểm đó, từ V61+); setting mới phải seed cùng migration.
- Ghi chú tuân thủ: không đổi envelope/mã lỗi; ratchet file ≤ 300 dòng, package ≤ 15 lớp phải xanh.
- Restart docker app local sau mỗi sửa backend trước khi chạy lại tấn công.

## Risks

- Prod chưa bật cờ practice hoặc env năng lực AI: demo 403 hoặc công tắc không có tác dụng; báo sớm.
- Test lâu hoặc lỗi không liên quan trong worktree bẩn: ghi nhận, không che giấu.
- Chạy tấn công trên prod làm sai dữ liệu thật: dùng tổ chức/tài khoản demo, dọn sau khi chạy.

## Quality and Testing State

- Quality gate: skipped_by_user (user_confirmed_skip)
- Testing: local suites run 2026-11-28 (see verification report); prod checks pending

## Todo

- [ ] `.\mvnw.cmd -pl app test` và ghi kết quả
- [ ] tsc/eslint/vitest pte-web và pte-practice; flutter analyze/test
- [ ] Attack checklist chạy xong, ghi vào báo cáo
- [ ] 13 kịch bản DS trên demo (DS-01e/03c/04c qua công tắc phase 05); đo NFR-05
- [ ] Kiểm env prod (không in giá trị)
- [ ] BM04 v1.2
- [ ] Báo cáo `pte-doc/plans/reports/YYMMDD-defense-unhappy-path-hardening-verification.md`
- [ ] Cập nhật AGENTS.md và trạng thái plan.md

## Bổ sung sau red-team (2026-11-27)

- **Thứ tự cắt khi thiếu thời gian (M5):** cắt trước P2 của phase 06 (entitlement reason UI) → bulk staff → tax code → option/blank validator
  → Host template remove-only → RF-18/RF-20. **Không cắt:** phase 01, FR-01/FR-03 (phase 04), phase 05, FR-11 (phase 06), phase 07.
- **Runbook prod trước defense:**
  1. Kiểm env (chỉ kiểm có hay không, không in giá trị): `PRACTICE_WEB_ENABLED`, `PRACTICE_STRICT_ENTITLEMENT_ENABLED`, `QUESTION_GEN_ENABLED`, `CHAT_AI_ENABLED`, provider chấm.
  2. Tài khoản demo: không còn user demo nào có `must_change_password=true` ngoài đúng tài khoản dùng để demo F-20. Có đủ M1, M2, Staff, Host, Proctor, Examiner, Student.
  3. Tập dượt DS-01a (submit → approve → activate), DS-03b (mất mạng xong trước `examEndTime` ≥ 5 phút), và chu trình tắt/bật AI.
  4. Sau demo: bật lại 4 công tắc AI, trả TTL đơn về 1440 phút, trả cron về giá trị cũ, kiểm banner admin đã tắt.
- **FR-14 P2 chưa có phase** (attempt gắn thiết bị, device check network/screen): chuyển sang NOTED/P3 trong spec, và chuẩn bị câu trả lời Q&A cho 3-4, 3-5.
