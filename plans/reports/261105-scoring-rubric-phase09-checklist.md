# Phase 9 — checklist và bằng chứng

Toàn suite: **4602/0 failures/0 errors/73 skipped**; [số liệu XML](assets/261105-scoring-rubric-transparency-verification/phase09-surefire-summary.json). Quality: skipped_by_user.

LỆCH PLAN / ranh giới:
- Chạy node_modules/.bin theo yêu cầu, không pnpm/install/browser/commit/push. Vendor tsc chỉ lỗi sinh cũ TS2307 login/page.js; eslint 0 lỗi, 2 cảnh báo cũ. Vendor 303 và api-client 685 test qua.
- Gộp gate toggle/pending notice vào component trait và Alert chung, không tạo component trùng UI chung. Có endpoint/history audit thật.
- Gộp test pin/snapshot vào RubricVersionConcurrencyIT: 4 ca PostgreSQL/JPA đã chạy; snapshot tổng hợp được ghi published=true trong bảng thật rồi kiểm bất biến byte, không gọi UI publish thật.
- Manager không tự duyệt PENDING, Admin được phép. DRAFT của Manager được kích hoạt trực tiếp theo quyết định spec.
- Trọng số gate >0 kể cả tắt; sửa kỳ vọng test cũ theo ràng buộc người dùng.
- Lỗi lúc phát triển đã sửa: Java `reference to assertThat is ambiguous` ở test Optional (tách biến có kiểu); FE `Cannot find package @/lib/apiClient` trong SSR test (tách component xác nhận thuần khỏi module fetch)..
- Chưa kiểm chứng: browser, Next build, AI spike/độ ổn định 90%, hiệu chỉnh bằng dữ liệu người chấm.


## 1. Implementation steps

1. **Máy trạng thái**: `DRAFT -> PENDING -> ACTIVE | REJECTED`; `ACTIVE -> RETIRED` khi bản khác được kích hoạt; `DRAFT/REJECTED -> DRAFT` (sửa lại); `DRAFT` bỏ bằng xóa mềm (`BaseEntity.deleted`). **Không có trạng thái APPROVED riêng** (U4): duyệt `PENDING` = kích hoạt.
   `RubricVersionCommandService` (`internal/rubric/service`; tách `internal/rubric/workflow` nếu sát trần 15): `createDraft` (từ bản ACTIVE hoặc bản bất kỳ, tham số **đầy đủ** như Phase 2), `updateDraft` (chỉ DRAFT/REJECTED; `@Version`/`lock_version` chống ghi đè), `submit`, `reject` (bắt buộc `reason` <= 1000), `activate`. Dấu thời gian bằng `Clock` inject.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 2. Implementation steps

2. **Kích hoạt (MEDIUM-1, U4)** trong **một giao dịch** theo đúng thứ tự: (i) khóa hàng ACTIVE hiện hành; (ii) kiểm tra xác nhận diff (bước 3); (iii) **câu lệnh native UPDATE chuyển bản ACTIVE cũ sang RETIRED rồi flush** (chỉ mục duy nhất từng phần được kiểm tra theo từng câu lệnh, không dựa vào thứ tự flush ngầm của Hibernate);
   (iv) đặt bản mới ACTIVE với `activated_at` và **`approver_user_public_id` = người gọi** (đường `PATCH .../status` với `ACTIVATE`; áp dụng cả duyệt `PENDING` lẫn kích hoạt ngay từ `DRAFT`); (v) INSERT một dòng `scoring_rubric_activation_audits` (ai, khi nào, bản trước, tóm tắt diff). Xử lý va chạm đồng thời bằng khóa và thử lại có giới hạn.
   **Service guard bất biến**: không sửa/xóa ACTIVE/RETIRED (lớp hai là trigger V32).

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 3. Implementation steps

3. **Diff và xác nhận trước khi kích hoạt (U4)**: `GET /versions/{publicId}/diff` (so với ACTIVE hiện hành: liệt kê từng task type/tiêu chí/Form band/cổng/phiên bản bảng Azure đổi từ-sang) trả thêm `diffDigest` (băm ổn định của diff và `lock_version` hai bên). `ACTIVATE` yêu cầu thân `{expectedActiveVersionPublicId, confirmedDiffDigest}`;
   server tính lại diff và **từ chối nếu digest lệch hoặc ACTIVE đã đổi** (người dùng phải xem diff mới). Không có đường kích hoạt bỏ qua xác nhận.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 4. Implementation steps

4. **Quyền theo hành động**: tạo/sửa/gửi duyệt bản nháp: `ACADEMIC_STAFF`, `PLATFORM_AUTHOR`, `ACADEMIC_MANAGER`, `PLATFORM_ADMIN`; duyệt (ACTIVATE từ PENDING), từ chối, kích hoạt ngay: `ACADEMIC_MANAGER`, `PLATFORM_ADMIN` (người duyệt không được là tác giả của chính bản nháp đó trừ `PLATFORM_ADMIN`; có test); Staff không bao giờ kích hoạt được.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 5. Implementation steps

