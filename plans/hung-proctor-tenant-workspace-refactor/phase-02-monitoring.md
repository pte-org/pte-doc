# Phase 2 — Monitoring

Status: planned, chờ phê duyệt. Chỉ tài liệu; không triển khai.

## 1. Mục tiêu

Hoàn thiện luồng từ danh sách ca tới roster giám sát, chi tiết thí sinh và cảnh báo realtime, giữ nguyên ranh giới quyền can thiệp hiện hữu.

## 2. Hiện trạng

- **Existing:** `LiveMonitoringView`, `MonitoringStudentTable`, student panel, connection banner, force-submit dialog, violation form; REST monitoring snapshot và attempt history; STOMP transport/useProctorRoom, operation results/errors và kiểm tra role/assignment tại backend.
- **Missing:** monitoring REST hiện chỉ nhận page/size, chưa có server search/status filter. Không có pause/resume; không được coi đây là chức năng được cấp phép.
- **Needs Modification:** raw monitoring table, state khi refresh, mapping selected student/attempt và các bộ lọc cần đồng bộ toàn dataset.
- **Needs Confirmation:** ngưỡng mới cho cảnh báo hay quyền can thiệp bổ sung phải có quy tắc riêng; kế hoạch chỉ dùng tín hiệu và forceSubmit/flag hiện có.

## 3. Chức năng bổ sung

Monitoring list từ Phase 1 dẫn tới session detail có summary, connection status, roster và detail panel. Roster phân biệt trạng thái thi, kết nối/last seen và violation; active student là domain selection, không phải bulk checkbox. Cảnh báo dẫn tới thí sinh hoặc incident tương ứng; không tự kết luận ABSENT/LATE từ kết nối hoặc attempt status.

## 4. Luồng nghiệp vụ

Assigned PROCTOR chọn ca hợp lệ → GET snapshot → mở/join proctor room bằng transport hiện có → chọn thí sinh → xem attempt history → flag violation hoặc force submit theo capability hiện hành → nhận operation result, cập nhật/refetch snapshot. Input là tenant/actor, session, student, attempt và operation identity hiện có. Monitoring đọc không đổi exam status; flag tạo violation; forceSubmit đi qua Attempt owner và chỉ thành công khi target còn hợp lệ. LEAD_PROCTOR/ASSISTANT_PROCTOR là assignment labels, không tạo cấp quyền mới. Host vẫn sở hữu lifecycle ca; Proctor không đóng exam session bằng thao tác đóng proctor room. Reconnect, stale heartbeat, thay attempt, assignment bị thu hồi, terminal session hoặc lệnh lỗi đều có trạng thái rõ ràng; không gửi lại can thiệp mù. Kết thúc khi thao tác có kết quả hoặc room được rời/đóng theo luồng hiện hữu; handoff nghiệp vụ mới chưa được suy ra từ room close.

## 5. Frontend changes

- Chuyển `MonitoringStudentTable` sang common typed DataTable với student public ID làm row key, StatusBadge, row action “Xem chi tiết”, renderMobileRow và pagination slot. Không dùng selectable cho active student.
- Giữ active student khi snapshot refresh; nếu thí sinh/attempt không còn thuộc ca, panel giải thích thay đổi và bỏ action cũ. Có thể đề xuất optional `activeRowKey` tại common DataTable với token chung khi row highlight cần thiết; không truyền prop chưa tồn tại hoặc tự thêm màu feature.
- Controlled search/status/connection controls qua filters slot; server filters trước paging. Tắt cả ba client transforms; cột `sortable=false` nếu chưa có server sort contract. Không dùng adapter trang đầu 50 rows làm roster đầy đủ.
- Initial loading chỉ trước dữ liệu đầu tiên; polling/reconnect giữ bảng/panel/draft form, hiển thị refreshing/stale connection warning. ErrorState retry ở page boundary; failure một panel không che roster. Empty phân biệt roster rỗng và filter không khớp.
- Desktop bảng và panel; mobile DataTable cards rồi mở panel/dialog phù hợp. ForceSubmit dùng ConfirmDialog, violation form dùng Modal, notification dùng useToast. Pending action khóa đúng thao tác và hiển thị lỗi được trả về; không báo thành công trước acknowledgement.

## 6. Backend/API changes

Reuse GET `/api/v1/exam-sessions/{id}/monitoring`, `/monitoring/students/{studentId}/attempts` và STOMP open/forceSubmit/flag hiện hữu. Đề xuất search, exam-status và connection filter với definitions rõ ràng trong MonitoringController/QueryService, client types/hooks/query keys. Summary phải nêu phạm vi toàn session hay filtered dataset, không suy từ rows. Reuse ProctorAccessPolicy, room authorization, revocation checks và operation contracts. MonitoringQueryService lấy enrollment/session qua Session facade, attempt qua Attempt facade, identity qua Identity facade; không import module internal khác.

## 7. Database changes dự kiến

Không cần bảng monitoring mới. Reuse enrollment monitoring view, attempts, proctor sessions và violation events. Search/status projection mở rộng query hiện có; không lưu bản sao attendance/connection làm nguồn sự thật. Chỉ đề xuất schema/index nếu contract đã duyệt cần thông tin chưa có.

## 8. File dự kiến tạo/sửa

`pte-web/apps/tenant-web/app/(dashboard)/proctor/sessions/[publicId]/page.tsx`; `features/proctor/components/LiveMonitoringView.tsx`, `MonitoringStudentTable.tsx`, `MonitoringStudentPanel.tsx`, `MonitoringConnectionBanner.tsx`, `ForceSubmitDialog.tsx`, `ViolationForm.tsx`; `api.ts`, `queryKeys.ts`, `types.ts`, `messages/{en,vi}.ts`; `packages/api-client/src/requests/proctoring.ts`, `types/proctoring/index.ts`. Common `packages/ui/src/components/DataTable.tsx` chỉ khi opt-in active-row/controlled-sort extension được cần và duyệt. Backend: `proctoring/internal/controller/MonitoringController.java`, `internal/service/MonitoringQueryService.java`, DTO monitoring; `session/internal/service/ProctorMonitoringQueryService.java` và public DTO/facade nếu mở rộng projection.

## 9. Dependencies

Phase 1 queue/navigation, existing transport/permission infrastructure và common table contract. Incident deep links phụ thuộc Phase 4; đọc violation và ghi flag hiện có không phải chờ vòng đời incident mới.

## 10. Functional acceptance criteria

- Chỉ đúng actor/tenant/assignment được xem roster và dùng room actions.
- Search/filter/pagination truy vấn toàn roster; mobile và desktop mở cùng student/attempt detail.
- Refresh/reconnect không làm mất active student hoặc ghi chú chưa gửi; dữ liệu stale được nhận diện.
- Force submit/flag chỉ phản ánh thành công sau operation result; target hết hiệu lực không nhận action cũ.
- Không có pause/resume hoặc quyền lead mới; đóng room không đóng ca thi.

## Design Constraints

DataTable và common tokens là chuẩn table duy nhất. Shared extensions opt-in, defaults/consumer khác giữ nguyên. Reuse STOMP thay transport mới; không thay lifecycle exam, attendance hay quyền Host/Examiner/Candidate. Feature flag giữ tắt.
