# Phase 9: Chỉnh rubric (D1), quy trình duyệt và audit kích hoạt

## Mục tiêu

Cho phép chỉnh **tham số số học** của rubric thành **phiên bản mới** (không sửa đè phiên bản cũ): Academic Staff tạo bản nháp và gửi duyệt; Academic Manager duyệt (**duyệt = kích hoạt ngay**) hoặc từ chối (có lý do); Academic Manager và Platform Admin chỉnh thì kích hoạt ngay không qua duyệt.
Trước khi kích hoạt, UI hiện **diff so với phiên bản ACTIVE** và bắt xác nhận; mỗi lần kích hoạt ghi **một dòng audit**. Phiên bản mới chỉ áp dụng cho mẫu đề tạo sau đó; báo cáo đã publish và mẫu đề đã tạo không đổi.

## Stories/FR covered

- S5; FR-09 (chỉ sửa trọng số tiêu chí, các mức Form không chồng nhau có ít nhất một mức đạt tối đa, bật/tắt điều kiện chặn; lưu tạo phiên bản mới)

## Files to read first

- `D:\GitHub\pte-org\docs\CODING_STANDARDS_API.md`, `API_RESPONSE_SETUP.md`, `COMMON_EXCEPTION_SETUP.md`, `TEST_SCENARIOS_IAM.md`, `CODING_STANDARDS_WEB.md`
- Phase 2: `ScoringRubricVersion`, `ScoringRubricActivationAudit`, `RubricVersionRepository`, `RubricParametersValidator`, trigger V32 (đặc tả chính xác cột và chuyển trạng thái), controller đọc
- Mẫu quy trình duyệt: `pte-api/app/src/main/java/com/pte/assessment/internal/controller/ExamDefinitionController.java` (`PATCH /{publicId}/status` với `ExamDefinitionStatusRequest {action, reason?}`, `StatusReasonRequiredException`), `ExamDefinitionAdminService.java`, `ExamDefinitionCommandService.java`
- `pte-web/apps/vendor-web/features/scoretemplate/` (`ActivateTemplateModal.tsx`, `TemplateToolbarActions.tsx`, `ScoreTemplateEditorView.tsx`, `_ScoreTemplateItemTable.tsx`, `draftSnapshot.ts`, `serialization.ts`, `skillWeightTotals.ts`, `errorMessage.ts`), `features/examstudio/components/_PendingReviewNotice.tsx`, `lifecycleMoves.ts`
- Phase 7 (feature `scoringrubric`), Phase 8 (bộ chọn rời rạc, `FormRule.bandFor`)

## Implementation steps

1. **Máy trạng thái**: `DRAFT -> PENDING -> ACTIVE | REJECTED`; `ACTIVE -> RETIRED` khi bản khác được kích hoạt; `DRAFT/REJECTED -> DRAFT` (sửa lại); `DRAFT` bỏ bằng xóa mềm (`BaseEntity.deleted`). **Không có trạng thái APPROVED riêng** (U4): duyệt `PENDING` = kích hoạt.
   `RubricVersionCommandService` (`internal/rubric/service`; tách `internal/rubric/workflow` nếu sát trần 15): `createDraft` (từ bản ACTIVE hoặc bản bất kỳ, tham số **đầy đủ** như Phase 2), `updateDraft` (chỉ DRAFT/REJECTED; `@Version`/`lock_version` chống ghi đè), `submit`, `reject` (bắt buộc `reason` <= 1000), `activate`. Dấu thời gian bằng `Clock` inject.
2. **Kích hoạt (MEDIUM-1, U4)** trong **một giao dịch** theo đúng thứ tự: (i) khóa hàng ACTIVE hiện hành; (ii) kiểm tra xác nhận diff (bước 3); (iii) **câu lệnh native UPDATE chuyển bản ACTIVE cũ sang RETIRED rồi flush** (chỉ mục duy nhất từng phần được kiểm tra theo từng câu lệnh, không dựa vào thứ tự flush ngầm của Hibernate);
   (iv) đặt bản mới ACTIVE với `activated_at` và **`approver_user_public_id` = người gọi** (đường `PATCH .../status` với `ACTIVATE`; áp dụng cả duyệt `PENDING` lẫn kích hoạt ngay từ `DRAFT`); (v) INSERT một dòng `scoring_rubric_activation_audits` (ai, khi nào, bản trước, tóm tắt diff). Xử lý va chạm đồng thời bằng khóa và thử lại có giới hạn.
   **Service guard bất biến**: không sửa/xóa ACTIVE/RETIRED (lớp hai là trigger V32).
