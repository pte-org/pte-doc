# Phase 3: API client và Vendor Web settings UX

Status: Implemented — API client and Vendor Web gates passed  

## Requirements

Thiết kế lại màn hình `vendor-web` theo nhóm nghiệp vụ, dùng API typed thật và
giữ nhất quán với component/token hiện có trong `@pte/ui`.

## Design constraints

- Không hiển thị machine key làm label chính.
- Không tự tạo Button/Input/Alert/section visual clone nếu common component đã
  đáp ứng.
- Không tạo tab rỗng cho Security, Data retention hoặc Feature flags.
- UI guard chỉ là usability; quyền vẫn do API enforce.
- Chỉ render setting có `editable=true` hoặc trạng thái read-only rõ ràng.

## Proposed layout

### Thương mại & phê duyệt

- Hạn mức học viên miễn phí — `học viên`.
- Thời gian phản hồi hồ sơ tenant — `giờ`.
- Mỗi field có scope copy như “Áp dụng cho hồ sơ được duyệt sau khi lưu”.

### Thanh toán

- Chỉ hiển thị khi payment TTL đã được backend chuyển sang runtime DB setting.
- Thời hạn link thanh toán — `giờ`.
- Thời gian giữ đơn chờ thanh toán — `giờ`.
- Cảnh báo riêng về tác động tới link/đơn đang tồn tại.

### Giới hạn nền tảng

- Chỉ hiển thị global cap khi đã có product decision và protected confirmation.
- Không trộn với capacity của từng plan.

## Steps

1. Cập nhật API client types/requests/query keys cho metadata và batch update.
2. Tách constants/copy khỏi JSX: label, unit, validation, impact và error
   mapping theo locale mechanism hiện có.
3. Refactor `PlatformSettingsView` thành section/setting-row components nhỏ,
   giữ route mỏng.
4. Dùng `PageHeader`, panel/section, `FormField`, `Input`, `FormActions`,
   `Alert` và `Toast` của `@pte/ui`.
5. Thay các nút Save lặp lại bằng một action lưu ở cấp nhóm; disable khi chưa
   dirty, hiển thị saving/saved/error rõ ràng.
6. Thêm reset-to-default với confirmation khi giá trị ảnh hưởng rộng.
7. Hiển thị loading, API error, validation error, empty/deprecated và retry
   state; không hiển thị raw backend error.
8. Sau mutation, invalidate settings query và cập nhật thông báo thành công
   bằng label nghiệp vụ, không dùng raw key.
9. Kiểm tra responsive và dark/light token hiện có, không đổi common defaults.

## Success criteria

- Admin nhìn thấy nhóm và hiểu đơn vị/phạm vi của từng setting mà không cần biết
  key backend.
- Không còn hai nút Save rời rạc cho một nhóm nhỏ setting.
- Batch update hiển thị lỗi theo field và không làm mất input chưa lưu.
- `suspension_default_days` không xuất hiện như setting có hiệu lực.
- Không có duplicate control cho plan catalog, exam/session hoặc profile.

## Quality/testing state

- Preflight: reuse `PageHeader`, `DashboardPanel`, `Input`, `FormActions`,
  `ConfirmDialog`, `Alert`, `Toast` and the existing feature locale adapter;
  `PlatformSettingRow` keeps the main view under the component-size limit.
- `@pte/api-client` typecheck passed; `vendor-web` typecheck passed.
- Vendor Web lint passed with `0` errors and `2` existing `<img>` warnings in
  question bank files; `vendor-web` production build passed and generated
  `23` static pages.
- The grouped form uses the typed batch endpoint, localized business labels,
  units, impact copy, dirty/saving/saved/error/loading/empty/retry states and
  reset confirmation. Browser smoke, live unauthorized response and API failure
  interaction were not run in this session.

## Risks

- UI hiển thị category mới trước khi backend runtime support đã hoàn tất.
- Form group lưu nhầm giá trị cũ nếu query refetch trong lúc dirty; cần giữ
  draft state riêng và cảnh báo conflict nếu API trả version mới.
- Copy impact không nói rõ “future only” khiến admin hiểu là hồi tố.
