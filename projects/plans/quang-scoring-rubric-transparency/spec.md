# Spec: Rubric chấm điểm minh bạch và cấu hình được

**Date:** 2026-11-04
**Status:** Ready
**Nguồn:** [brainstorm](../../../plans/reports/261104-scoring-rubric-transparency-brainstorm.md),
[báo cáo đối chiếu Pearson](../../../plans/reports/261104-pte-scoring-pearson-alignment-review.md)

---

## Problem Statement

Luật chấm các task type tự luận đang nằm rải trong prompt, hằng số và công thức Java, và lệch so với Pearson Score Guide
(L1–L10). Hội đồng và nhóm học thuật không xem được hệ thống chấm một câu như thế nào, cũng không thấy điểm 10–90 được
tạo ra ra sao. Cần một rubric duy nhất, theo Pearson, vừa điều khiển việc chấm vừa được hiển thị trên giao diện.

---

## User Stories

- **[P1]** Là thành viên hội đồng hoặc Academic Manager, tôi muốn xem luật chấm của từng task type trên vendor-web để hiểu
  câu được chấm theo tiêu chí nào, thang bao nhiêu và khi nào bị 0.
  Accepted when: cả 22 task type chuẩn đều có trang luật chấm. Mỗi trang hiện đủ: tiêu chí, thang tối đa, mô tả từng mức
  (với task type tự luận), điều kiện chặn, các mức Form (nếu có), trọng số theo kỹ năng của mẫu đề đang xem, và số trang
  trích dẫn trong Score Guide.

- **[P1]** Là người vận hành hệ thống, tôi muốn điểm của mọi câu tự luận được tính từ rubric theo Pearson để điểm khớp
  với luật đang hiển thị.
  Accepted when:
  - Content = 0 hoặc Form = 0 thì điểm câu = 0.
  - Form của Essay và SST chia 3 mức.
  - Speaking mở có chấm Pronunciation.
  - Prompt chứa mô tả từng mức theo Pearson.
  - Điểm câu = tổng điểm đạt / tổng điểm tối đa × 100.

- **[P1]** Là Host của trung tâm (và Examiner với các bài được phân công), tôi muốn chọn một lượt thi đã chấm trên
  tenant-web để xem từng bước từ điểm tiêu chí đến điểm 10–90 và tự kiểm chứng được. Khi demo cho hội đồng, người trình
  bày dùng tài khoản Host.
  Accepted when: mọi con số trên màn giải thích khớp chính xác với báo cáo đã publish, chênh lệch bằng 0. Host chỉ xem
  được lượt thi của trung tâm mình; Examiner chỉ xem được lượt thi được phân công. Vendor không đọc được dữ liệu lượt thi.

- **[P2]** Là người trình bày khi bảo vệ, tôi muốn nhập điểm tiêu chí giả định cho một task type rồi xem điểm câu, để
  minh họa điều kiện chặn và cách gộp điểm.
  Accepted when: kết quả mô phỏng dùng đúng hàm tính điểm của backend và bằng kết quả scorer thật với cùng đầu vào.

- **[P2]** Là Academic Manager, tôi muốn chỉnh các tham số số học của rubric và lưu thành phiên bản mới, gắn vào mẫu đề.
  Tham số gồm: tỉ trọng của từng tiêu chí, các mức Form, bật/tắt điều kiện chặn. Thang điểm và mô tả từng mức cố định
  theo Pearson, không sửa được.
  Accepted when: phiên bản mới chỉ áp dụng cho mẫu đề gắn với nó. Báo cáo đã publish không đổi.

- **[P2]** Là giám khảo, tôi muốn chấm theo từng tiêu chí của rubric thay vì một điểm tổng, để điểm của tôi được giải
  thích giống điểm AI (L8).

- **[P3]** _(ngoài phạm vi)_ Chỉnh mô tả các mức hoặc prompt trên giao diện (D2); tự ghép công thức hoặc thêm tiêu chí (D3);
  quy đổi 10–90 bằng mô hình thống kê thay cho công thức tuyến tính.

---

## Functional Requirements

1. FR-01: Mỗi task type chuẩn có một rubric gồm: danh sách tiêu chí (key, tên hiển thị, thang tối đa, mô tả từng mức,
   nguồn chấm AI hoặc Azure, trang trích dẫn Pearson), các tiêu chí đóng vai trò điều kiện chặn, các mức Form và quy tắc
   gộp điểm.