3. **Diff và xác nhận trước khi kích hoạt (U4)**: `GET /versions/{publicId}/diff` (so với ACTIVE hiện hành: liệt kê từng task type/tiêu chí/Form band/cổng/phiên bản bảng Azure đổi từ-sang) trả thêm `diffDigest` (băm ổn định của diff và `lock_version` hai bên). `ACTIVATE` yêu cầu thân `{expectedActiveVersionPublicId, confirmedDiffDigest}`;
   server tính lại diff và **từ chối nếu digest lệch hoặc ACTIVE đã đổi** (người dùng phải xem diff mới). Không có đường kích hoạt bỏ qua xác nhận.
4. **Quyền theo hành động**: tạo/sửa/gửi duyệt bản nháp: `ACADEMIC_STAFF`, `PLATFORM_AUTHOR`, `ACADEMIC_MANAGER`, `PLATFORM_ADMIN`; duyệt (ACTIVATE từ PENDING), từ chối, kích hoạt ngay: `ACADEMIC_MANAGER`, `PLATFORM_ADMIN` (người duyệt không được là tác giả của chính bản nháp đó trừ `PLATFORM_ADMIN`; có test); Staff không bao giờ kích hoạt được.
5. **API ghi** (`/api/v1/scoring-rubrics`): `POST /versions`, `PUT /versions/{publicId}` (kèm `expectedLockVersion`), `PATCH /versions/{publicId}/status` với `{action: SUBMIT | ACTIVATE | REJECT | DISCARD, reason?, expectedActiveVersionPublicId?, confirmedDiffDigest?}` (`reason` bắt buộc khi REJECT; digest bắt buộc khi ACTIVATE), `GET /versions/{publicId}/diff`.
   DTO record trong `internal/rubric/dto`; exception miền (trạng thái không hợp lệ, tự duyệt, va chạm, digest lệch) theo `COMMON_EXCEPTION_SETUP.md`, message/mã trong `RubricConstants`.
6. **Quy tắc tham số** (mở rộng `RubricParametersValidator` cho mọi đường ghi, MEDIUM-3, LOW-3): trọng số **số nguyên 0-10**; **tiêu chí cổng phải > 0**; **tổng trọng số mỗi task type > 0**; Form band không chồng lấn, có ít nhất một band đạt tối đa của Form, không vượt thang; `gates` chỉ cho tiêu chí cổng của catalog; khóa lạ bị từ chối;
   quy tắc "đúng một câu" của SWT và quy tắc phụ cơ học không chỉnh được (chỉ khoảng số từ); mô tả mức, thang Pearson, nguồn chấm, prompt không có đường chỉnh (D2/D3). **Read Aloud Content**: trọng số chỉnh được nhưng thang động theo N (không chỉnh được thang). **Giới hạn kích thước JSON tham số và số phần tử** theo `RubricConstants`, kiểm tra **trước khi lưu**.
   Lưu `catalog_version` hiện hành khi tạo; quy tắc cấu trúc khác với code như Phase 2.
7. **Không có hành động ghim lại mẫu DRAFT** (LOW-4): mẫu đề mới tạo/clone ghim bản ACTIVE lúc đó (Phase 2); không thêm `PATCH /exam-definitions/{id}/rubric`.
8. **FE vendor-web** (`features/scoringrubric/` mở rộng; route `app/(dashboard)/admin/scoring-rubric/versions/page.tsx` và `.../versions/[publicId]/page.tsx`): danh sách phiên bản; màn chi tiết/chỉnh gồm `_VersionStatusBar` (hành động theo role/trạng thái), `_TraitWeightEditor` (bộ tăng giảm/thanh trượt rời rạc 0-10, hiện trọng số mặc định Pearson để so; **với RA Content hiện chú thích "tiêu chí này theo độ dài đoạn văn: trọng số chỉnh được, thang động"**),
   `_FormBandEditor` (kéo biên giữa các band thay cho nhập số), `_GateToggle` (cảnh báo tác động), `_VersionDiffPanel`, **`_ActivateConfirmDialog` (hiện diff và bắt tick xác nhận trước khi gửi `ACTIVATE` kèm `confirmedDiffDigest`)**, `_RejectDialog` (bắt buộc lý do), `_PendingNotice`, `_ActivationHistory` (đọc audit nếu có endpoint; nếu không thì hoãn), bản ACTIVE/RETIRED chỉ đọc. Hằng/nhãn/lỗi vào constants/i18n (`errorMessage.ts` theo mẫu `scoretemplate`). Component <= 150 dòng.
