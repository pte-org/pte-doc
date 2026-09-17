# Spec: PTE Score Template (V5) + sinh đề ngẫu nhiên theo template

**Date:** 2026-09-16
**Status:** Ready

---

## Problem Statement

Hệ thống chưa có score template: task→skill, thời gian, cờ AI nằm rải rác trong JSON/Java không có trọng số, và đề thi do tác giả chọn tay từng câu. Cần một template versioned (bắt đầu từ APEUni V5) do platform admin quản lý, dùng để **sinh đề ngẫu nhiên** cho kỳ thi 1–4 skill và **chấm điểm có trọng số**, để đổi thang điểm sau này không phải sửa code và không làm đổi điểm cũ.

---

## User Stories

- **[P1]** Là platform admin, tôi muốn xem score template V5 đang ACTIVE với đủ 22 dạng câu (section, số câu min~max, thời gian, cách chấm AI/khách quan, % Overall và % từng skill) để biết hệ thống đang chấm theo thang nào.
  Accepted when: GET template ACTIVE trả 22 item khớp bảng V5 bên dưới.

- **[P1]** Là platform admin, tôi muốn tạo version template mới (clone từ bản hiện có), sửa ở DRAFT rồi kích hoạt, để áp dụng thang điểm mới mà không deploy.
  Accepted when: tại mọi thời điểm có đúng 1 template ACTIVE; template đã ACTIVE/đã được snapshot tham chiếu không sửa được.

- **[P1]** Là host, tôi muốn tạo kỳ thi bằng cách chọn 1, 2, 3 hoặc 4 skill (SPEAKING/WRITING/READING/LISTENING) để hệ thống tự lấy random câu từ question bank.
  Accepted when: đề sinh ra chỉ chứa các dạng thuộc section đã chọn; mỗi dạng có số câu nằm trong [min, max] của template; không câu nào trùng.

- **[P1]** Là host, sau khi tạo kỳ thi, tôi muốn assign một hoặc nhiều Class tham gia để mọi học sinh của các Class đó được ghi danh vào kỳ thi.
  Accepted when: mọi học sinh của Class được assign được enroll đúng 1 lần (học sinh thuộc nhiều Class không bị trùng); tất cả làm chung 1 đề (1 snapshot).

- **[P1]** Là host, khi question bank không đủ câu, tôi muốn thấy chính xác dạng nào thiếu bao nhiêu câu.
  Accepted when: tạo kỳ thi thất bại, không ghi gì vào DB, lỗi liệt kê `{taskType, required, available}` cho mọi dạng thiếu.

- **[P1]** Là thí sinh, tôi muốn điểm được tính theo trọng số của template mà đề thi đã pin, để điểm của tôi không đổi khi admin kích hoạt thang điểm mới.
  Accepted when: kích hoạt template mới rồi xem lại kết quả cũ → điểm không đổi.

- **[P1]** Là thí sinh thi 1–3 skill, tôi chỉ nhận điểm các skill đã thi.
  Accepted when: kết quả chỉ có skill thuộc section đã chọn; Overall chỉ hiển thị khi thi đủ 4 skill.

- **[P2]** Là platform admin, tôi muốn thấy số câu PUBLISHED hiện có theo từng dạng so với `max` của template để bổ sung question bank trước khi host bị lỗi.

- **[P2]** Là host, tôi muốn xem trước cấu trúc đề (dạng, số câu, tổng thời gian ước tính) trước khi xác nhận tạo kỳ thi.

- **[P3]** _(ngoài phạm vi)_ Random đề riêng cho từng thí sinh; tránh lặp câu thí sinh đã làm; host tạo template riêng; import template từ file.

---

## Functional Requirements

**Template**