2. FR-02: Rubric có phiên bản. Mẫu đề (`exam_definitions`) ghim phiên bản rubric giống cách ghim trọng số. Snapshot báo cáo
   ghi lại phiên bản đã dùng.
3. FR-03: Scorer AI dựng prompt từ mô tả mức của rubric và yêu cầu trả điểm từng tiêu chí theo thang của rubric. Giá trị
   ngoài thang thì kết quả chấm thất bại theo hướng an toàn (fail closed), không làm tròn về trong thang.
4. FR-04: Điểm câu được tính bằng một hàm thuần duy nhất `score(rubric, traitScores)`: áp điều kiện chặn → áp các mức Form
   → tính `Σ(tỉ trọng × đạt / tối đa) / Σ tỉ trọng × 100`. Tỉ trọng mặc định bằng điểm tối đa của tiêu chí, nên mặc
   định công thức bằng `Σ đạt / Σ tối đa × 100`. Hàm này được dùng chung cho scorer, cho màn giải thích (FR-07) và cho bộ mô phỏng (FR-08).
5. FR-05: Điểm tiêu chí lưu theo thang Pearson. Khi đổi rubric, có thể tính lại điểm câu từ điểm tiêu chí đã lưu mà không
   gọi AI.
6. FR-06: Sửa các điểm lệch:
   - L1: điều kiện chặn Content/Form;
   - L2: Pronunciation cho DI, RL, RTS, SGD, và thống nhất cách xử lý khi thiếu prosody;
   - L3: Form chia 3 mức cho Essay và SST, cộng các quy tắc chữ hoa, dấu câu, gạch đầu dòng;
   - L4: Form của SWT và WE lấy từ kiểm tra cơ học;
   - L5: tỉ trọng theo thang tối đa;
   - L6: Content cho Read Aloud có phạt từ chèn;
   - L7: Repeat Sentence chia mức Content 0–3, không tính Fluency hai lần;
   - L10: prompt theo thang mô tả.
7. FR-07: API và màn giải thích một lượt thi: điểm tiêu chí → điểm câu → trung bình task type (kèm số câu bỏ trống) →
   Σ(w × avg) / Σw → 10–90, cho từng kỹ năng và cho Overall.
8. FR-08: API và màn mô phỏng: nhận task type, phiên bản rubric và điểm tiêu chí giả định, trả về điểm câu cùng các bước
   tính (tiêu chí nào kích hoạt điều kiện chặn, Form ở mức nào). Không gọi AI.
9. FR-09: Màn chỉnh rubric (D1) chỉ cho sửa tỉ trọng tiêu chí (số nguyên 0–10; tiêu chí điều kiện chặn phải > 0), các mức Form (khoảng số chữ không chồng nhau,
   có ít nhất một mức đạt điểm tối đa) và bật/tắt điều kiện chặn. Lưu lại tạo phiên bản mới, không sửa đè phiên bản cũ.
10. FR-10: Trang luật chấm cho task type khách quan hiện công thức chấm (ví dụ +1/−1, thấp nhất 0) từ cùng khai báo
    rubric. Phần này không cấu hình được.
11. FR-11: Migration V2 tạo bảng rubric và seed rubric chuẩn theo Score Guide 2025. DB demo được reset (đã thống nhất).

---

## Non-Functional Requirements

- Performance: API luật chấm và API mô phỏng có p95 < 300 ms. API giải thích một lượt thi có p95 < 800 ms. Không API nào
  trong ba API này gọi AI.
- Security:
  - Chỉ các role vendor được xem và sửa rubric (giống `ExamDefinitionController`: `PLATFORM_ADMIN`, `ACADEMIC_MANAGER`,
    `ACADEMIC_STAFF`, `PLATFORM_AUTHOR`). Staff chỉ tạo bản nháp, Academic Manager duyệt.
  - Không có trường văn bản tự do nào được đưa vào prompt.
- Maintainability: tuân thủ `docs/CODING_STANDARDS_API.md` và `docs/CODING_STANDARDS_WEB.md` (file ≤ 300 dòng, gói
  `internal/**` ≤ 15 class, dùng `Clock` được inject, message nằm trong `*Constants`).

---

## Success Criteria

- [ ] Độ phủ trang luật chấm: 22/22 task type chuẩn, mỗi tiêu chí có trích dẫn trang Pearson.
- [ ] Độ khớp của màn giải thích: chênh lệch 0 điểm so với snapshot báo cáo trên toàn bộ lượt thi trong bộ test tích hợp.
- [ ] Độ khớp của mô phỏng: 100% case test cho kết quả bằng scorer với cùng điểm tiêu chí. Case test gồm cả các trường hợp
  điều kiện chặn của 7 task type có Content/Form.
