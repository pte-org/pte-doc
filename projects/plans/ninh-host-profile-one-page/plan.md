# Hồ sơ Host: một trang thay vì hai tab

## Thay đổi (tenant-web `features/profile`)
- `ProfileView`: bỏ `ProfileLayout`/`TabPanel`; xếp dọc hai khối "Thông tin tổ chức" và "Thông tin cá nhân". Mỗi khối vẫn có nút Chỉnh sửa và lưu riêng (hai API khác nhau); nhánh nhiều tổ chức giữ nguyên.
- `useUpdateMyOrganization`: sau khi lưu, ngoài cập nhật cache còn `invalidateQueries` để đọc lại từ máy chủ.

## Về lỗi "chọn phường/xã, lưu xong không hiện"
- Không tái hiện được: DB của `ninh-le2` đã có ward 691 và địa chỉ; trên host seed (UI thật, qua nginx 8080) chọn tỉnh/phường/địa chỉ rồi lưu hiện đúng cả ngay lúc đó và sau khi tải lại, cả khi tỉnh đã có sẵn.
- Phỏng đoán: bộ nhớ đệm hoặc mã giao diện cũ ở trình duyệt người dùng. Bước đọc lại sau khi lưu là phòng ngừa. Nếu còn lỗi: xem phản hồi của `PATCH /organizations/{id}` trong tab Network.

## Kiểm tra
tsc, eslint, vitest tenant-web; xem trang gộp và nút Chỉnh sửa của khối cá nhân trên trình duyệt. Dữ liệu seed đã trả về như cũ.
