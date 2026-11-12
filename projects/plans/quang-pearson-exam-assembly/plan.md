# Plan: Tổ chức đề thi chuẩn Pearson — thời gian, phân chia câu hỏi, độ khó CEFR

Status: 🟡 Đã code, chờ người dùng kiểm tra (2026-11-03)
Date: 2026-11-03
Created by: quang
Mode: Hard
Repo chạm tới: `pte-api` (assessment, itembank, media), `pte-web` (vendor-web, tenant-web, api-client), `pte-doc`
Test:
- Backend: `.\mvnw.cmd -pl app test` xanh. Sau mỗi phase backend thì build lại container `app` local; profile `local-schema` không chạy Flyway nên áp migration bằng tay vào `pte-postgres`.
- Web: `tsc`, `eslint`, `vitest` cho `vendor-web`, `tenant-web`, `packages/ui`. Không mở trình duyệt.
- Chuẩn bắt buộc đọc trước khi sửa: `docs/CODING_STANDARDS_API.md`, `docs/CODING_STANDARDS_WEB.md`, `docs/API_RESPONSE_SETUP.md`, `docs/COMMON_EXCEPTION_SETUP.md`.

Agent không commit, không push.

---

## 1. Mục tiêu

Luồng tổ chức kỳ thi là phần bị hội đồng hỏi vặn nhiều nhất. Plan này làm cho mọi con số trong đề thi (thời gian từng phần, số câu từng dạng, mức độ khó) **có căn cứ từ tài liệu Pearson, tính được bằng công thức rõ ràng, tái lập được, và có log để đối chứng**.

Ba câu hỏi phải trả lời được bằng code và bằng báo cáo:

1. Một đề thi dài bao lâu, và vì sao con số đó nằm trong chuẩn Pearson?
2. Vì sao đề này có đúng từng ấy câu mỗi dạng bài?
3. Vì sao các câu hỏi được chọn có độ khó như vậy, và các đề khác nhau có tương đương không?

## 2. Căn cứ từ Pearson (trích nguyên văn, có nguồn)

| # | Nội dung | Nguồn |
|---|---|---|
| P1 | "PTE Academic … is a maximum of 2 hours 15 minutes long" | *PTE Academic Test Taker Score Guide*, phần giới thiệu |
| P2 | Part 1 Speaking & Writing (approx. 76–84 minutes); Part 2 Reading (approx. 23–30); Part 3 Listening (approx. 31–39) | Score Guide, mục 7 |
| P3 | "The minimum and maximum timings … do not add up to the total timings stated. This is because different versions of the test are balanced for total length. No test taker will get the maximum or minimum times indicated." | Score Guide, mục 7, ghi chú 1 |
| P4 | "Test forms are drawn from the item bank in a stratified random sampling procedure. Selections are stratified according to (a) aspect to be measured, (b) item difficulty, and (c) length of time." | *Aligning PTE Academic Test Scores to the CEFR* (Pearson, 2010) |
| P5 | Người soạn câu nhắm "CEF levels from upper B1 to lower C2" và phải ghi mức CEFR mục tiêu cho từng câu; người duyệt đánh giá lại; cả hai được lưu cùng câu trong ngân hàng | *Aligning …* (2010) |
| P6 | Độ khó được hiệu chuẩn bằng mô hình Rasch (IRT 1 tham số) sau hai đợt thi thử | *Aligning …* (2010); De Jong & Zheng (2016) |
| P7 | Mỗi thí sinh làm 52–64 câu, 20 dạng bài (phiên bản đề 2022) | *Specification for PTE Academic* V7 (06/2022) |

Pearson **không công bố thuật toán** lắp đề. Plan này mô phỏng đúng hành vi mà P3 và P4 mô tả, và ghi rõ điều đó trong báo cáo.

Lưu ý về P7: bản đề 2022 khác cấu trúc hiện tại (Speaking & Writing 54–67 phút trong bản 2022, 76–84 trong Score Guide hiện hành). Vì vậy khung thời gian phải lưu thành dữ liệu sửa được, không viết cứng trong code.

## 3. Hiện trạng (đo trên code ngày 2026-11-03)

### 3.1 Thời gian

