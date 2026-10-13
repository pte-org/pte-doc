# Rà soát breadcrumb màn chi tiết

**Ngày:** 2026-10-13
**Phạm vi:** PTE Web — tenant-web và vendor-web
**Trạng thái:** Đã triển khai; chưa commit

Phạm vi: tenant-web và vendor-web. Quét toàn bộ route động và các component DetailView.
Có 15 route xem chi tiết bản ghi: 2 route đã đúng, 13 route được bổ sung trong 12 component (mẫu bài thi dùng chung cho 2 route).
Giữ hook useDashboardBreadcrumbLabel và provider common hiện có. Feature đăng ký tên từ dữ liệu đã tải; shell không thêm API request.

| App | Route | Nhãn cuối | Kết quả |
| --- | --- | --- | --- |
| Tenant | /host/students/[publicId] | fullName hoặc username | Đã có, giữ nguyên |
| Tenant | /host/exam-staff/[staffPublicId] | fullName hoặc username | Đã có, giữ nguyên |
| Tenant | /host/programs/[publicId] | program.name | Bổ sung; đã kiểm tra dữ liệu thật |
| Tenant | /host/programs/[publicId]/classes/[classPublicId] | studentClass.name | Bổ sung; đã kiểm tra dữ liệu thật |
| Tenant | /host/exams/[publicId] | session.name | Bổ sung |
| Tenant | /host/notifications/[publicId] | inbox item.title | Bổ sung tên và mục cha Thông báo |
| Tenant | /host/support-tickets/[publicId] | Yêu cầu #mã / Request #code | Bổ sung; API không có name/subject/title |
| Admin | /admin/tenants/[publicId] | tenant.name | Bổ sung; đã kiểm tra dữ liệu thật |
| Admin | /admin/applications/[applicationId] | application.orgName | Bổ sung |
| Admin | /admin/questions/[publicId] | question.title | Bổ sung; đã kiểm tra dữ liệu thật và VI/EN |
| Admin | /admin/exam-template/[publicId] | template.name hoặc code, kèm version | Bổ sung |
| Admin | /admin/score-template/[publicId] | template.name hoặc code, kèm version | Cùng component; bổ sung mục cha Mẫu bài thi |
| Admin | /admin/announcements/[publicId] | announcement.title | Bổ sung |
| Admin | /admin/notifications/[publicId] | inbox item.title | Bổ sung tên và mục cha Thông báo |
| Admin | /admin/support-tickets/[publicId] | Yêu cầu #mã / Request #code | Bổ sung; API không có name/subject/title |

## Các màn đã rà soát nhưng không áp dụng breadcrumb tên bản ghi

- /proctor/sessions/[publicId] và /proctor/audit-log/[publicId] là workspace giám sát/nhật ký. Hiện navigation chỉ có /proctor/profile, nên shell không có mục cha để hiển thị breadcrumb. API của hai workspace đang là stub, không cung cấp tên kỳ thi. Chưa thêm request của host dưới quyền proctor và chưa tự tạo tên kỳ thi.
- Các route /edit là màn chỉnh sửa, không thuộc view detail được yêu cầu.
- Các modal chi tiết (tenant dashboard, account details, answer details) không có breadcrumb route.

## Xác minh

- Lint phạm vi thay đổi: 0 lỗi; 1 warning img có sẵn trong QuestionDetailView.
- Typecheck cả hai app: pass.
- Build cả hai app: pass; warning turbopack.root có sẵn.
- Trình duyệt, dữ liệu thật: Lớp học > Class 1; Chương trình > Test; Tenant > Local Host Tenant; Ngân hàng câu hỏi > PTE_QUANG - MC_READING_SINGLE - 2.
- Đổi VI/EN: mục cha câu hỏi đổi đúng, tên câu hỏi được giữ.
- Trở về danh sách tenant: không còn breadcrumb của bản ghi trước.
- Các route khác được trace nguồn dữ liệu và kiểm tra compile; chưa kiểm tra trực quan từng route bằng dữ liệu thật.
- Chưa commit.
