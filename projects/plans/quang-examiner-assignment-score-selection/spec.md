# Spec: Examiner assignment and host-approved score publication

**Date:** 2026-09-23
**Status:** Draft

---

## Problem Statement

Host hiện không thể giao phần Speaking/Writing cho Examiner trong hệ thống, và điểm Examiner hiện chỉ là điểm độc lập do Host tự nhập. Cần một quy trình theo từng exam/session để chia bài làm cho Examiner, Host chọn nguồn điểm được dùng, rồi duyệt và publish kết quả nhất quán cho Student.

---

## User Stories

- **[P1]** Là Host, tôi muốn lọc attempt theo Program/Class của session rồi giao mỗi attempt cho một Examiner, để phân công đúng nhóm học viên.
  Accepted when: Host có thể tạo assignment cho session hiện tại bằng mapping thủ công theo class/program; attempt được giao đúng một lần và mọi câu Speaking/Writing AI-eligible trong attempt đi cùng Examiner đó.

- **[P1]** Là Host, tôi muốn random một pool attempt từ nhiều class cho nhiều Examiner, để chia đều khối lượng mà không chia theo lớp.
  Accepted when: Với 40 attempt thuộc các class đã chọn và 2 Examiner, preview và kết quả là 20/20; tổng quát N attempt/M Examiner thì số attempt giữa các Examiner lệch tối đa 1; refresh/retry không làm thay đổi assignment đã xác nhận.

- **[P1]** Là Examiner, tôi muốn có hàng đợi chỉ gồm attempt được giao cho tôi và chấm từng câu đủ điều kiện, để không truy cập bài ngoài trách nhiệm.
  Accepted when: Examiner cùng tenant chỉ xem/nghe và nộp điểm cho attempt được giao; điểm 0–100 lưu cùng examiner ID và thời gian nộp; API từ chối attempt không được giao.

- **[P1]** Là Host, tôi muốn xem riêng điểm AI và Examiner, rồi áp dụng nguồn điểm theo task type, section hoặc toàn bộ, để chọn đúng điểm đưa vào kết quả.
  Accepted when: Mỗi thao tác preview số câu bị ảnh hưởng và số câu chưa có điểm từ nguồn chọn; thao tác phạm vi hẹp thực hiện sau cập nhật đúng nhóm câu đó mà không xóa hai điểm gốc.

- **[P1]** Là Host, tôi muốn duyệt việc chọn nguồn điểm trước khi publish, để Student chỉ nhận report đã hoàn tất.
  Accepted when: Host không thể duyệt/publish khi bất kỳ câu AI_SPEECH/AI_TEXT đủ điều kiện nào chưa có selected source hoặc score publishable; khi đủ điểm, report tính bằng selected score trên thang đo và trọng số của ScoreTemplate được pin.

- **[P1]** Là Student, tôi muốn chỉ xem report sau khi Host publish, và report phản ánh đúng nguồn điểm Host đã duyệt.
  Accepted when: Report không hiển thị trước publish; sau publish, score aggregation dùng selected score của từng câu AI-eligible và giữ nguyên cách chấm objective hiện có.

- **[P3]** Là Host, tôi muốn lưu mapping examiner theo lớp để tái sử dụng cho các session sau, nhằm giảm thao tác lặp.
  Accepted when: Ngoài phạm vi phiên bản đầu; assignment config hiện chỉ áp dụng cho một session.

---

## Functional Requirements