- `AttemptStartFlow`: `examEndTime = startedAt + Σ(prepSeconds + responseSeconds)` trên mọi câu của đề. Không có trần.
- `TimerService`: chỉ READING dùng ngân sách chung cả phần; các phần khác đếm theo từng câu.
- Mô hình thời gian **không tính** thời gian phát audio, đọc đề và chuyển câu.

Mẫu chuẩn đang seed, tính theo `số câu × (prep + response)`:

| Phần | Ngắn nhất (mọi dạng = min) | Dài nhất (mọi dạng = max) | Khung Pearson | Kết luận |
|---|---|---|---|---|
| Speaking & Writing | 64,7 phút | 71,7 phút | 76–84 | Không bao giờ đạt |
| Reading | 21,0 | 27,8 | 23–30 | Một phần tổ hợp đạt |
| Listening | 21,3 | 26,2 | 31–39 | Không bao giờ đạt |
| Tổng | 107,0 | 125,6 | ≤ 135 | — |
| Số câu | 65 | 85 | 52–64 (bản 2022) | Cao hơn |

Muốn ép khung thì **phải sửa mô hình thời gian trước** (Phase 1). `MediaAsset.durationSeconds` đã lưu độ dài audio, đây là dữ liệu cần cho mô hình mới.

### 3.1a Sau khi sửa mẫu theo bảng APEUni V5 (2026-11-03)

Mẫu ACTIVE mới (`V24`) dùng đúng số câu, prep, answer time và trọng số của bảng. Thời gian theo `số câu × (prep + response)`, chưa cộng audio:

| Phần | Ngắn nhất | Dài nhất | Khung Pearson |
|---|---|---|---|
| Speaking & Writing | 63,4 phút | 70,2 | 76–84 |
| Reading | 28,0 | 37,0 | 23–30 |
| Listening | 34,5 | 46,5 | 31–39 |

- **Reading và Listening** đã có tổ hợp nằm trong khung. Listening không cần cộng audio vì answer time ≤ 1–1.5 phút của bảng đã gồm thời gian nghe. Cộng thêm audio sẽ tính hai lần: Phase 1 phải có cờ theo dạng bài cho biết audio nằm trong answer time (Listening) hay phát trước khi đếm giờ (Speaking).
- **Speaking & Writing** vẫn thấp hơn khung 76–84 khoảng 6–13 phút. Phần thiếu đến từ audio phát trước khi đếm giờ (Re-tell Lecture, Summarize Group Discussion, Respond to a Situation, Answer Short Question, Repeat Sentence), Personal Introduction và hướng dẫn. Phase 1 xử lý bằng `stimulus` cho các dạng này.
- Các answer time ghi "≤" trong bảng được lưu bằng cận trên (1–1.5 phút = 90 giây; 1.5–2 phút và ≤ 2 phút = 120 giây). Đây là giả định, đổi bằng một migration mới nếu cần.

### 3.2 Chọn số câu và câu hỏi

- `ExamBlueprintAssembler.roll()` bốc số câu mỗi dạng **độc lập**, phân phối đều trong `min..max`, không nhìn tổng. Có thể ra đề "mọi dạng = max", trái với P3.
- `drawDeterministic` xáo trộn ngân hàng rồi lấy `n` câu đầu. Không phân tầng theo độ khó hay thời lượng, trái với P4.
- Tạo đề tái lập theo `seed` (`generateDeterministic`). Phải giữ tính chất này.

### 3.3 Độ khó

- Bảng `questions` không có trường độ khó nào. Không có CEFR, IRT hay p-value.

### 3.4 Mẫu bài thi

- Mẫu admin luôn `STANDARD_PTE`; mẫu trung tâm luôn `CUSTOM`.
- `validateWithinBase` chỉ kiểm tra dạng bài của mẫu trung tâm thuộc mẫu gốc. Quyết định sản phẩm ngày 2026-11-03: **giữ nguyên tự do này** cho trung tâm.

### 3.5 Tạo kỳ thi ở trung tâm

- Wizard 4 bước: Exam details (chọn mẫu, kỹ năng) → Schedule & policy → Audience → Review & create.
- Backend bốc câu ngẫu nhiên khi tạo (`generateExam`). Trung tâm không chọn từng câu.