1. FR-01: Entity `ScoreTemplate` (`code` vd "APEUNI_V5", `version`, `status` DRAFT/ACTIVE/RETIRED, `name`) và `ScoreTemplateItem` (1 dòng / task type).
2. FR-02: `ScoreTemplateItem` gồm: `taskType`, `section`, `sequence`, `minCount`, `maxCount`, `prepSeconds`, `responseSeconds`, `timingMode` (FIXED / RECOMMENDED), `scoringMethod` (AI_SPEECH / AI_TEXT / OBJECTIVE / UNSCORED), `overallWeight`, `speakingWeight`, `writingWeight`, `readingWeight`, `listeningWeight` (decimal, null/0 = không đóng góp).
3. FR-03: Chỉ role platform admin được tạo/sửa/kích hoạt; host chỉ đọc template ACTIVE.
4. FR-04: Kích hoạt 1 template → template ACTIVE cũ chuyển RETIRED trong cùng transaction; tối đa 1 ACTIVE.
5. FR-05: Validate khi kích hoạt: đủ mọi task type `scored`; `0 ≤ minCount ≤ maxCount`, `maxCount ≥ 1`; weight ≥ 0; mỗi skill có tổng weight > 0. **Không** bắt tổng = 100 (bảng V5 làm tròn).
6. FR-06: Migration seed template V5 ở trạng thái ACTIVE với dữ liệu bảng dưới.
7. FR-07: **Xóa** `AiScoringTaskCatalog`, `task-skill-mapping.json`; thông tin prep/response/AI/weights trong `task-timing.json` chuyển sang template (chỉ giữ config cơ chế UI như `preListenSeconds` nếu không đưa vào template). Luồng chấm đọc `scoringMethod` / weights từ template đã pin của snapshot.
   - Hệ thống **chưa deploy** → không cần tương thích ngược: không giữ công thức cũ, không cần xử lý snapshot/attempt thiếu `scoreTemplateVersion` (cột NOT NULL).

**Sinh đề**

8. FR-08: API host tạo kỳ thi nhận `skills: Set<SPEAKING|WRITING|READING|LISTENING>` (1–4 phần tử, không trùng).
9. FR-09: Lấy template ACTIVE; chọn các item có `section ∈ skills`.
10. FR-10: Với mỗi item: `n = random trong [minCount, maxCount]`; lấy random `n` câu **PUBLISHED**, `taskType` khớp, readable bởi host (SHARED + PRIVATE cùng tenant), không trùng.
11. FR-11: Kiểm tra đủ câu cho **tất cả** dạng trước khi ghi; thiếu → lỗi 422 liệt kê mọi dạng thiếu, không tạo blueprint/snapshot/session.
12. FR-12: Thứ tự đề: theo section (SPEAKING → WRITING → READING → LISTENING), trong section theo `sequence` của template. Nếu có SPEAKING: tự thêm 1 câu PERSONAL_INTRODUCTION (UNSCORED) đầu phần Speaking; thiếu câu PI trong bank → báo thiếu như FR-11.
13. FR-13: Sinh đề → publish snapshot **một lần khi tạo kỳ thi**; `ExamSnapshot` lưu `scoreTemplatePublicId` + `scoreTemplateVersion` + `selectedSkills`.
14. FR-14: Timing của câu trong attempt lấy từ template đã pin. Với 5 dạng audio-prompt Speaking (RS, RL, ASQ, RTS, SGD): prep V5 = `preRecordSeconds`, `prepSeconds` tổng vẫn tính động theo độ dài audio (giữ logic `SnapshotPinService`); dạng "No preparation" (RS, ASQ) giữ `preRecordSeconds = 3` cho tiếng beep.
15. FR-15: **Bỏ hẳn** luồng cũ phía host: tạo blueprint soạn tay, `SessionComposition` (subset task type), bulk-create chia batch theo Program ở tenant-web.

**Assign Class**

16. FR-16: Host assign 1..n Class (thuộc tenant của host) vào kỳ thi → enroll toàn bộ học sinh của các Class đó; dedupe học sinh thuộc nhiều Class; assign lại Class đã assign không tạo enrollment trùng (tái dùng unique constraint enrollment).
17. FR-17: Chỉ assign/bỏ assign khi kỳ thi còn trạng thái SCHEDULED.

**Chấm điểm**