- [ ] Hồi quy theo Pearson: có unit test cho đúng các ví dụ trong Score Guide, gồm essay < 120 chữ được 0, essay 150 chữ có
  Form = 1, DI có Content = 0 được 0.
- [ ] Ghim phiên bản: đổi rubric không làm đổi snapshot của báo cáo đã publish (test).
- [ ] Tính lại không gọi AI: tính lại điểm sau khi đổi rubric thực hiện 0 lời gọi vendor (test có mock).
- [ ] Độ ổn định của LLM: chấm cùng 20 bài mẫu 3 lần, ≥ 90% điểm tiêu chí lệch không quá 1 mức.

---

## Out of Scope

- Chỉnh mô tả các mức hoặc prompt trên giao diện (D2); tự ghép công thức hoặc thêm tiêu chí (D3).
- Thay công thức quy đổi tuyến tính 10–90 bằng mô hình thống kê của Pearson (Pearson không công bố).
- Trang luật chấm đầy đủ và bộ mô phỏng trên tenant-web (Host chỉ thấy tham số của phiên bản đã ghim, ngay trong màn
  giải thích điểm).
- Chuyển đổi dữ liệu chấm cũ; DB demo sẽ được reset.
- Rubric cho task type do trung tâm tự định nghĩa (custom task type).

---

## Assumptions

- Production chưa có dữ liệu thật cần giữ; reset DB được chấp nhận như lần đưa V1 lên. Nếu sai, phải thêm migration dữ liệu.
- `azure-gemini` là provider chính. `openai-compatible` sẽ được làm cho theo rubric hoặc ngừng hỗ trợ (câu hỏi mở 4).
- Gemini làm theo được schema yêu cầu trả điểm số nguyên trong thang nhỏ (0–6). Nếu không ổn định, cần thêm bước chấm lại
  hoặc dùng model khác.
- Trọng số kỹ năng tiếp tục do Score Template quản lý; rubric không lặp lại các trọng số này.

---

## Quyết định đã chốt (2026-11-04)

- **Quy trình duyệt:** Academic Staff tạo bản nháp phiên bản rubric, Academic Manager duyệt hoặc từ chối (có lý do).
  Academic Manager và Platform Admin sửa thì áp dụng ngay, không qua duyệt.
- **Phạm vi rubric:** một bộ chung cho nền tảng do vendor quản lý. Khi tạo, mẫu đề ghim phiên bản rubric đang hiệu lực.
  Trung tâm không sửa được rubric.
- **Quyền xem dữ liệu kỳ thi:** mọi nội dung gắn với lượt thi thật (màn giải thích điểm) chỉ Host của trung tâm và
  Examiner được phân công xem được, trên tenant-web. Vendor-web giữ trang luật chấm, bộ mô phỏng và màn chỉnh rubric.
  Host được xem tham số của phiên bản rubric đã ghim vào mẫu đề (ACTIVE hoặc RETIRED), không bao giờ thấy bản nháp.
- **Trạng thái phiên bản:** DRAFT → PENDING → ACTIVE (duyệt = kích hoạt ngay) | REJECTED; ACTIVE cũ → RETIRED.
  Trước khi kích hoạt hiện so sánh với phiên bản đang chạy để xác nhận; mỗi lần kích hoạt đều ghi audit.
- **Dữ liệu hiệu chỉnh:** không có dữ liệu do người chấm. Trợ lý AI tạo bộ dữ liệu tổng hợp: bài viết và transcript nói
  nhắm vào từng mức Pearson (dùng đo độ ổn định của LLM bằng chấm lặp), và ghi âm TTS có chèn ngập ngừng (chỉ dùng kiểm
  tra tính đơn điệu của Fluency). Bảng quy đổi điểm Azure sang 0–5 được gắn nhãn "chưa hiệu chỉnh với dữ liệu người chấm"
  trên giao diện và trong báo cáo.
- **Commit và deploy:** do người dùng tự xử lý; plan không chứa bước release, commit hay thứ tự deploy.
- **Phạm vi đợt này:** làm đầy đủ toàn bộ P1 và P2, gồm bộ mô phỏng, màn chỉnh rubric và giám khảo chấm theo từng tiêu chí.
  Thứ tự phase ưu tiên P1 để có thể dừng giữa chừng mà vẫn dùng được. Không được làm sơ sài để kịp tiến độ.