## 4. Thiết kế tổng thể

```
Câu hỏi (itembank)                      Mẫu bài thi (assessment)            Kỳ thi (session)
 ├ thời lượng thật (stimulus)             ├ dạng bài: min..max, prep, resp   ├ mẫu đã chọn
 ├ cefr_level                              ├ khung thời gian 3 phần + trần    ├ tỉ lệ CEFR (ghi đè)
 └ trạng thái APPROVED                     └ tỉ lệ CEFR mục tiêu              └ nhãn Chuẩn / Tùy chỉnh
            │                                        │                               │
            └──────────────► Bộ lắp đề (3 tầng, theo P4) ◄─────────────────────────┘
                              1. Kỹ năng/dạng bài  → số câu mỗi dạng (Phase 2)
                              2. Thời lượng         → tổng mỗi phần trong khung (Phase 1–2)
                              3. Độ khó CEFR        → chọn câu theo tỉ lệ (Phase 5)
                                          │
                                          ▼
                       Đề đã tạo + Biên bản lắp đề (assembly report, lưu kèm đề)
```

Nguyên tắc:

- **Mọi lựa chọn ngẫu nhiên đều theo seed.** Cùng mẫu, cùng ngân hàng, cùng seed thì ra cùng đề. Đây là cách trả lời "chứng minh đề này sinh ra như thế nào".
- **Mọi đề đều có biên bản lắp đề:** số câu từng dạng, thời gian từng phần, phân bố CEFR, các chỗ phải lấy bù. Báo cáo và hội đồng dùng biên bản này để đối chứng.
- **Không phá mẫu cũ.** Mẫu không có khung hay tỉ lệ CEFR thì chạy đúng như trước, có test hồi quy theo seed.

## 4a. Phân quyền

Lấy từ code: `SecurityRoles`, `SecurityPolicy`, `ItembankAccessPolicy`, `ExamDefinitionApprovalWorkflow`. Plan **không thêm vai trò và không đổi quy tắc quyền**; khung thời gian, tỉ lệ CEFR và `cefr_level` đi theo đúng quyền của mẫu và câu hỏi hiện có.

Phía nền tảng (vendor) có 4 vai trò:

- **Academic Staff**: viết bản nháp và nhập liệu học thuật (`ACADEMIC_DRAFT_WRITE`, `ACADEMIC_IMPORT`).
- **Academic Manager**: như Staff, thêm quyền duyệt, chấp thuận và xuất bản/kích hoạt (`ACADEMIC_REVIEW`, `ACADEMIC_APPROVE`, `ACADEMIC_PUBLISH`), nhưng không duyệt hay kích hoạt thứ do chính mình tạo.
- **Platform Manager**: chỉ vận hành nền tảng (`PLATFORM_OPERATIONS`), không có quyền học thuật.
- **Platform Admin**: toàn quyền.

`PLATFORM_AUTHOR` chỉ là tên cũ, được quy về Academic Staff (`SecurityRoles.canonicalize`), nên không phải vai trò riêng.

| Việc | Academic Staff | Academic Manager | Platform Manager | Platform Admin | Host Admin (trung tâm) |
|---|---|---|---|---|---|
| Tạo câu hỏi, nhập `cefr_level` | ✔ | ✔ | — | ✔ | — |
| Sửa câu nháp, kể cả `cefr_level` | Câu của mình | Câu của mình | — | ✔ mọi câu | — |
| Duyệt câu (CEFR có hiệu lực khi câu được duyệt) | — | ✔, trừ câu của mình | — | ✔ | — |
| Tạo mẫu nền tảng DRAFT | ✔ | ✔ | — | ✔ | — |
| Sửa mẫu DRAFT: dạng bài, khung thời gian, tỉ lệ CEFR | Mẫu của mình | Mẫu của mình | — | ✔ mọi mẫu | — |
| Duyệt và kích hoạt mẫu nền tảng | — | ✔, trừ mẫu của mình | — | ✔ | — |
| Sửa mẫu của trung tâm (tự do) | — | — | — | — | ✔ |
| Chọn chế độ độ khó khi tạo kỳ thi | — | — | — | — | ✔ |