18. FR-18: `skillScore = round(10 + 80 × Σ(w_type,skill × avgRaw_type/100) / Σ(w_type,skill))`, tổng chỉ trên các dạng có trong đề và có ≥1 câu SCORED; `avgRaw_type` = trung bình `rawScore` (0–100) các câu của dạng đó.
19. FR-19: Chỉ báo điểm cho skill ∈ `selectedSkills` của snapshot; skill không có dữ liệu → "insufficient data" (giữ hành vi hiện tại).
20. FR-20: Overall chỉ tính khi `selectedSkills` = cả 4; công thức như FR-18 với `overallWeight`.

### Dữ liệu seed V5

| Seq | V5 code | `PteTaskType` | Section | Số câu | Prep/Resp (s) | Chấm | Overall | S | W | R | L |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | RA | READ_ALOUD | SPEAKING | 6–7 | 35/40 | AI_SPEECH | 4 | 9 | | | |
| 2 | RS | REPEAT_SENTENCE | SPEAKING | 10–12 | 0/15 | AI_SPEECH | 7 | 16 | | | 17 |
| 3 | DI | DESCRIBE_IMAGE | SPEAKING | 5–6 | 25/40 | AI_SPEECH | 15 | 31 | | | |
| 4 | RL | RE_TELL_LECTURE | SPEAKING | 2–3 | 10/40 | AI_SPEECH | 6 | 13 | | | 13 |
| 5 | ASQ | ANSWER_SHORT_QUESTION | SPEAKING | 5–6 | 0/10 | AI_SPEECH | 2 | | | | 4 |
| 6 | SGD | SUMMARIZE_GROUP_DISCUSSION | SPEAKING | 2–3 | 10/120 | AI_SPEECH | 9 | 19 | | | 20 |
| 7 | RTS | RESPOND_TO_A_SITUATION | SPEAKING | 2–3 | 10/40 | AI_SPEECH | 6 | 13 | | | |
| 8 | SWT | SUMMARIZE_WRITTEN_TEXT | WRITING | 2–2 | 0/600 | AI_TEXT | 7 | | 28 | 23 | |
| 9 | WE | WRITE_ESSAY | WRITING | 1–1 | 0/1200 | AI_TEXT | 7 | | 31 | | |
| 10 | FIB_Dropdown | FILL_BLANKS_READING_WRITING | READING | 5–6 | ≤120 (rec) | OBJECTIVE | 7 | | | 25 | |
| 11 | MCM_R | MC_READING_MULTIPLE | READING | 2–3 | ≤90 (rec) | OBJECTIVE | 1 | | | 5 | |
| 12 | RO | RE_ORDER_PARAGRAPHS | READING | 2–3 | ≤120 (rec) | OBJECTIVE | 3 | | | 9 | |
| 13 | FIB_Drag&Drop | FILL_BLANKS_READING | READING | 4–5 | ≤120 (rec) | OBJECTIVE | 6 | | | 20 | |
| 14 | MCS_R | MC_READING_SINGLE | READING | 2–3 | ≤90 (rec) | OBJECTIVE | <1 ⚠ | | | 3 | |
| 15 | SST | SUMMARIZE_SPOKEN_TEXT | LISTENING | 1–1 | 0/600 | AI_TEXT | 4 | | 18 | | 10 |
| 16 | MCM_L | MC_LISTENING_MULTIPLE | LISTENING | 2–3 | ≤90 (rec) | OBJECTIVE | 1 | | | | 3 |
| 17 | FIB_L | FILL_BLANKS_LISTENING | LISTENING | 2–3 | ≤120 (rec) | OBJECTIVE | 3 | | | | 8 |
| 18 | HCS | HIGHLIGHT_CORRECT_SUMMARY | LISTENING | 2–3 | ≤90 (rec) | OBJECTIVE | <1 ⚠ | | | 3 | 2 |
| 19 | MCS_L | MC_LISTENING_SINGLE | LISTENING | 2–3 | ≤90 (rec) | OBJECTIVE | <1 ⚠ | | | | 2 |
| 20 | SMW | SELECT_MISSING_WORD | LISTENING | 1–2 | ≤90 (rec) | OBJECTIVE | 1 | | | | 1 |
| 21 | HIW | HIGHLIGHT_INCORRECT_WORDS | LISTENING | 2–3 | ≤120 (rec) | OBJECTIVE | 4 | | | 13 | 8 |
| 22 | WFD | WRITE_FROM_DICTATION | LISTENING | 3–4 | 0/120 | OBJECTIVE | 5 | | 23 | | 13 |

