# Phase 7: pte-app — bỏ Enabling skills, hiển thị điểm theo kỹ năng đã thi

Covers spec FR-19, FR-20 (phía hiển thị) + quyết định user 2026-09-16: "Xóa hẳn enabling skills + sửa app mobile".

## Requirements

Hợp đồng `ReportResponse` mới do Phase 5 định nghĩa:

```json
{
  "attemptPublicId": "...", "sessionPublicId": "...", "published": true, "publishedAt": "...",
  "overall": { "skill": "OVERALL", "score": 68, "sufficientData": true },   // null khi kỳ thi không đủ 4 skill
  "communicativeSkills": [ { "skill": "READING", "score": 70, "sufficientData": true } ]  // chỉ các skill đã thi
}
```

- **Không còn** field `enablingSkills`.
- `overall == null` nghĩa là "không áp dụng" (thi 1–3 skill) → app **ẩn** cả mục Overall. `overall.sufficientData == false` vẫn là "Insufficient data" (vd AI chưa chấm xong) → hiển thị nhãn như hiện tại.
- `communicativeSkills` chỉ chứa skill đã thi → app hiển thị đúng danh sách nhận được, không tự thêm skill thiếu.

## Files

**Sửa**
- `pte-app/lib/features/report/domain/report_response.dart` — xóa `enablingSkills` (field, constructor, `fromJson`); `overall` đổi thành `SkillScoreResponse?`, parse null-safe.
- `pte-app/lib/features/report/presentation/pages/report_screen.dart` — `_ReportReadyView`: bỏ tiêu đề + vòng lặp Enabling skills (dòng 113–115); chỉ vẽ tiêu đề Overall + `SkillScoreRow` khi `report.overall != null`.
- `pte-app/lib/features/report/constants/report_strings.dart` — xóa `reportEnablingSkillsSectionTitle`.
- `pte-app/lib/core/constants/app_strings.dart` — xóa `reportEnablingSkillsSectionTitle` (dòng 234, bản trùng) nếu grep xác nhận không còn nơi dùng.
- `pte-app/lib/features/report/presentation/widgets/skill_score_row.dart` — sửa doc comment dòng 8 (bỏ nhắc `enablingSkills`).

**Sửa test**
- `pte-app/test/unit/features/report/domain/report_response_test.dart` — bỏ assert `enablingSkills`; thêm case `overall: null` parse thành `null`.
- `pte-app/test/unit/features/report/data/repositories/report_repository_impl_test.dart` — bỏ `enablingSkills` khỏi JSON mẫu.
- `pte-app/test/unit/features/report/presentation/bloc/report_bloc_test.dart` — bỏ tham số `enablingSkills`.
- `pte-app/test/widget/features/report/report_screen_test.dart` — bỏ `enablingSkills` và `expect` tiêu đề Enabling skills (dòng 68); thêm case `overall == null` → không thấy tiêu đề Overall; case 2 skill → đúng 2 `SkillScoreRow` dưới Communicative skills.

## Steps

1. Grep `enablingSkills|EnablingSkills` trong `pte-app/lib` và `pte-app/test` để có danh sách đầy đủ (kỳ vọng khớp các file trên).
2. Sửa model `ReportResponse` (field + `fromJson`), cho `overall` nullable.
3. Sửa `report_screen.dart` và string constants.
4. Cập nhật 4 file test theo hợp đồng mới.
5. `flutter analyze` và `flutter test` trong `pte-app/`.

## Tests

- `flutter test test/unit/features/report test/widget/features/report` → xanh.
- `flutter test` toàn bộ → xanh, `flutter analyze` → 0 lỗi.

## Success Criteria

- `grep -r "enablingSkills" pte-app/lib pte-app/test` → 0 kết quả.
- Widget test: báo cáo thi 4 skill hiển thị Overall + 4 dòng skill, không có tiêu đề "Enabling skills".
- Widget test: báo cáo thi 2 skill (`overall: null`) không hiển thị mục Overall, hiển thị đúng 2 dòng skill.

## Risks

- MEDIUM: Phase 7 phải merge **cùng lúc** với Phase 5 — app cũ gặp JSON thiếu `enablingSkills` sẽ crash (`null as List`), và app mới gặp backend cũ vẫn chạy được (field thừa bị bỏ qua) nhưng `overall` luôn có. Chưa deploy nên chấp nhận; chạy Phase 5 và Phase 7 liền nhau.
- LOW: Tiêu đề "Communicative skills" giữ nguyên chữ — đổi nhãn là việc UX riêng, ngoài phạm vi.