Ghi chú:

- "Của mình" theo `author_user_public_id`. Bản nháp cũ chưa có tác giả thì Academic Staff sửa được (`SecurityPolicy.canModifyAcademicDraft`).
- Trong plan, "mẫu nền tảng" là mẫu không có `tenant_id`, do các vai trò học thuật phía nền tảng quản lý theo bảng trên.

## 5. Phases

- [x] Phase 1: Mô hình thời gian và khung Pearson — [phase-01-time-model.md](phase-01-time-model.md) — làm xong phần backend (`V25`, `V26`, `ExamTimeModel`, endpoint `time-frame`, `parts` trong feasibility). Đổi so với kế hoạch: bỏ `overhead`; dùng cờ `stimulus_before_timer` thay vì cộng audio cho mọi dạng
- [x] Phase 2: Lập kế hoạch số câu theo khung — [phase-02-balanced-planner.md](phase-02-balanced-planner.md) — `BalancedCountPlanner`, biên bản lắp đề (`V27`), kiểm tra khung khi kích hoạt. Đổi: trần tổng là ràng buộc mềm
- [x] Phase 3: Nhãn "Chuẩn Pearson" cho mẫu trung tâm — [phase-03-host-standard-label.md](phase-03-host-standard-label.md) — R1–R4 và R6 ở backend; phần CEFR (R5) ở mức kỳ thi, chỉ hiển thị
- [x] Phase 4: CEFR trên câu hỏi — [phase-04-question-cefr.md](phase-04-question-cefr.md) — cột `cefr_level` (`V28`), bắt buộc khi gửi duyệt câu thi; form, chip, bộ lọc ở vendor-web. Chưa có bộ lọc CEFR phía server
- [x] Phase 5: Chọn câu phân tầng theo CEFR và thời lượng — [phase-05-stratified-draw.md](phase-05-stratified-draw.md) — `StratifiedQuestionPicker` (`V29`). **Chưa làm** bước chọn câu theo thời lượng audio thật (tầng c)
- [x] Phase 6: Tạo kỳ thi ở trung tâm — [phase-06-exam-wizard.md](phase-06-exam-wizard.md) — mix riêng của kỳ thi (`V30`), `DifficultyPicker`, chip trên danh sách mẫu. Chưa dựng thẻ "Dự kiến đề thi" từ dữ liệu feasibility
- [x] Phase 7: Giao diện admin — [phase-07-admin-web.md](phase-07-admin-web.md) — hộp thoại khung thời gian và mix CEFR, thanh thời lượng. Chưa làm: heatmap độ phủ CEFR ở Content Hub, khoảng "X–Y phút" ở tab Timeline
- [x] Phase 8: Báo cáo nghiệp vụ tổ chức đề thi — [phase-08-report.md](phase-08-report.md) — `pte-doc/plans/reports/261103-exam-assembly-time-cefr-report.md`

## 6. Thứ tự và phụ thuộc

```
1 ─► 2 ─► 3
│         │
4 ─► 5 ───┴─► 6
1,2,4 ─► 7
1..7 ─► 8
```

- Phase 1 và 4 độc lập nhau (một bên ở assessment và media, một bên ở itembank), làm song song được.
- Phase 5 cần 2 (đã biết số câu) và 4 (đã có CEFR).
- Phase 6 cần 3 (nhãn) và 5 (tỉ lệ CEFR).

## 6a. Những điểm thực hiện khác kế hoạch