Section tổng thời gian (tham khảo V5): Speaking & Writing 76–84', Reading 23–30', Listening 31–39'.

Quy ước seed: ô "<1%" ⚠ = **0.5**; RA prep = **35s**; với 5 dạng audio-prompt, cột Prep = `preRecordSeconds` (RS/ASQ "No preparation" lưu 3s beep). Các dạng "(rec)" có `timingMode = RECOMMENDED` — giữ giá trị `responseSeconds` hiện tại trong `task-timing.json` làm giới hạn per-question, con số V5 chỉ hiển thị tham khảo.

---

## Non-Functional Requirements

- Performance: sinh đề full 4 skill (tối đa ~84 câu) hoàn tất < 2s p95 với question bank 10k câu; random bằng query DB (không load toàn bộ bank vào memory).
- Security: API template chỉ platform admin ghi; sinh đề chỉ lấy câu host được quyền đọc (tái dùng access policy itembank); API host/thí sinh không trả đáp án đúng.
- Consistency: tạo kỳ thi là all-or-nothing — lỗi ở bất kỳ bước nào không để lại blueprint/snapshot/session mồ côi.
- Immutability: template đã được ≥1 snapshot tham chiếu không sửa/xóa được.

---

## Success Criteria

- [ ] Template V5 seed: 22 item, mọi giá trị khớp bảng trên (test so sánh từng ô).
- [ ] Kỳ thi 4 skill: số câu mỗi dạng ∈ [min, max], tổng câu ∈ [64, 81]; 100 lần sinh không lần nào vi phạm.
- [ ] Kỳ thi 1 skill (mỗi skill) và 2–3 skill: 0 câu thuộc section không chọn.
- [ ] Bank thiếu câu: 0 bản ghi mới trong blueprint/snapshot/session; lỗi liệt kê đủ mọi dạng thiếu.
- [ ] Kích hoạt template mới → điểm của 100% attempt đã có không đổi.
- [ ] Assign 2 Class có 1 học sinh chung → số enrollment = số học sinh distinct; mọi enrollment trỏ cùng 1 snapshot.
- [ ] Unit test FR-18: bộ rawScore đã biết → skill/Overall score đúng từng điểm; kỳ thi 1 skill không có Overall.
- [ ] `AiScoringTaskCatalog`, `task-skill-mapping.json`, API blueprint soạn tay phía host và `SessionComposition` đã bị xóa; `grep` không còn tham chiếu.

---

## Out of Scope

- Đề riêng cho từng thí sinh; chống lặp câu giữa các kỳ thi.
- Host tạo/sửa template riêng.
- Tái tạo thuật toán chấm chính thức của Pearson (vẫn là công thức mô phỏng).
- Enabling skills (ORAL_FLUENCY, PRONUNCIATION, SPELLING…) trên báo cáo điểm.

---

## Assumptions

- "Theo section" dùng enum `PteSection` 4 giá trị hiện có (Speaking và Writing là 2 section riêng, dù V5 gộp chung 1 phần thi).
- Mọi scorer tiếp tục trả `rawScore` thang 0–100 (như `ScoreAggregationService` đang giả định).
- Một kỳ thi = một snapshot dùng chung cho mọi thí sinh.
- Question bank đã có trường `taskType` + `status` PUBLISHED + visibility SHARED/PRIVATE đủ để lọc.
- Hệ thống chưa deploy production → được đổi schema/xóa code cũ tự do, không cần migration dữ liệu thật.
- Học sinh được thêm vào Class **sau khi** đã assign không tự được enroll (host assign lại để bổ sung) — nếu sai, cần thêm event listener membership.
- Kỳ thi = `ExamSession` hiện có (1 snapshot, 1 cửa sổ `opensAt/closesAt`); `capacity` không còn dùng để chia batch.
