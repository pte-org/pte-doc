# Phase 0: Design Contract, Offline Preview & Baseline

## Requirements

Khóa bản thiết kế làm nguồn chuẩn trước khi sửa production UI. Tạo một preview
offline cho toàn bộ task type hiện có để màn hình có thể render đầy đủ khi
`pte-api` chưa implement hoặc chưa sẵn sàng. Phase này không sửa API contract,
`TaskView`, `ExamAttemptBloc`, `TaskAnswerCubit`, `TimerService`, hay
`LockdownService`.

## Design Authority

- **Screen fidelity:** từng `screen.png` và `screen.html` tương ứng trong
  `pte-doc/design/stitch-pte-exam-app/screens/`.
- **Product semantic roles:** `pte-doc/design/stitch-pte-exam-app/DESIGN.md`.
- **Generated tokens:** `screens/36-*/tokens.json` và `screens/37-*/tokens.css`.
- **Component/layout behavior:** `screens/35-*/component-spec.md`.
- Các nguồn này có một số token trùng tên nhưng khác value. Phase 0 phải ghi
  mapping theo component: Material `primary=#004787`, component
  `brand.primary=#0B5FAE`, generic content `960px`, reading workstation
  `1160px`. Không flatten thành một token duy nhất.
- Ghi quyết định này vào `design-authority.md` và dùng file đó làm contract
  review artifact cho mọi phase sau. Fallback của hai task thiếu asset là
  quyết định phạm vi đã chấp nhận, không phải placeholder.

## Design Contract

1. Màu dùng đúng semantic token của design: Material roles, `brand`,
   `surface`, `border`, `text`, `status`, `interactive`; giữ riêng các role
   có value khác nhau.
2. `AppTypography` có 10 application style từ `DESIGN.md`: `headline-lg`,
   `headline-md`, `instruction-bold`, `body-passage`, `body-regular`,
   `body-bold`, `timer-tabular`, `label-meta`, `label-bold`, `caption`,
   font Arimo và thông số đúng nguồn. Generated `display-*` styles chỉ thêm
   khi screen/component reference yêu cầu.
3. Spacing/radius/border/shadow lấy từ token thật, không thay bằng scale tự
   nghĩ. Header và footer đều cao `56px` theo `DESIGN.md` và HTML canonical;
   generated footer `64px` chỉ được ghi nhận là conflict note. Button phải
   được đối chiếu với screen export/component token; generic content `960px`,
   reading workstation `1160px` theo variant. Visual golden chuẩn là
   `2560x2048`, DPR 1, scroll `(0,0)`; runner nhỏ hơn phải ghi fixed scale.
4. Mỗi task screen phải có đủ vùng mà mockup của family đó thể hiện: persistent
   exam header, task banner/meta, instruction/scoring content, stimulus,
   response interaction, action/help/status content khi có trong mockup, fixed
   footer và chrome footer strip khi có trong mockup.
5. `TaskView` là input runtime hiện tại. Khi API chưa có dữ liệu, preview dùng
   fixture đầy đủ; không tạo API giả trong production và không để màn hình
   rơi về placeholder/empty state cho task đã có trong catalog. Fixture
   `WRITE_ESSAY` phải dùng đúng task type; không dùng `WRITE_ESSAY_V2`.

## Steps

1. Validate and update the checked-in `design-coverage-matrix.md` for all 23
   task types: current screen, template, stimulus/response variant, design
   reference, missing-design decision and visual states to verify.
2. Xác nhận 21 task screen có mockup trực tiếp. Hai task
   `SUMMARIZE_GROUP_DISCUSSION` và `RESPOND_TO_A_SITUATION` hiện chưa có
   screenshot riêng trong bundle; dùng audio-prompt pattern gần nhất,
   ghi rõ là design-gap fallback, không tự phát minh token/layout mới.
3. Chụp baseline UI của các screen hiện tại và snapshot payload trước khi
   migrate. Baseline chỉ là bằng chứng hồi quy, không phải visual target.