1. **Số hiệu migration** dịch lên vì `V24` được dùng để sửa mẫu chuẩn theo bảng APEUni V5: thực tế là `V24` mẫu chuẩn, `V25` khung thời gian, `V26` stimulus, `V27` biên bản, `V28` CEFR câu hỏi, `V29` mix của mẫu, `V30` mix của kỳ thi.
2. **Không có `overhead`.** Chưa có dữ liệu nào chứng minh cần; thay bằng cờ `stimulus_before_timer`: audio chỉ được cộng vào thời lượng với năm dạng phát audio trước khi đếm giờ, vì answer time của Listening trong bảng APEUni đã gồm thời gian nghe.
3. **Trần tổng 135 phút là ràng buộc mềm.** Khung từng phần là cứng. Lý do trong báo cáo, mục 5.4.
4. **Một cột CEFR duy nhất** (`cefr_level`), không có mức đề xuất hay mức thực nghiệm (quyết định người dùng).
5. **Mix CEFR mặc định chia đều B1–C2** (25% mỗi mức): Pearson không công bố tỉ lệ.
6. **Chưa làm tầng (c) ở bộ chọn câu** (ưu tiên câu theo thời lượng audio thật).
7. Seed được trộn (`Seeds`, SplitMix64) vì `java.util.Random` với seed nhỏ liên tiếp cho kết quả gần giống nhau; trọng số chia cho số tổ hợp cùng thời lượng để không dồn về mép ngắn của khung.

## 7. Migration dự kiến

| Version | Nội dung | Phase |
|---|---|---|
| `V24__correct_standard_exam_template.sql` | **Đã làm 2026-11-03.** Mẫu nền tảng ACTIVE mới theo bảng APEUni V5: số câu, prep, answer time, trọng số Overall và từng kỹ năng. Bản cũ chuyển RETIRED, không sửa tại chỗ để đề đã xuất bản giữ nguyên cách tính điểm | 0 |
| `V25__exam_time_model.sql` | Thời lượng chuẩn và overhead theo dạng bài; khung thời gian trên mẫu; nạp khung cho mẫu ACTIVE | 1 |
| `V26__exam_assembly_report.sql` | Lưu biên bản lắp đề và seed kèm đề | 2 |
| `V27__question_cefr.sql` | Cột `cefr_level` trên câu hỏi | 4 |
| `V28__cefr_target_mix.sql` | Tỉ lệ CEFR mục tiêu trên mẫu; tỉ lệ ghi đè trên kỳ thi | 5–6 |

Số version cuối cùng chốt khi làm, nối tiếp `V23` hiện có.

## 8. Rủi ro

| Rủi ro | Ảnh hưởng | Giảm thiểu |
|---|---|---|
| Thời lượng audio thiếu (`durationSeconds = null` với media cũ) | Thời lượng thật tính sai | Dùng giá trị ước lượng theo dạng bài làm dự phòng; báo số câu thiếu dữ liệu ở trang readiness; có job đo lại |
| Khung quá chặt so với ngân hàng, không tổ hợp nào đạt | Không tạo được đề | Kiểm tra khả thi khi kích hoạt mẫu; thông báo phần thiếu hoặc dư bao nhiêu phút |
| Ngân hàng thiếu câu ở một mức CEFR | Không đủ câu theo tỉ lệ | Lấy bù từ mức liền kề, ghi vào biên bản, không chặn tạo đề |
| Đổi thuật toán làm đề sinh từ cùng seed khác trước | Đề cũ không tái lập được | Đề đã tạo lưu sẵn danh sách câu, không sinh lại; ghi phiên bản thuật toán vào biên bản |
| CEFR do người gắn, có tính chủ quan | Hội đồng chất vấn độ tin cậy | Giao cho người có vai trò chuyên môn như Pearson (P5); `cefr_level` là trường của câu, có hiệu lực khi Academic Manager (thâm niên PTE) duyệt câu; báo cáo phân bố CEFR của ngân hàng |
| Hội đồng hỏi "sao không dùng IRT như Pearson" | — | Báo cáo trình bày: IRT cần dữ liệu thi thử (Pearson ≥ 200 lượt mỗi câu); hệ thống thiết kế sẵn chỗ thay nguồn độ khó |

## 9. Ngoài phạm vi (ghi vào báo cáo dưới mục "Hướng phát triển")

- Hiệu chuẩn IRT/Rasch và quy điểm (equating) giữa các đề.
- Độ khó thực nghiệm (p-value, IRT) tự động từ bài làm. CEFR do quản lý học thuật xác nhận (quyết định 2026-11-03).
- Đồng hồ theo phần cho Listening (cần đối chiếu format Pearson riêng).
- Ràng buộc số câu hay thời gian lên mẫu trung tâm (quyết định sản phẩm: không ràng buộc).