1. **FR-01:** Mỗi assignment batch thuộc đúng một exam/session. Không tự lưu hoặc áp dụng mapping cho session tiếp theo.
2. **FR-02:** Host chọn một hoặc nhiều Program/Class trong tenant và session; pool chỉ gồm attempt đã nộp, thuộc session, khớp scope, có ít nhất một câu mà scoring method trong pinned ScoreTemplate là AI_SPEECH hoặc AI_TEXT.
3. **FR-03:** Attempt giao cho tối đa một Examiner trong một session. Một attempt chứa nhiều câu AI-eligible vẫn là một đơn vị giao việc; không chia câu của cùng attempt cho nhiều Examiner.
4. **FR-04:** Examiner được chọn phải là user active có role EXAMINER thuộc cùng tenant. Backend xác minh tenant và assignment ownership khi list, đọc detail, phát audio URL và submit score.
5. **FR-05:** Host có hai chế độ: mapping thủ công các Program/Class đã chọn tới Examiner; hoặc random pooled assignment trên toàn bộ attempt thuộc tất cả scope đã chọn. Random không phân lớp thành các pool riêng.
6. **FR-06:** Random mode phân phối attempt sao cho mỗi Examiner nhận số lượng chênh tối đa 1. Với 40 attempt/2 Examiner, phân bổ đúng 20/20. Preview phải liệt kê số attempt, số câu AI-eligible và phân bổ dự kiến trước khi commit.
7. **FR-07:** Một attempt chỉ xuất hiện một lần trong pool kể cả khi khớp nhiều scope Class/Program đã chọn. Nếu các manual mappings khiến cùng một attempt được gán cho nhiều Examiner khác nhau, hệ thống từ chối xác nhận batch và hiển thị danh sách conflict để Host sửa mapping.
8. **FR-08:** Sau khi xác nhận, assignment được lưu ổn định và idempotent. Attempt mới nộp sau batch không làm xáo trộn assignment đã lưu; Host có thể tạo batch bổ sung chỉ cho các attempt chưa được giao.
9. **FR-09:** Examiner xem danh sách attempt được giao, trạng thái chấm, payload câu trả lời và media playback cần thiết; Examiner không xem các attempt không được giao. Chế độ chấm là blind: AI score và nguồn điểm đang chọn bị ẩn khỏi Examiner trước và trong khi chấm; chỉ Host xem được cả hai nguồn.
10. **FR-10:** MVP cho Examiner nộp một điểm tổng nguyên 0–100 cho mỗi câu AI-eligible. Score record phải xác định answer, attempt, examiner, tenant, thời điểm submit và trạng thái; không ghi đè rawScore/AI score. Rubric sub-scores và feedback chi tiết không thuộc MVP.
11. **FR-11:** Điểm từ AI và Examiner được giữ riêng. Điểm objective và UNSCORED không được đưa vào examiner assignment; scoring objective tiếp tục dùng luật hiện tại.
12. **FR-12:** AI score chỉ được chọn làm nguồn publish nếu là kết quả từ provider thật, hoàn tất và hợp lệ. Kết quả provider stub/place-holder phải mang provenance rõ ràng và bị loại khỏi các nguồn có thể publish.
13. **FR-13:** Host áp dụng nguồn AI hoặc Examiner cho: (a) mọi câu AI-eligible trong phạm vi, (b) một section, hoặc (c) một task type. Thao tác cập nhật selected source trực tiếp trên tập câu đang khớp; action sau cùng thắng trên từng answer, vì vậy thao tác hẹp sau thao tác rộng chỉ ghi đè các câu trong tập hẹp. Mỗi lần áp dụng có preview số lượng và availability.
14. **FR-14:** Host nhìn thấy điểm AI, điểm Examiner, selected source, trạng thái assignment/chấm và các câu đang thiếu điểm trong một session review; chỉ Host được đổi selected source, duyệt và publish.
15. **FR-15:** Host approval bị chặn nếu bất kỳ câu AI_SPEECH/AI_TEXT đã nộp trong tập report cần publish thiếu selected source hoặc selected score không tồn tại/không publishable. API trả danh sách/count task type bị thiếu; không publish một phần.
16. **FR-16:** ScoreAggregationService dùng selected score trên từng câu AI-eligible trước khi average theo task type và áp dụng trọng số pinned ScoreTemplate. Câu objective vẫn dùng objective score; UNSCORED tiếp tục không đóng góp.
17. **FR-17:** Session report chỉ publish sau host approval thành công. Sau publish, selected source và scores dùng cho report bị khóa; thay đổi cần một quy trình reopen/republish riêng, không âm thầm đổi kết quả Student đang thấy.
18. **FR-18:** Lưu audit cho assignment creator/time, chế độ phân phối, Examiner nhận attempt, điểm Examiner và người submit, các lần source selection, Host approval và publish.

