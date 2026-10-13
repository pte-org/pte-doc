# Kiểm tra màn chi tiết chương trình

**Ngày:** 2026-10-13
**Phạm vi:** PTE Web — chi tiết chương trình
**Trạng thái:** Bản ghi kiểm tra tại thời điểm triển khai

Báo cáo và ảnh dưới đây phản ánh phiên bản được kiểm tra trước các chỉnh sửa tiếp theo: bỏ khối điều hướng lớp học khỏi Tổng quan, chuyển chỉnh sửa lớp sang trang chi tiết và bỏ phần Giảng viên. Không xem ảnh này là ảnh chụp UI hiện tại.

Đã kiểm tra bằng tài khoản host với dữ liệu thật: chương trình Test, 1 lớp, 0 học viên. Lint, typecheck và production build thành công. Đã kiểm tra lưu lại giá trị hiện tại, validation tên rỗng, toast, điều hướng lớp có bộ lọc chương trình, chuyển ngôn ngữ, search và trạng thái rỗng, tabs bằng bàn phím. Chưa thực hiện tạm dừng hoặc lưu trữ dữ liệu thật; chỉ kiểm tra hộp xác nhận.

UI giữ component, màu, font và variants của @pte/ui. Không dùng dữ liệu giả trong sản phẩm. Có kiểm tra dark mode dùng data-theme của dự án. Build còn warning turbopack.root có sẵn.

Đã sửa nút xem lớp xuống dòng ở 780–940px và dùng renderMobileRow của DataTable để tránh ép cột trên mobile. Probe đã chạy trên route thật, mở screenshot sáng/tối ở desktop và mobile. Không thấy cuộn ngang trang ở 375px.

## Các cảnh báo còn lại của common UI

Các cảnh báo dưới đây được ghi nhận; không đổi common defaults trong phạm vi redesign này. Probe có thể đo sai nền gradient và hover khi chuyển động đã bị tắt. Các mục tương phản gradient cần dựa trên nền gradient thật, không dựa trên nền card của probe.

### Danh sách lớp sáng

- P1 [1440px, 768px, 375px] scale / translate / rotate không chạy chuyển động: transition: box-shadow, transform: div.rounded-xl.border-[0.5px].border-[var(--shell-border)].bg-[var(--surface-card)].p-5.relative "Lớp học1"
  - Đánh giá: StatCard common ở panel tổng quan được giữ mounted; giữ default, cảnh báo transition sẵn có.
- P2 [1440px, 768px, 375px] scale / translate / rotate không chạy chuyển động: transition: box-shadow, transform: div.rounded-xl.border-[0.5px].border-[var(--shell-border)].bg-[var(--surface-card)].p-5.relative "Học viên0"
  - Đánh giá: StatCard common ở panel tổng quan được giữ mounted; giữ default, cảnh báo transition sẵn có.
- P3 [375px] chỗ bấm dưới 24px: a.flex.items-center.gap-1.font-medium.text-[var(--ink-secondary)].transition-colors "Chương trình"
  - Đánh giá: Breadcrumb common có vùng bấm nhỏ; ghi nhận, chưa đổi common.
- P4 [375px] chỗ bấm dưới 24px: input.min-w-0.flex-1.bg-transparent.text-sm.outline-none.text-[var(--table-body-text)] "Tìm lớp theo tên hoặc trạng thái"
  - Đánh giá: Input nằm trong TableSearchControl có wrapper cao 40px; probe đo riêng input 20px, chưa đánh giá toàn wrapper.
- P5 [1440px, 768px] tương phản thấp: 1.10:1, cần 4.5:1, chữ #ffffff trên nền #f4f4f5 "Chương trình": span.truncate "Chương trình"
  - Đánh giá: Probe không tính nền gradient của sidebar; ảnh thực cho thấy chữ trên nền gradient.
- P6 [1440px, 768px] tương phản thấp: 4.40:1, cần 4.5:1, chữ #71717a trên nền #f4f4f5 "Cổng tổ chức": p.text-xs.text-[var(--ink-muted)] "Cổng tổ chức"
  - Đánh giá: Màu chữ phụ và nền sidebar của common shell; ghi nhận, chưa thay token.
- P7 [1440px, 768px] tương phản thấp: 4.40:1, cần 4.5:1, chữ #71717a trên nền #f4f4f5 "Trang chủ": p.mb-2.px-3.text-xs.font-medium.uppercase.tracking-[0.04em] "Trang chủ"
  - Đánh giá: Màu chữ phụ và nền sidebar của common shell; ghi nhận, chưa thay token.
- P8 [1440px, 768px] tương phản thấp: 4.40:1, cần 4.5:1, chữ #71717a trên nền #f4f4f5 "Người dùng": p.mb-2.px-3.text-xs.font-medium.uppercase.tracking-[0.04em] "Người dùng"
  - Đánh giá: Màu chữ phụ và nền sidebar của common shell; ghi nhận, chưa thay token.
- P9 [1440px, 768px] tương phản thấp: 4.40:1, cần 4.5:1, chữ #71717a trên nền #f4f4f5 "K": kbd.rounded-md.border.border-[var(--shell-border)].bg-[var(--surface-subtle)].px-2.py-0.75 "⌘ K"
  - Đánh giá: Màu chữ phụ và nền sidebar của common shell; ghi nhận, chưa thay token.
