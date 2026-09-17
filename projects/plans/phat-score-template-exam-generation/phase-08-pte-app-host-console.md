# Phase 8: pte-app — Host console: tạo kỳ thi theo skill + assign Class, xóa hẳn question bank/blueprint authoring

Covers FR-08, FR-15, FR-16, FR-17 phía `pte-app` (Flutter) — console host sống thứ 2 (song song `tenant-web`) tạo session qua snapshot + composition, phải migrate đồng bộ để không còn client nào gọi luồng cũ đã bị xóa ở Phase 3/5. **Mở rộng bắt buộc (quyết định user 2026-09-17, "chỉ platform thao tác question bank"):** `host_console_page.dart` hôm nay có 2 nút "Question bank"/"Exam blueprints" mở thẳng `QuestionListPage`/`BlueprintListPage`, được hậu thuẫn bởi nguyên module `pte-app/lib/features/authoring/**`. Vì `QuestionController`/`BlueprintController`/`SnapshotController` đã bị khóa còn platform-only (Phase 1, Phase 5) và `pte-app` không có — và sẽ không có — bất kỳ bề mặt UI platform-admin nào, module `features/authoring` trở thành code chết gọi API sẽ luôn trả 403: xóa hẳn nguyên module (lib + test), không giữ lại phần nào.

## Requirements

Host dùng app tạo kỳ thi bằng cách chọn 1–4 skill (không còn nhập `snapshotPublicId` tay, không còn xem/tạo được câu hỏi hay blueprint nào); màn chi tiết kỳ thi không còn phần chỉnh composition, thay bằng assign/unassign Class; `host_console_page.dart` không còn 2 nút Question bank/Exam blueprints; toàn bộ `features/authoring` (lib + test) bị xóa sạch, không còn tham chiếu nào từ `main.dart` hay chuỗi dùng chung.

## Files

**Sửa**
- `pte-app/lib/features/scheduling/domain/session_types.dart` — `CreateSessionInput` đổi `snapshotPublicId` → `skills: Set<String>` (+ optional `examMode`/`lockdownMode`/`capacity` nếu muốn parity với backend); xóa `CompositionItemInput`, `SetCompositionInput`, `SessionCompositionItem`, `SnapshotTaskOption`; `ExamSession` bỏ field `composition`.
- `pte-app/lib/features/scheduling/domain/repositories/scheduling_repository.dart` — bỏ `setComposition`/`loadSnapshotOptions`; thêm `loadAssignedClasses(sessionPublicId)`, `assignClass(sessionPublicId, classPublicId)`, `unassignClass(sessionPublicId, classPublicId)`.
- `pte-app/lib/features/scheduling/data/repositories/scheduling_repository_impl.dart` — xóa 2 method cũ; `createSession()` gửi `skills` thay vì `snapshotPublicId`; thêm implementation gọi `/sessions/{id}/classes` cho 3 method mới; xác minh `_sessionsPath` có đúng path thật hay không (xem Step 1) và sửa nếu cần.
- `pte-app/lib/features/scheduling/data/models/session_model.dart` — bỏ parse `composition` (nếu có), map field mới nếu backend trả thêm.
- `pte-app/lib/features/scheduling/presentation/bloc/session_create_bloc.dart` / `session_create_event.dart` / `session_create_state.dart` — nhận `skills` thay vì `snapshotPublicId`.
- `pte-app/lib/features/scheduling/presentation/pages/session_create_page.dart` — thay `TextField` nhập snapshot ID bằng 4 checkbox chọn skill.
- `pte-app/lib/features/scheduling/presentation/bloc/session_detail_bloc.dart` / `session_detail_event.dart` / `session_detail_state.dart` — bỏ state/event liên quan `loadSnapshotOptions`/`updateComposition`; thêm state/event cho load/assign/unassign Class.
- `pte-app/lib/features/scheduling/presentation/pages/session_detail_page.dart` — bỏ hẳn khối `CheckboxListTile` chọn task type + nút "Save Composition"; thêm section assign/unassign Class (disable khi session không SCHEDULED).
- `pte-app/lib/features/scheduling/scheduling_module.dart` — bỏ đăng ký `LoadSnapshotOptions`/`UpdateSessionComposition`; thêm đăng ký usecase mới cho assign/unassign/list Class.
- `pte-app/lib/features/host_console/presentation/pages/host_console_page.dart` — xóa 2 `ElevatedButton` "Question bank" (mở `QuestionListPage`) và "Exam blueprints" (mở `BlueprintListPage`) cùng 2 import tương ứng từ `features/authoring`; giữ nguyên các nút còn lại (Sessions, Notification audit...).
- `pte-app/lib/main.dart` — xóa `import 'package:pte_app/features/authoring/authoring_module.dart';` và lời gọi `setupAuthoringModule();`.
- `pte-app/lib/core/constants/app_strings.dart` — xóa các hằng số **chỉ** dùng bởi `features/authoring` (nhóm `questions*`, `createQuestion*`, `authoring*`, `selectQuestionType`, `mcReadingSingleLabel`/`readAloudLabel`/`writeEssayLabel`, `create*Title` liên quan, `referenceAnswerLabel`/`*WordCount*`, nhóm `blueprint*`, `publishBlueprint`/`publishConfirmation*`/`publishFailure`, `snapshot*`) — **giữ nguyên** các hằng dùng chung với feature khác (`cancel`, `retry`, `edit`, `publish` — đã grep xác nhận `scheduling`/`scoring_review`/`live_proctor`/`host_audit` đều tái sử dụng, không được xóa).