9. **api-client**: hàm/kiểu cho endpoint ghi và diff.
10. **Test backend**: máy trạng thái (mọi chuyển hợp lệ/không), phân quyền theo hành động (Staff không kích hoạt; Manager/Admin kích hoạt), REJECT bắt buộc lý do, `lock_version` va chạm, tự duyệt bị chặn, **digest lệch/ACTIVE đã đổi bị từ chối**, **mỗi ACTIVATE tạo đúng một dòng audit và đặt `approver_user_public_id`**, validator (Form chồng lấn/không band tối đa, trọng số ngoài 0-10, cổng = 0, tổng = 0, khóa lạ, JSON quá lớn),
    bất biến (sửa ACTIVE qua service và qua SQL: bị chặn); **Postgres IT gồm ca thứ tự flush** (kích hoạt khi chưa retire bản cũ thất bại; đúng quy trình native-update-flush rồi activate thành công; hai kích hoạt song song: đúng một ACTIVE); tích hợp chính: **đổi rubric không đổi snapshot báo cáo đã publish** và **mẫu đề đã tạo giữ ghim**. Cập nhật `ApiInventoryExportTest`.
11. **Test FE**: dựng tham số từ trạng thái trình chỉnh, kiểm tra khoảng Form/trọng số phía FE chỉ để báo lỗi sớm, bật/tắt hành động theo role/trạng thái, tính diff hiển thị, nút ACTIVATE bị khóa cho tới khi xác nhận.

## Acceptance criteria

- Staff tạo nháp và gửi duyệt được; không duyệt/kích hoạt (403). Manager duyệt (= kích hoạt) hoặc từ chối (bắt buộc lý do); Manager/Admin kích hoạt ngay không qua duyệt.
- Kích hoạt đòi hỏi xác nhận diff (`confirmedDiffDigest`); digest sai/ACTIVE đã đổi bị từ chối; UI hiện diff và bắt xác nhận.
- Mỗi lần ACTIVATE tạo đúng một dòng audit (ai, khi nào, bản trước, tóm tắt diff) và đặt `approver_user_public_id`; audit không sửa/xóa được.
- Bản ACTIVE cũ -> RETIRED bằng native update + flush trước khi bản mới ACTIVE trong một giao dịch; luôn đúng một ACTIVE (IT đồng thời và ca thứ tự flush).
- Không sửa/xóa được ACTIVE/RETIRED; lưu thay đổi luôn tạo phiên bản mới.
- Tham số không hợp lệ (số nguyên 0-10, cổng > 0, tổng > 0, Form band, khóa lạ, kích thước) bị từ chối với mã chuẩn; RA Content hiện chú thích độ dài.
- Mẫu đề tạo trước khi kích hoạt giữ ghim; báo cáo đã publish không đổi; không có đường ghim lại mẫu DRAFT.
- Không có đường chỉnh mô tả mức, thang Pearson hay prompt; FE/BE test và ratchet xanh.

## Validation commands

```powershell
cd D:\GitHub\pte-org\pte-api
.\mvnw.cmd -pl app -DskipTests compile
.\mvnw.cmd -pl app test -Dtest="RubricVersionCommandServiceTest,RubricVersionControllerTest,RubricParametersValidatorTest,RubricActivationAuditTest,RubricVersionConcurrencyIT,RubricPinningSnapshotIT,ApiInventoryExportTest"
.\mvnw.cmd -pl app test -Dtest="PackageDensityTest,SourceFileSizeTest,NoDirectClockAccessTest,ModuleStructureTest"
.\mvnw.cmd -pl app test      # toàn suite

cd D:\GitHub\pte-org\pte-web
pnpm --filter vendor-web typecheck; pnpm --filter vendor-web lint; pnpm --filter vendor-web test
```

## Design Constraints