5. **API ghi** (`/api/v1/scoring-rubrics`): `POST /versions`, `PUT /versions/{publicId}` (kèm `expectedLockVersion`), `PATCH /versions/{publicId}/status` với `{action: SUBMIT | ACTIVATE | REJECT | DISCARD, reason?, expectedActiveVersionPublicId?, confirmedDiffDigest?}` (`reason` bắt buộc khi REJECT; digest bắt buộc khi ACTIVATE), `GET /versions/{publicId}/diff`.
   DTO record trong `internal/rubric/dto`; exception miền (trạng thái không hợp lệ, tự duyệt, va chạm, digest lệch) theo `COMMON_EXCEPTION_SETUP.md`, message/mã trong `RubricConstants`.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 6. Implementation steps

6. **Quy tắc tham số** (mở rộng `RubricParametersValidator` cho mọi đường ghi, MEDIUM-3, LOW-3): trọng số **số nguyên 0-10**; **tiêu chí cổng phải > 0**; **tổng trọng số mỗi task type > 0**; Form band không chồng lấn, có ít nhất một band đạt tối đa của Form, không vượt thang; `gates` chỉ cho tiêu chí cổng của catalog; khóa lạ bị từ chối;
   quy tắc "đúng một câu" của SWT và quy tắc phụ cơ học không chỉnh được (chỉ khoảng số từ); mô tả mức, thang Pearson, nguồn chấm, prompt không có đường chỉnh (D2/D3). **Read Aloud Content**: trọng số chỉnh được nhưng thang động theo N (không chỉnh được thang). **Giới hạn kích thước JSON tham số và số phần tử** theo `RubricConstants`, kiểm tra **trước khi lưu**.
   Lưu `catalog_version` hiện hành khi tạo; quy tắc cấu trúc khác với code như Phase 2.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 7. Implementation steps

7. **Không có hành động ghim lại mẫu DRAFT** (LOW-4): mẫu đề mới tạo/clone ghim bản ACTIVE lúc đó (Phase 2); không thêm `PATCH /exam-definitions/{id}/rubric`.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 8. Implementation steps

8. **FE vendor-web** (`features/scoringrubric/` mở rộng; route `app/(dashboard)/admin/scoring-rubric/versions/page.tsx` và `.../versions/[publicId]/page.tsx`): danh sách phiên bản; màn chi tiết/chỉnh gồm `_VersionStatusBar` (hành động theo role/trạng thái), `_TraitWeightEditor` (bộ tăng giảm/thanh trượt rời rạc 0-10, hiện trọng số mặc định Pearson để so; **với RA Content hiện chú thích "tiêu chí này theo độ dài đoạn văn: trọng số chỉnh được, thang động"**),
   `_FormBandEditor` (kéo biên giữa các band thay cho nhập số), `_GateToggle` (cảnh báo tác động), `_VersionDiffPanel`, **`_ActivateConfirmDialog` (hiện diff và bắt tick xác nhận trước khi gửi `ACTIVATE` kèm `confirmedDiffDigest`)**, `_RejectDialog` (bắt buộc lý do), `_PendingNotice`, `_ActivationHistory` (đọc audit nếu có endpoint; nếu không thì hoãn), bản ACTIVE/RETIRED chỉ đọc. Hằng/nhãn/lỗi vào constants/i18n (`errorMessage.ts` theo mẫu `scoretemplate`). Component <= 150 dòng.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 9. Implementation steps

9. **api-client**: hàm/kiểu cho endpoint ghi và diff.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 10. Implementation steps

10. **Test backend**: máy trạng thái (mọi chuyển hợp lệ/không), phân quyền theo hành động (Staff không kích hoạt; Manager/Admin kích hoạt), REJECT bắt buộc lý do, `lock_version` va chạm, tự duyệt bị chặn, **digest lệch/ACTIVE đã đổi bị từ chối**, **mỗi ACTIVATE tạo đúng một dòng audit và đặt `approver_user_public_id`**, validator (Form chồng lấn/không band tối đa, trọng số ngoài 0-10, cổng = 0, tổng = 0, khóa lạ, JSON quá lớn),
    bất biến (sửa ACTIVE qua service và qua SQL: bị chặn); **Postgres IT gồm ca thứ tự flush** (kích hoạt khi chưa retire bản cũ thất bại; đúng quy trình native-update-flush rồi activate thành công; hai kích hoạt song song: đúng một ACTIVE); tích hợp chính: **đổi rubric không đổi snapshot báo cáo đã publish** và **mẫu đề đã tạo giữ ghim**. Cập nhật `ApiInventoryExportTest`.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 11. Implementation steps

11. **Test FE**: dựng tham số từ trạng thái trình chỉnh, kiểm tra khoảng Form/trọng số phía FE chỉ để báo lỗi sớm, bật/tắt hành động theo role/trạng thái, tính diff hiển thị, nút ACTIVATE bị khóa cho tới khi xác nhận.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 12. Acceptance criteria

