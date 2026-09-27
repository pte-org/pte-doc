# Brainstorm: PTE Score Template (V5) + sinh đề ngẫu nhiên theo template

**Date:** 2026-09-16

## Bối cảnh — trạng thái code hiện tại

Chưa có khái niệm "score template". Các mảnh nghiệp vụ nằm rải rác, không có version chung:

| Mảnh | Vị trí | Vấn đề |
|---|---|---|
| Task → skill | `pte-api/app/src/main/resources/config/task-skill-mapping.json` | Không có %; còn enabling skills cũ; RA/ASQ/FIB_L/FIB_RW gán skill khác V5 |
| Thời gian | `pte-api/app/src/main/resources/config/task-timing.json` | Speaking gần khớp V5; Listening là placeholder |
| Cờ AI | `scoring/internal/service/AiScoringTaskCatalog.java` | Hardcode Java |
| Có chấm điểm | `itembank/domain/enums/PteTaskType.java` (`scored`) | Hardcode enum |
| Số câu / dạng | — | Không có; blueprint soạn tay, không validate |
| Công thức | `reporting/internal/service/ScoreAggregationService.java` | Mọi câu trọng số bằng nhau; Overall = trung bình 4 skill |
| Tạo đề | `assessment/.../BlueprintService` → snapshot → `session` + `SessionComposition` lọc dạng | Tác giả chọn tay từng câu |

Lệch V5 cụ thể: RA (code: Reading+Speaking, V5: Speaking), ASQ (code: Listening+Speaking, V5: Listening), FIB_L (code: Listening+Writing, V5: Listening), FIB_RW (code: Reading+Writing, V5: Reading). Bảng V5 cộng dọc ≠ 100% (làm tròn) và có ô "<1%".

## Ideas Explored

1. **Gộp 1 file JSON versioned** — ít thay đổi nhất, nhưng đổi thang điểm phải deploy. *Loại: user muốn admin quản lý.*
2. **DB + admin quản lý (ScoreTemplate/ScoreTemplateItem, DRAFT→ACTIVE)** — **chọn.**
3. **JSON seed → DB, admin chỉ xem/kích hoạt** — trung gian. *Loại.*
4. **Pin template vào snapshot** vs **pin vào attempt** — **chọn snapshot**: cùng đề = cùng thang điểm.
5. **Dùng số câu để validate blueprint soạn tay (chặn/cảnh báo)** — *bị thay thế* bởi hướng 6.
6. **Sinh đề tự động: host chọn 1–4 skill → random đúng số câu mỗi dạng từ question bank** — **chọn** (user yêu cầu "chỉnh lại hệ thống luôn").
7. Chọn dạng theo **% đóng góp** skill (Reading kéo theo SWT/HIW/HCS) — *loại*, chọn **theo section**.
8. Random **mỗi thí sinh 1 đề** (chống lộ đề tốt hơn, phải đổi kiến trúc snapshot) và **mỗi batch 1 đề** — *loại*, chọn **mỗi kỳ thi 1 đề**.
9. Số câu dạng khoảng: host chỉnh / luôn lấy max — *loại*, chọn **random trong min~max**.

## User's Direction

- "Hình như hệ thống chưa có template" → xác nhận đúng.
- Template lưu **cả số câu và thời gian** theo từng dạng; **đánh dấu AI theo từng dạng**.
- Lưu **DB, platform admin quản lý**, dùng chung toàn hệ thống (host không tạo template riêng).
- Đổi thang điểm (V5→V6): **điểm lượt thi cũ giữ nguyên** — pin version **lúc publish snapshot**.
- "Khi host tạo exam cho thí sinh, hệ thống vào question bank lấy random đúng số lượng câu của mỗi dạng. Không phải lúc nào cũng thi full 4 skills, có thể tạo kì thi 1, 2, 3 skills."
- Chọn skill **theo section**; chỉ báo điểm skill đã chọn; Overall chỉ khi đủ 4 skill.
- **Mỗi kỳ thi 1 đề** chung cho mọi thí sinh; số câu **random trong khoảng min~max**.

Công thức đề xuất (user chưa phản đối):
`skill = 10 + 80 × Σ(w_dạng × avgRaw_dạng) / Σ(w_dạng có mặt trong đề)` — Overall tương tự với cột Overall %.

## Đã chốt sau vòng làm rõ

- "Host sẽ tạo kì thi, xong host sẽ assign Class nào sẽ tham gia kì thi đó" → 1 kỳ thi = 1 đề; bỏ bulk-create chia batch theo Program.
- "<1%" = 0.5; RA prep 35s; prep V5 của dạng audio-prompt = `preRecordSeconds`.
- "Thay hẳn đi, hệ thống chưa deploy nên chưa có attempt cũ" → xóa blueprint soạn tay phía host, `SessionComposition`, `AiScoringTaskCatalog`, `task-skill-mapping.json`; không cần tương thích ngược.

## Open Questions

- Reading/Listening V5 chỉ có "recommended time" — tạm giữ giới hạn per-question hiện tại; có cần ép theo cả section (23–30 / 31–39 phút) không?
- Học sinh vào Class sau khi đã assign có tự được enroll không? (spec giả định: không)
- Có tránh random lại câu thí sinh đã làm ở kỳ thi trước không? (P3)

## Risks

1. **Question bank không đủ câu** cho một dạng (vd SGD, RTS mới) → tạo kỳ thi thất bại. Cần báo thiếu rõ ràng và màn hình admin thấy tồn kho câu theo dạng.
2. **Thay đổi xuyên 5 module** (itembank, assessment, session, scoring, reporting) + FE tenant-web/vendor-web; `ScoreAggregationService` đổi công thức làm điểm hiện tại thay đổi — cần quyết định cho attempt cũ không có `scoreTemplateVersion`.
3. **Mỗi kỳ thi 1 đề** → thí sinh các kỳ sau có thể gặp lại câu cũ / lộ đề nếu bank nhỏ.