**Xóa**
- `pte-app/lib/features/authoring/**` (toàn bộ: `authoring_module.dart`, `data/`, `domain/`, `presentation/` — 41 file) — module hậu thuẫn question bank/blueprint authoring phía host, không còn đường vào nào sau khi `QuestionController`/`BlueprintController`/`SnapshotController` chỉ còn platform-only (Phase 1/5) và không có UI platform-admin nào trong `pte-app`.
- `pte-app/test/widget/features/authoring/**` (`question_list_page_test.dart`, `blueprint_pages_test.dart`, `create_mc_reading_single_page_test.dart`, `create_text_question_pages_test.dart`).
- `pte-app/test/unit/features/authoring/**` (toàn bộ subfolder `presentation/`, `data/`, `domain/`, `authoring_module_test.dart`).
- `pte-app/lib/features/scheduling/domain/usecases/load_snapshot_options.dart`
- `pte-app/lib/features/scheduling/domain/usecases/update_session_composition.dart`

**Thêm**
- `pte-app/lib/features/scheduling/domain/usecases/load_assigned_classes.dart`
- `pte-app/lib/features/scheduling/domain/usecases/assign_class.dart`
- `pte-app/lib/features/scheduling/domain/usecases/unassign_class.dart`

## Steps

1. Xác minh path thật `SchedulingRepositoryImpl._sessionsPath` (`/api/scheduling/sessions`) có bị lệch với controller thật (`/sessions`) như đã xác nhận ở `pte-web` hay không — kiểm tra cấu hình `ApiClient`/base URL và (nếu có) tài liệu gateway của `pte-app`; nếu xác nhận lệch, sửa `_sessionsPath` cùng lúc vì luồng tạo-kỳ-thi-theo-skill/assign-Class mới bắt buộc phải gọi đúng path.
2. Đổi `CreateSessionInput`/`session_create_page.dart`/`session_create_bloc.dart` sang `skills` (4 checkbox SPEAKING/WRITING/READING/LISTENING), bỏ ô nhập snapshot ID.
3. Xóa `SetCompositionInput`/`CompositionItemInput`/`SessionCompositionItem`/`SnapshotTaskOption` khỏi `session_types.dart`; xóa 2 usecase `load_snapshot_options.dart`/`update_session_composition.dart`; gỡ khỏi `scheduling_repository.dart`/`scheduling_repository_impl.dart`/`scheduling_module.dart`.
4. Gỡ khối UI composition (`CheckboxListTile` chọn task type + nút Save Composition) khỏi `session_detail_page.dart`; gỡ state/event tương ứng khỏi `session_detail_bloc.dart`.
5. Thêm 3 usecase mới (`load_assigned_classes`, `assign_class`, `unassign_class`) + implementation trong `SchedulingRepositoryImpl` gọi `/sessions/{id}/classes` (Phase 4); đăng ký DI trong `scheduling_module.dart`.
6. Thêm UI assign/unassign Class vào `session_detail_page.dart` (danh sách Class đã assign + nút assign Class mới, disable khi `session.status.canOpen == false` tức không còn SCHEDULED — dùng lại enum `SessionStatus` đã có `canOpen`/`canClose`, hoặc thêm getter `isScheduled` nếu rõ ràng hơn).
7. Gỡ 2 `ElevatedButton` "Question bank"/"Exam blueprints" khỏi `host_console_page.dart` cùng 2 import `features/authoring`; xóa `import`/`setupAuthoringModule()` khỏi `main.dart`.
8. Xóa nguyên `lib/features/authoring/**` + `test/widget/features/authoring/**` + `test/unit/features/authoring/**`; grep lại `authoring` trong toàn repo `pte-app` để xác nhận không còn file nào tham chiếu (comment nhắc tới "authoring" trong `exam_attempt` là mô tả thuần túy, không phải import — giữ nguyên, không phải xóa).
9. Dọn `app_strings.dart`: xóa các hằng chỉ dùng bởi `features/authoring` (đã liệt kê ở "Files > Sửa"), grep từng hằng trước khi xóa để chắc chắn không có feature khác dùng chung (đặc biệt `cancel`/`retry`/`edit`/`publish` — PHẢI giữ lại).
10. Chạy `flutter analyze` + `flutter test` toàn app, sửa mọi test cũ còn dựng `SetCompositionInput`/`CompositionItemInput`/`SnapshotTaskOption` (bao gồm `test/unit/features/scheduling/data/scheduling_repository_test.dart` — test hiện có của nó gọi `/api/authoring/snapshots/snap-1` qua `loadSnapshotOptions`, vốn đã bị xóa ở bước 3, phải xóa/viết lại case đó).