- Staff tạo nháp và gửi duyệt được; không duyệt/kích hoạt (403). Manager duyệt (= kích hoạt) hoặc từ chối (bắt buộc lý do); Manager/Admin kích hoạt ngay không qua duyệt.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 13. Acceptance criteria

- Kích hoạt đòi hỏi xác nhận diff (`confirmedDiffDigest`); digest sai/ACTIVE đã đổi bị từ chối; UI hiện diff và bắt xác nhận.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 14. Acceptance criteria

- Mỗi lần ACTIVATE tạo đúng một dòng audit (ai, khi nào, bản trước, tóm tắt diff) và đặt `approver_user_public_id`; audit không sửa/xóa được.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 15. Acceptance criteria

- Bản ACTIVE cũ -> RETIRED bằng native update + flush trước khi bản mới ACTIVE trong một giao dịch; luôn đúng một ACTIVE (IT đồng thời và ca thứ tự flush).

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 16. Acceptance criteria

- Không sửa/xóa được ACTIVE/RETIRED; lưu thay đổi luôn tạo phiên bản mới.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 17. Acceptance criteria

- Tham số không hợp lệ (số nguyên 0-10, cổng > 0, tổng > 0, Form band, khóa lạ, kích thước) bị từ chối với mã chuẩn; RA Content hiện chú thích độ dài.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 18. Acceptance criteria

- Mẫu đề tạo trước khi kích hoạt giữ ghim; báo cáo đã publish không đổi; không có đường ghim lại mẫu DRAFT.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 19. Acceptance criteria

- Không có đường chỉnh mô tả mức, thang Pearson hay prompt; FE/BE test và ratchet xanh.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 20. Validation commands

.\mvnw.cmd -pl app -DskipTests compile

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 21. Validation commands

.\mvnw.cmd -pl app test -Dtest="RubricVersionCommandServiceTest,RubricVersionControllerTest,RubricParametersValidatorTest,RubricActivationAuditTest,RubricVersionConcurrencyIT,RubricPinningSnapshotIT,ApiInventoryExportTest"

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 22. Validation commands

.\mvnw.cmd -pl app test -Dtest="PackageDensityTest,SourceFileSizeTest,NoDirectClockAccessTest,ModuleStructureTest"

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 23. Validation commands

.\mvnw.cmd -pl app test      # toàn suite

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 24. Validation commands

pnpm --filter vendor-web typecheck; pnpm --filter vendor-web lint; pnpm --filter vendor-web test

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 25. Design Constraints

- `docs/CODING_STANDARDS_API.md`, `API_RESPONSE_SETUP.md`, `COMMON_EXCEPTION_SETUP.md`, `TEST_SCENARIOS_IAM.md`, `CODING_STANDARDS_WEB.md` bắt buộc; message/mã trong `*Constants.java`; `Clock` inject; file <= 300 dòng; `internal/**` <= 15 class/gói.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 26. Design Constraints

- D1 chỉ chỉnh số; không mô tả mức, thang Pearson, nguồn chấm hay prompt; không văn bản tự do ngoài `reason` của từ chối; không tham số nào vào prompt.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 27. Design Constraints

- ACTIVE/RETIRED bất biến; mọi lưu tạo phiên bản mới; tham số luôn đầy đủ trong hàng.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 28. Design Constraints

- Duyệt = kích hoạt; không bỏ qua xác nhận diff; mọi ACTIVATE có audit và `approver_user_public_id`.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 29. Design Constraints

- Đổi rubric không đổi điểm đã publish hay mẫu đề đã tạo; rubric dùng chung toàn nền tảng, chỉ vendor quản lý; Host/tenant không thấy bản nháp.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 30. Design Constraints

- Chuyển trạng thái qua `PATCH .../{id}/status` với `{action, reason?}` (quy ước dự án).

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 31. Design Constraints

- FE: bộ chọn rời rạc/kéo thả cho đầu vào số; không Playwright (tsc, eslint, vitest). Không có bước release/deploy.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 32. Risks

- Kích hoạt đồng thời hoặc thứ tự flush vi phạm chỉ mục: native update + flush, khóa, thử lại giới hạn, IT.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 33. Risks

- Staff tự duyệt qua tài khoản khác: chặn theo `author_user_public_id`; audit ghi người duyệt.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 34. Risks

- Diff không phản ánh hết tác động lên điểm: diff liệt kê từng thay đổi tham số; xác nhận bắt buộc.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**

## 35. Risks

- Mở rộng tham số sau này phải tăng `catalog_version` và tương thích bản đã lưu: validator theo `catalog_version` của từng bản.

**ĐÃ LÀM — bằng chứng backend/FE ở đầu báo cáo; với lệnh pnpm/typecheck và các component gộp, LỆCH PLAN như đã liệt kê; browser chưa chạy.**