- `docs/CODING_STANDARDS_API.md`, `API_RESPONSE_SETUP.md`, `COMMON_EXCEPTION_SETUP.md`, `TEST_SCENARIOS_IAM.md`, `CODING_STANDARDS_WEB.md` bắt buộc; message/mã trong `*Constants.java`; `Clock` inject; file <= 300 dòng; `internal/**` <= 15 class/gói.
- D1 chỉ chỉnh số; không mô tả mức, thang Pearson, nguồn chấm hay prompt; không văn bản tự do ngoài `reason` của từ chối; không tham số nào vào prompt.
- ACTIVE/RETIRED bất biến; mọi lưu tạo phiên bản mới; tham số luôn đầy đủ trong hàng.
- Duyệt = kích hoạt; không bỏ qua xác nhận diff; mọi ACTIVATE có audit và `approver_user_public_id`.
- Đổi rubric không đổi điểm đã publish hay mẫu đề đã tạo; rubric dùng chung toàn nền tảng, chỉ vendor quản lý; Host/tenant không thấy bản nháp.
- Chuyển trạng thái qua `PATCH .../{id}/status` với `{action, reason?}` (quy ước dự án).
- FE: bộ chọn rời rạc/kéo thả cho đầu vào số; không Playwright (tsc, eslint, vitest). Không có bước release/deploy.

## Quality and Testing State

- Quality: skipped_by_user (decision: user_confirmed_skip)
- Testing: passed with boundaries (2026-11-05). Clean test-compile BUILD SUCCESS; full app: **4602 tests, 0 failures, 0 errors, 73 skipped**, read from 519 XML files. Focused command/controller/validator/ratchet/read/V32: 136 passed; final regression after extra limits/role tests: 81 passed, including 4 RubricVersionConcurrencyIT (JPA/native flush, concurrent activation, pin/published JSON invariance, soft deletion/version numbering), 0 skipped. Vendor vitest 303, api-client 685; package tsc exit 0. Vendor tsc has only existing generated `.next/types/validator.ts(62,39) TS2307`; vendor eslint 0 errors/2 existing warnings. Browser/Next build/live AI/real human calibration not run. Quality skipped_by_user.

## Risks

- Kích hoạt đồng thời hoặc thứ tự flush vi phạm chỉ mục: native update + flush, khóa, thử lại giới hạn, IT.
- Staff tự duyệt qua tài khoản khác: chặn theo `author_user_public_id`; audit ghi người duyệt.
- Diff không phản ánh hết tác động lên điểm: diff liệt kê từng thay đổi tham số; xác nhận bắt buộc.
- Mở rộng tham số sau này phải tăng `catalog_version` và tương thích bản đã lưu: validator theo `catalog_version` của từng bản.

## Preflight / quyết định khi làm (2026-11-05)

- Đã đọc đủ các chuẩn API/WEB, API_RESPONSE_SETUP, COMMON_EXCEPTION_SETUP, TEST_SCENARIOS_IAM; plan/spec và phase 1-8; sibling lifecycle, codec/validator, DTO, CurrentUser và mẫu scoretemplate.
- D1 chỉ số/boolean, không đổi cấu trúc/thang/mô tả. RubricVersionService là lõi lifecycle; đường API mới kiểm role, lock và digest trong giao dịch. Native retire + flush giữ nguyên. Kiểm tự duyệt với PENDING; DRAFT của Manager có đường kích hoạt ngay theo quyết định spec.
- Checklist dưới đây được ghi trước triển khai; mỗi mục sẽ chốt bằng chứng hoặc ghi lệch/chưa.

- D1 siết trọng số > 0 cho mọi trait có cổng trong catalog, kể cả cổng tắt (theo ràng buộc cứng của yêu cầu); sửa test cũ từng cho phép gate tắt có weight=0. Test tổng weight=0 chuyển sang RS (không cổng), giữ nguyên mục tiêu kiểm tra.
- `defaultWeight` chỉ là tham chiếu catalog trong API đọc để FE hiển thị; `weight` và mọi điểm hiệu lực vẫn từ hàng phiên bản. Thêm metadata `lockVersion`, audit-read endpoint để có lịch sử thật. Không có đường ghim lại mẫu đề.

- Bằng chứng và checklist: [phase 9](../../../plans/reports/261105-scoring-rubric-phase09-checklist.md). PostgreSQL IT đã chạy thật ở phiên này. `RubricVersionConcurrencyIT` gộp cả ca ghim/snapshot thay cho một lớp riêng RubricPinningSnapshotIT: snapshot tổng hợp được ghi trong exam_results với published=true, rồi so byte sau kích hoạt; không phải một lượt publish UI thật.
- Kích hoạt lại sau lock conflict tối đa 2 giao dịch mới; thay ACTIVE hoặc lock_version làm digest hết hiệu lực. Mọi API ACTIVATE kiểm role và digest. Update nháp yêu cầu expectedLockVersion; giữ phiên bản editor ban đầu trước refetch nền.
