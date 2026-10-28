# Phase 7: Kiểm chứng và handoff

Status: Not started
User stories: US-1 … US-9 (bằng chứng)
Tiêu chí §7: 1–9

## Requirements

Xác nhận backend và `pte-practice` đồng bộ, có bằng chứng thật cho từng tiêu chí §7, ghi rõ phần chưa
kiểm được, rồi viết report và commit theo từng feat (không push/merge khi chưa được yêu cầu).

## Design Constraints

- Typecheck/build không phải bằng chứng hành vi; tiêu chí 1, 2, 4–7 cần chạy thật trên trình duyệt.
- Không xoá/viết lại thay đổi chưa commit của nhánh `hung/feat/practice-revamp` (V132, auth).
- Không thêm `Co-Authored-By`/"Generated with Claude Code" vào commit/PR (quy ước của Hung); không commit `.superpowers`.
- Mọi bước bỏ qua phải ghi lý do và ranh giới.

## Related files

- `pte-api/scripts/seed-local-practice-question-bank.ps1` (`[ValidateRange(1, 3)][int]$PerTask`)
- `pte-api/docker-compose.yml`, `pte-api/docker-compose.services.yml`
- `pte-api/app/src/test/java/com/pte/ModuleStructureTest.java`, `RouteContractTest.java`
- `pte-doc/plans/reports/261024-hung-practice-timed-modes-report.md` (mới)
- `pte-doc/plans/261024-hung-practice-timed-modes/plan.md` (checkbox, trạng thái phase)
- Tuỳ chọn: ghi chú FR-PRACTICE trong `pte-doc/report/report03/` (chế độ tính giờ, chọn câu, nghe lại bản ghi)

## Steps

1. Nới seed: `PerTask` lên `ValidateRange(1, 12)` và sinh đủ biến thể câu (ít nhất cho `REPEAT_SENTENCE`)
   để kiểm tiêu chí 2; chạy lại script (re-runnable theo title).
2. Kiểm số Flyway trên `origin/dev` lần cuối; rebuild `docker compose -f docker-compose.yml -f docker-compose.services.yml up -d --build app`;
   xác nhận log áp `V133` thành công trên DB local có phiên cũ; kiểm SQL: phiên `IN_PROGRESS` cũ có `deadline_at` null.
3. Backend: `./mvnw -pl app test` full suite; ghi số test/failure/error/skipped; tách rõ lỗi có sẵn ngoài phạm vi.
4. Frontend (`pte-practice`): `npm run typecheck`, `npm run lint`, `npm run test:unit`; kiểm số dòng
   (`PracticeSessionView.tsx` và mọi file mới ≤ 300, component ≤ 150), `grep` không còn `style={{` mới,
   `session-timer`, `formatRemaining`, `deadlineAt` trong UI.
5. Trình duyệt (`npm run dev`, cổng 3014, tài khoản `pte-center.practice01`), Chrome/Edge:
   - TC1: bấm dạng bài ở Home, Practice tests, Skill list → luôn mở hộp chọn; Bắt đầu vào thẳng câu 1.
   - TC2: Repeat Sentence 10 câu → 10 câu không trùng (kiểm `source_question_public_id` trong DB);
     phiên thứ hai ưu tiên câu chưa làm; dạng bài 3 câu chọn 10 → "1/3".
   - TC3: UNTIMED ở 1 dạng mỗi kỹ năng → không có đồng hồ nào.
   - TC4: TIMED Repeat Sentence → đề phát 1 lần, không có nút phát lại/ghi lại, tự ghi, tự dừng ±1 s — đo độ dài **thật** từ WAV (số mẫu trong header `data` / `sampleRate`, hoặc
     `AudioBuffer.duration` sau `decodeAudioData`), **không** dùng `durationSeconds` số nguyên client gửi lên (red-team #3).
   - TC5: UNTIMED ghi → nghe → ghi lại → nộp; `saved_payload`/payload nộp mang media cuối.
   - TC6: nói/ im lặng → sóng sống đổi theo âm lượng; sóng tĩnh khớp; bấm sóng tua đúng vị trí.
   - TC7: chặn mạng khi upload (DevTools offline) → bản ghi còn; "Lưu lại" thành công → nộp được.
   - TC8: mở phiên cũ trước V133 → làm tiếp được, coi là UNTIMED.
   - TC9: reload giữa nhịp TIMED (chưa lưu → chạy lại; đã lưu → Xong, nghe lại được, không phát lại đề); cổng "Bắt đầu câu" xuất hiện sau reload cho cả Repeat Sentence và Read Aloud, bấm rồi đề phát đúng một lần và ghi âm tự bật (red-team #2).
   - TC10: TIMED Listening/Writing → hết giờ khoá ô trả lời, vẫn nộp được.
   - TC11: Progress/Home hiển thị `ProgressRing` (progress/segmented/empty) ở theme sáng và tối; vòng x/y và vòng đếm ngược trong phiên.
   - TC12: học viên khác gọi `GET .../items/{id}/recording` của TC5 → 404; ghi kết quả spike CORS (P3 bước 7).
6. Review diff hai repo: `git diff --check`, không conflict marker, không file sinh ra ngoài phạm vi, không đụng `pte-app`.
7. Viết report `pte-doc/plans/reports/261024-hung-practice-timed-modes-report.md`: lệnh đã chạy + kết quả,
   bảng tiêu chí §7 ↔ bằng chứng, quyết định D1–D6, kết luận dữ liệu vòng Progress/Home cần Hung duyệt, **lệch spec §4**: thiếu Web Audio thì
   không ghi âm được (WAV mã hoá từ `AudioContext`), chỉ có "decode lỗi → ẩn sóng, vẫn phát" (red-team #6),
   trạng thái quyết định mở red-team #8, rủi ro còn lại.
8. Cập nhật checkbox và `[quality: …; testing: …]` trong `plan.md`; commit theo feat:
   `feat(practice): ...` ở `pte-api` (theo phase BE), `feat(practice): ...` ở `pte-practice`, `docs(plans): ...` ở `pte-doc`.

## Tests to add

- Không thêm test sản phẩm mới; phase này chạy toàn bộ test của P1–P6 và các kịch bản tay TC1–TC12.
- Nếu TC phát hiện lỗi, test hồi quy được thêm vào phase tương ứng (ghi vào report).

## Success criteria

- Full suite BE, `tsc`, eslint, vitest của `pte-practice` xanh (tiêu chí 9), lỗi có sẵn được ghi rõ.
- Mỗi tiêu chí §7 có bằng chứng (lệnh, ảnh chụp hoặc truy vấn DB) trong report.
- Report và plan cập nhật, commit theo từng feat, không push.

## Quality and Testing State

- quality: not evaluated
- testing: not started
