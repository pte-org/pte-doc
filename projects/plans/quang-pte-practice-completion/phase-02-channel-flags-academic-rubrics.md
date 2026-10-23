# Phase 02: channel flags và academic rubric governance

Status: planned. Dependencies: phase 01; D01 cho applicability, D04 confirmed. Stories: US-04, US-10. Requirements: PR-02,03,05,12.

## Work packages

1. Thêm revision-level `available_for_practice` và `available_for_exam` độc lập. Không chuyển enum loại trừ nhau thành một channel selector khác. Migration additive với backfill EXAM → false/true, PRACTICE → true/false theo thứ tự practice/exam. Tìm null/legacy enum bất thường và fail/report rõ, không tự coi là public. Không backfill both=true.
2. Consumer inventory phải bao gồm `PracticeQuestionService`, exam generation/blueprint/selectors, approval/readiness checks, import/export, vendor forms/list/filter/detail/clone, score/task publication usage và API/client contracts. Migrate exam consumers sang exam flag trước deprecate pool; rolling deployment đọc tương thích có giới hạn và kiểm tra dual-write mismatch. Chọn migration number sau kiểm tra nhánh hiện tại.
3. Practice chỉ lấy APPROVED/current/SHARED và practice=true, task ready, rubric/reference/media phù hợp; đa dạng hóa selection và lưu actual selected revision. Không fallback exam pool khi thiếu câu; không thay snapshots đã được pin.
4. Academic Staff soạn rubric/reference; Academic Manager duyệt/publish. Đối chiếu role permission thực tế cho Manager/Platform Admin; không cấp academic publish cho tất cả admin mặc định. Flow draft → submitted → review changes/rejected → published → retired; published immutable, sửa tạo revision mới. Audit actor/reason/version/approval. Tách tác giả và người publish theo policy được duyệt.
5. Rubric gồm task compatibility, criterion IDs, descriptors, applicability, evidence requirements, reference provenance, invalid/empty/NA policies và examples. Score Template weights hiện tại không thay rubric này. Binding question revision → rubric revision/reference revision; gate thiếu binding trước khi practice flag có hiệu lực.
6. Vendor screens: rubric list với task/status/version; criterion editor; examples/reference editor; preview student feedback; review diff và publish dialog; question usage panel với 2 checkboxes độc lập và readiness errors. Both=true cần academic release/disclosure rằng Student có thể đã thấy câu trước exam, không bật hàng loạt mặc định.

## Rubric đề xuất để học thuật chốt

| Criterion mẫu | Áp dụng | Descriptor ví dụ | Evidence và invalid/NA |
|---|---|---|---|
| `WR_CONTENT` | Essay/summary theo task | đạt: ý đúng nguồn và đủ ý bắt buộc; cần cải thiện: bỏ ý hoặc thêm nội dung trái nguồn | Trích span bài và reference section; off-topic theo policy riêng, không chỉ dựa số từ |
| `WR_ORGANIZATION` | Task viết dài nếu phù hợp | đạt: các ý nối rõ; cần cải thiện: thứ tự khiến luận điểm khó theo dõi | Trích các câu liên quan; short-answer có thể NA |
| `WR_LANGUAGE` | Bài viết | đạt: cấu trúc và từ dùng đúng; cần cải thiện: lỗi có tác động nghĩa | Quote đúng text, correction và lý do; không invent lỗi |
| `SP_CONTENT` | Speaking có nội dung chấm được | đạt: giữ ý/đáp án yêu cầu; cần cải thiện: bỏ/đổi ý nguồn | Transcript đã xác minh + source; transcript confidence thấp → limited |
| `SP_PRONUNCIATION` | Chỉ task/audio assessor đã được duyệt | Mức đạt và ngưỡng phải học thuật định nghĩa, chưa tự gán | Audio/time range và assessor evidence; chỉ có transcript → NA, không suy ra phát âm |
| `SP_FLUENCY` | Chỉ audio có evidence phù hợp | Descriptor về độ liên tục theo policy, không chỉ tốc độ từ | Pause/timing/audio evidence; audio lỗi → limited |
| `OBJ_CORRECTNESS` | Choice/blank/order/highlight/dictation | Credit/penalty theo evaluator version được duyệt | Stable IDs/key; Gemini không quyết định lại correctness |

Mỗi criterion có examples tốt/trung bình/yếu/empty/invalid và rule mức qualitative. D06 đã chọn feedback trước; numeric AI là capability sau khi qua calibration gate, không block initial qualitative release. Không lấy bảng ví dụ này làm rubric Pearson chính thức.

## Proposed files

- `pte-api/.../itembank/{PracticeQuestionService.java,TaskTypePublicationUsageService.java,domain/enums/QuestionPool.java}`; question domain/repository/DTO/controllers; migration SQL dưới current app Flyway path.
- `pte-web/apps/vendor-web/features/questionbank`, `features/scoretemplate`, `features/questiontemplate` và academic feature phù hợp sau inventory; shared API client/types theo hiện trạng.
- Đề xuất public academic rubric/reference service/domain trong module sở hữu nội dung; practice nhận immutable DTO qua public facade, không truy cập repository nội bộ.

## Failure paths / tests to consider

Legacy backfill giữ phạm vi câu cũ; both false; both true chưa duyệt; exam không chọn practice-only; practice không chọn exam-only; unpublished rubric/media missing; draft edit race; retired revision còn trong historical session; staff tự publish; rolling reader/writer mismatch; import/export round-trip flags. Chưa viết/chạy tests.

## Design Constraints

Không xóa pool column trước kiểm tra mọi consumer và deployment compatibility. Không sửa session snapshots cũ. Published rubric/reference immutable. Academic approval và task readiness là điều kiện thực, không chỉ checkbox frontend.

## Exit criteria

Flags độc lập end-to-end, migration và exam regression plan rõ; rubric/reference governance có RBAC và versioning; đủ published fixtures cho task in-scope. Both-channel exposure có approval trước activation.

## Quality and Testing State

Quality: not evaluated. Testing: not started. TDD chưa chọn; đề xuất mạnh cho backfill/exam selection/publication permissions. Optional checks do cook xác nhận; required compile/lint theo standards khi triển khai.