4. Tạo `ExamUiPreviewCatalog`/fixture offline cho đủ 23 task, gồm text,
   audio/image reference, options, blank groups, timing, word limits và các
   trạng thái tương tác đại diện. Normalize `WRITE_ESSAY` and resolve media
   locally or through a deterministic test asset resolver. Fixture phải đi qua
   cùng screen/dispatcher như runtime.
   Record fixtures phải có timing/audio giả lập deterministic; Describe Image
   phải dùng asset local/test resolver, không dùng Picsum/network. Preview chỉ
   ghi nhận callback/action và không gọi microphone, outbox, API hay force-submit
   thật.
5. Triage các lỗi `flutter analyze`/`flutter test` có sẵn; tách lỗi baseline
   khỏi lỗi do refactor. Lỗi compile/test nền chặn phase nếu chưa có waiver
   được ghi rõ, và không được báo cáo là regression của migration.
6. Assign every baseline compile/test blocker to this preflight: fix it before
   migration or stop with a named waiver. Phase 8 cannot claim final
   `analyze/test` pass while an unclassified baseline blocker remains.

## Success Criteria

- [ ] Có coverage matrix cho đủ 23 task type; không có task type nào chỉ render
  placeholder.
- [ ] Có fixture offline cho đủ 23 task và một preview entry point để render
  từng task không cần gọi `pte-api`.
- [ ] Preview có media/timing deterministic cho đủ 8 record task, không có
      network side effect và không đẩy dữ liệu vào outbox thật.
- [ ] Design contract ghi mapping đúng: Material primary `#004787`, component
  brand primary `#0B5FAE`, header/footer `56px`, generic `960px`,
  reading max-width `1160px`, typography 10 style từ `DESIGN.md`.
- [ ] Baseline payload snapshot được lưu trước migration.
- [ ] Baseline analyze/test report được lưu; mọi lỗi đã phân loại là existing
  hoặc refactor-caused.

## Quality and Testing State

- **Quality gate:** not evaluated. Cook chạy `/ck:quality --gate` sau phase.
  Checks: matrix 23 task, fixture completeness, design-token authority, no
  placeholder path, baseline report.
- **Testing:** not started. Chạy preview smoke test cho 23 task và snapshot
  payload baseline; không yêu cầu API thật.

## File Ownership

**Files exclusively owned by this phase:**

- `pte-doc/projects/plans/quang-exam-ui-design-system/design-authority.md`
- `pte-doc/projects/plans/quang-exam-ui-design-system/design-coverage-matrix.md`
- `pte-doc/projects/plans/quang-exam-ui-design-system/baseline-payloads.json`
- `lib/features/exam_attempt/dev/exam_ui_preview_catalog.dart`
- `test/fixtures/exam_attempt_ui_fixtures.dart` (nếu fixture test không thể
  dùng chung catalog trong `lib`)
- `test_manual/exam_attempt_ui_preview_test.dart` (hoặc test tương đương theo
  cấu trúc hiện tại)
- `pte-doc/projects/plans/quang-exam-ui-design-system/baseline-analyze.txt`
- `pte-doc/projects/plans/quang-exam-ui-design-system/baseline-test.txt`
- baseline test/analyzer repair files, only when required to clear the
  preflight blocker and unrelated to API/state contracts

**Files not modified by this phase:**

- `pte-api` source hoặc generated API client
- `lib/features/exam_attempt/domain/task_view.dart`
- `lib/features/exam_attempt/presentation/bloc/*`
- `lib/features/exam_attempt/presentation/cubit/task_answer_cubit.dart`
- `lib/features/exam_attempt/domain/timer*`
- `lib/features/exam_attempt/*/presentation/cubit/*` production state logic

## Cook State

- **Status:** completed.
- **Testing:** baseline captured; final full suite passed (`582` tests).
- **Quality:** manual gate passed; scope and ownership checks found no blocker.