---

## Non-Functional Requirements

- **Performance:** Preview và commit việc chia 40 attempt cho 2 Examiner hoàn tất trong 2 giây p95 trên local integration environment, không tính thời gian tải media/AI.
- **Security:** 100% API đọc/chấm của Examiner phải kiểm tra tenant và assignment ownership; không trả payload/audio cho attempt ngoài assignment.
- **Consistency:** Mỗi attempt có tối đa một assignment active trong một session; random assignment đã commit không đổi khi retry hoặc reload.
- **Auditability:** 100% thay đổi điểm nguồn và approval ghi được actor, timestamp, phạm vi áp dụng và số câu bị ảnh hưởng.
- **Publication integrity:** Student chỉ nhận report đã được Host duyệt; không report nào được publish khi thiếu nguồn điểm hợp lệ cho câu AI-eligible.

---

## Success Criteria

- [ ] Random pooled allocation với 40 attempt từ ít nhất 2 class và 2 Examiner tạo đúng 20/20; với N attempt và M Examiner, chênh lệch giữa nhóm không quá 1.
- [ ] Assignment theo Program/Class chỉ lấy attempt của session và scope được chọn; attempt trùng do overlap giữa các scope chỉ được giao một lần.
- [ ] Examiner không thể list/detail/play media/submit score cho attempt của Examiner khác hoặc tenant khác.
- [ ] Mỗi examiner score được truy nguyên về examiner và timestamp; không làm thay đổi AI score/objective score đang lưu.
- [ ] Apply source theo ALL, SECTION và TASK_TYPE cập nhật đúng answer set; thao tác hẹp chạy sau ghi đè đúng subset, các điểm gốc vẫn còn.
- [ ] Host approval và session publish bị từ chối khi còn ít nhất một câu AI-eligible thiếu selected publishable score; thành công sau khi đủ score.
- [ ] Report aggregation dùng selected score và pinned template weights; objective score vẫn cho kết quả như trước.
- [ ] Score do stub tạo không thể được chọn/publish; report Student không thay đổi sau khi publish do selection bị khóa.

---

## Out of Scope

- Cấu hình examiner mặc định tái sử dụng giữa nhiều exam/session.
- Trả/reopen examiner submission để sửa điểm sau khi đã submit; xử lý thủ công ngoài hệ thống trong MVP.
- Random theo lớp riêng biệt trong chế độ pooled random; double-scoring một attempt bởi nhiều Examiner; hiệu chuẩn độ lệch giữa Examiner.
- Xây mới hoặc hiệu chuẩn model AI; feature này chỉ tiêu thụ kết quả AI đã cấu hình và xác thực.
- Rubric sub-scores/feedback theo từng tiêu chí task type trong MVP.
- Partial publish, hoặc sửa điểm/source sau publish mà không qua luồng reopen/republish.

---

## Assumptions

- Assignment và score-selection chỉ áp dụng cho submitted attempts trong một session; attempt chưa nộp hoặc chưa được ingest có thể được Host đưa vào batch bổ sung sau.
- Program/Class filter được giao cắt với roster/enrollment của session; mọi kết quả được deduplicate theo attempt ID.
- Tập AI-eligible lấy từ scoring method của ScoreTemplate pinned theo attempt, không hardcode task type.
- MVP cho Examiner nộp một điểm tổng nguyên 0–100 trên mỗi câu, phù hợp score range hiện có; rubric sub-score và feedback chi tiết nằm ngoài phạm vi.
- Provider stub không tạo ra điểm hợp lệ để publish; provenance phải phân biệt stub với provider thật.
- Host là người duy nhất chọn/duyệt nguồn điểm và gọi publish; Examiner chỉ submit score cho assignment của mình.
- Source selection được lưu theo từng answer; lệnh ALL/SECTION/TASK_TYPE là thao tác áp dụng hàng loạt lên tập answer hiện tại, không phải rule động cho future answers.

---