## Tests

- Cập nhật/viết lại test cho `session_create_bloc`/`session_create_page` (nếu có sẵn theo pattern Plan A Phase 7): submit với `skills` rỗng → lỗi validate; submit hợp lệ → gọi đúng usecase với đúng `skills`.
- Cập nhật/viết lại test cho `session_detail_bloc`: load session không còn gọi `loadSnapshotOptions`; thêm test cho luồng load/assign/unassign Class (bloc chuyển state đúng khi usecase thành công/thất bại).
- Test `SchedulingRepositoryImpl` (nếu có sẵn theo pattern mock `ApiClient`): `createSession` gửi đúng body `{skills, ...}` không còn `snapshotPublicId`; `assignClass`/`unassignClass`/`loadAssignedClasses` gọi đúng path `/sessions/{id}/classes`; xóa case cũ test `loadSnapshotOptions` (usecase đã bị xóa).
- Widget test `host_console_page` (nếu có sẵn): xác nhận không còn `find.text('Question bank')`/`find.text('Exam blueprints')`, các nút còn lại (Sessions, Notification audit...) vẫn render đúng.
- `flutter analyze` sạch; `flutter test` toàn bộ app xanh (không chỉ module `scheduling`) — theo đúng tiền lệ verify cuối của Plan A Phase 7.

## Success Criteria

- Tạo kỳ thi từ app không còn ô nhập snapshot ID; submit gọi đúng request body theo hợp đồng Phase 3.
- Màn chi tiết kỳ thi không còn UI chọn task type/lưu composition; có UI assign/unassign Class, disable đúng khi session không SCHEDULED.
- `host_console_page.dart` không còn nút nào mở question bank/blueprint; `pte-app/lib/features/authoring` không còn tồn tại trên đĩa.
- `grep -r "SetCompositionInput\|CompositionItemInput\|SessionCompositionItem\|SnapshotTaskOption\|loadSnapshotOptions\|updateSessionComposition\|features/authoring\|QuestionListPage\|BlueprintListPage" pte-app/lib pte-app/test` → 0 kết quả.
- `flutter analyze` sạch; `flutter test` toàn app xanh.

## Risks

- MEDIUM: Không xác minh được từ khảo sát tĩnh liệu `_sessionsPath` của `pte-app` có thật sự lệch path như `pte-web` hay không (có thể có proxy khác) — mitigation: Step 1 bắt buộc xác minh thật (gọi thử hoặc đọc cấu hình) trước khi sửa, tránh sửa nhầm một path đang chạy đúng.
- LOW: `session_detail_bloc`/`state` hiện gắn chặt với luồng composition (khởi tạo `_selected` từ `session.composition` trong `session_detail_page.dart`) — xóa không cẩn thận có thể để sót state rác; mitigation: xóa toàn bộ field liên quan `composition` khỏi `SessionDetailData`/tương đương trước khi coi phase xong, không chỉ ẩn UI.
- MEDIUM (mới, 2026-09-17): Xóa nguyên module `features/authoring` (41 file lib + toàn bộ test tương ứng) là thay đổi có diện rộng lớn nhất của phase — mitigation: grep `authoring` trên toàn `pte-app` (không chỉ `lib/`) sau khi xóa để xác nhận 0 kết quả thật (trừ 2 comment thuần túy trong `exam_attempt`, không phải import), chạy `flutter analyze` ngay sau bước xóa (trước khi làm tiếp phần assign-Class) để bắt lỗi biên dịch sớm thay vì dồn tới cuối phase.
- LOW: Dọn `app_strings.dart` có rủi ro xóa nhầm hằng dùng chung — mitigation: grep từng tên hằng riêng lẻ trước khi xóa (không xóa theo khối dòng mù quáng), đặc biệt các tên ngắn/generic (`cancel`, `retry`, `edit`, `publish`) đã xác nhận bị 4+ feature khác dùng chung, không được đụng.