- P10 [1440px, 768px] tương phản thấp: 4.40:1, cần 4.5:1, chữ #71717a trên nền #f4f4f5 "⌘": span.font-medium "⌘"
  - Đánh giá: Màu chữ phụ và nền sidebar của common shell; ghi nhận, chưa thay token.
- P11 [768px] chữ cắt còn quá ngắn: span.min-w-0.flex-1.truncate.pl-1.text-sm.text-[var(--ink-muted)] "Tìm kiếm trang..."
  - Đánh giá: Header search common bị thu ngắn ở ngưỡng sidebar, ngoài phạm vi màn detail.
- P12 [1440px, 768px] nền rê tan vào nền khác (soi: Gu): a "PTE Prep home": khai nền rê mà nền rê trùng nền phía sau #f4f4f5, rê không thấy gì
  - Đánh giá: Hover/contrast của common Button, Tabs, DataTable hoặc shell; giữ visual defaults theo quy định dự án.
- P13 [1440px, 768px] nền rê tan vào nền khác (soi: Gu): button "Thu gọn thanh điều hướng": khai nền rê mà nền rê trùng nền phía sau #f4f4f5, rê không thấy gì
  - Đánh giá: Hover/contrast của common Button, Tabs, DataTable hoặc shell; giữ visual defaults theo quy định dự án.
- P14 [768px] nền rê tan vào nền khác (soi: Gu): button "Tổng quan": khai nền rê mà nền rê trùng nền phía sau #f4f4f5, rê không thấy gì
  - Đánh giá: Hover/contrast của common Button, Tabs, DataTable hoặc shell; giữ visual defaults theo quy định dự án.
- P15 [1440px] nền rê tan vào nền khác (soi: Gu): tr "Class 10Đang hoạt động": khai nền rê mà nền rê trùng nền phía sau #ffffff, rê không thấy gì
  - Đánh giá: Hover/contrast của common Button, Tabs, DataTable hoặc shell; giữ visual defaults theo quy định dự án.

### Danh sách lớp tối

- P1 [1440px, 375px] scale / translate / rotate không chạy chuyển động: transition: box-shadow, transform: div.rounded-xl.border-[0.5px].border-[var(--shell-border)].bg-[var(--surface-card)].p-5.relative "Lớp học1"
  - Đánh giá: StatCard common ở panel tổng quan được giữ mounted; giữ default, cảnh báo transition sẵn có.
- P2 [1440px, 375px] scale / translate / rotate không chạy chuyển động: transition: box-shadow, transform: div.rounded-xl.border-[0.5px].border-[var(--shell-border)].bg-[var(--surface-card)].p-5.relative "Học viên0"
  - Đánh giá: StatCard common ở panel tổng quan được giữ mounted; giữ default, cảnh báo transition sẵn có.
- P3 [375px] chỗ bấm dưới 24px: a.flex.items-center.gap-1.font-medium.text-[var(--ink-secondary)].transition-colors "Chương trình"
  - Đánh giá: Breadcrumb common có vùng bấm nhỏ; ghi nhận, chưa đổi common.
- P4 [375px] chỗ bấm dưới 24px: input.min-w-0.flex-1.bg-transparent.text-sm.outline-none.text-[var(--table-body-text)] "Tìm lớp theo tên hoặc trạng thái"
  - Đánh giá: Input nằm trong TableSearchControl có wrapper cao 40px; probe đo riêng input 20px, chưa đánh giá toàn wrapper.
- P5 [1440px] tương phản thấp: 1.05:1, cần 4.5:1, chữ #07111d trên nền #09090b "Chương trình": span.truncate "Chương trình"
  - Đánh giá: Probe không tính nền gradient của sidebar; ảnh thực cho thấy chữ trên nền gradient.
- P6 [1440px] nền rê gần như không thấy (soi: Gu): button "Ngôn ngữ": #171718 → #18181b (chênh 3 mức)
  - Đánh giá: Hover/contrast của common Button, Tabs, DataTable hoặc shell; giữ visual defaults theo quy định dự án.
- P7 [1440px] nền rê gần như không thấy (soi: Gu): button "Chỉnh sửa": #171718 → #18181b (chênh 3 mức)
  - Đánh giá: Hover/contrast của common Button, Tabs, DataTable hoặc shell; giữ visual defaults theo quy định dự án.
- P8 [1440px] nền rê gần như không thấy (soi: Gu): button "Tổng quan": #18181b → #171719 (chênh 2 mức)
  - Đánh giá: Hover/contrast của common Button, Tabs, DataTable hoặc shell; giữ visual defaults theo quy định dự án.
- P9 [1440px] nền rê tan vào nền khác (soi: Gu): tr "Class 10Đang hoạt động": khai nền rê mà nền rê trùng nền phía sau #171718, rê không thấy gì
  - Đánh giá: Hover/contrast của common Button, Tabs, DataTable hoặc shell; giữ visual defaults theo quy định dự án.

## Bằng chứng kiểm tra

Ảnh chụp đã được dọn theo yêu cầu; báo cáo JSON vẫn được giữ lại để truy vết kết quả kiểm tra.

- Tổng quan sáng: [JSON](assets/261013-program-detail-ui-review/overview-light/report.json).
- Tổng quan tối: [JSON](assets/261013-program-detail-ui-review/overview-dark/report.json).
- Danh sách lớp sáng: [JSON](assets/261013-program-detail-ui-review/classes-light/report.json).
- Danh sách lớp tối: [JSON](assets/261013-program-detail-ui-review/classes-dark/report.json).
