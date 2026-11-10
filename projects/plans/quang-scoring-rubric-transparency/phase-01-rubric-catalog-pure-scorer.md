# Phase 1: Catalog rubric + RubricScorer + FormRule + golden test

## Mục tiêu

Khai báo bằng code (record Java, bất biến) rubric của **22 task type chuẩn** theo Pearson Score Guide 2025, viết **một hàm thuần** `RubricScorer.score(effectiveRubric, traitScores)`
trả điểm câu 0-100 kèm vết, và **một hàm thuần** `FormRule.bandFor(TextMetrics)` tính band Form. Chưa chạm DB, chưa chạm scorer hiện có. Phase này tự kiểm chứng được các ví dụ Score Guide
(essay < 120 chữ được 0, essay 150 chữ có Form = 1, DI có Content = 0 được 0).

## Stories/FR covered

- S2 (cổng Content/Form, Form Essay/SST 3 mức, `Σ đạt / Σ tối đa × 100`)
- FR-01 (khai báo rubric), FR-04 (hàm thuần duy nhất), FR-10 (task type khách quan: công thức hiển thị từ cùng khai báo)
- Một phần FR-06: L1, L3, L5 ở mức quy tắc tính; chưa nối scorer

## Files to read first

- `D:\GitHub\pte-org\docs\CODING_STANDARDS_API.md` ("File Size Limit", "Package density and time source", "Constants Management")
- `D:\GitHub\pte-org\pte-doc\plans\reports\261104-pte-scoring-pearson-alignment-review.md` (mục 3, 5, L1-L10)
- Pearson Score Guide trích: `C:\Users\ADMIN\AppData\Local\Temp\pte-guide-dl\fresh.txt` (Windows-1252; bỏ qua ký tự lỗi). Trang: RA 15-16; RS 16-17; DI 18-20; RL 21-24; ASQ 24; SGD 25-28; RTS 29-31;
  SWT 32-33; WE 34-39; Reading 40; SST 41-43; Listening khách quan 44; Pronunciation/Oral Fluency 45-46; cổng Content/Form tr.7-8.
- `pte-api/app/src/main/java/com/pte/scoring/internal/constant/ScoringConstants.java` (các hằng `TASK_TYPE_*`)
- `.../scoring/internal/vendor/gemini/FormCheck.java` (đếm từ/câu hiện tại: `countWords`, `countSentences`; sẽ chỉ còn tính metrics rồi gọi `FormRule.bandFor`)
- `.../gemini/scorer/GeminiWritingScorer.java`, `GeminiSpeakingScorer.java` (công thức cũ trung bình 0-100)
- `.../scoring/internal/service/objective/ObjectiveScoringService.java`, `OptionAnswerScorer.java`, `ReferenceAnswerScorer.java`
- `.../scoring/package-info.java`, `dto/response/package-info.java` (mẫu `@NamedInterface`)
- `pte-api/app/src/test/java/com/pte/architecture/PackageDensityTest.java`, `SourceFileSizeTest.java`, `SourceDebtAllowlist.java`

## Implementation steps

1. **Chốt bảng tiêu chí 22 task type** (theo Pearson):

   | Task type (hằng `TASK_TYPE_*`) | Tiêu chí (khóa: thang, nguồn, trang) | Cổng | Tổng tối đa |
   |---|---|---|---|
   | READ_ALOUD | CONTENT: động = N (số từ đoạn văn), MECHANICAL, tr.15; PRONUNCIATION 0-5 AZURE tr.15,45; ORAL_FLUENCY 0-5 AZURE tr.16,46 | không | N+10 |
   | REPEAT_SENTENCE | CONTENT 0-3 MECHANICAL tr.16; PRONUNCIATION 0-5; ORAL_FLUENCY 0-5 tr.17 | không | 13 |
   | DESCRIBE_IMAGE | CONTENT 0-6 AI_LLM tr.18-19; PRONUNCIATION 0-5; ORAL_FLUENCY 0-5 tr.20 | CONTENT | 16 |
   | RE_TELL_LECTURE | như trên, tr.21-24 | CONTENT | 16 |
   | SUMMARIZE_GROUP_DISCUSSION | như trên, tr.25-28 | CONTENT | 16 |
   | RESPOND_TO_A_SITUATION | như trên, tr.29-31 | CONTENT | 16 |
   | ANSWER_SHORT_QUESTION | VOCABULARY 0-1 MECHANICAL (khớp đáp án trên transcript), tr.24 | không | 1 |
   | SUMMARIZE_WRITTEN_TEXT | CONTENT 0-4 AI_LLM; FORM 0-1 MECHANICAL; GRAMMAR 0-2; VOCABULARY 0-2, tr.32-33 | CONTENT, FORM | 9 |
   | WRITE_ESSAY | CONTENT 0-6; FORM 0-2 MECHANICAL; DEVELOPMENT_STRUCTURE_COHERENCE 0-6; GRAMMAR 0-2; GENERAL_LINGUISTIC_RANGE 0-6; VOCABULARY_RANGE 0-2; SPELLING 0-2 (AI_LLM trừ FORM), tr.34-39 | CONTENT, FORM | 26 |
   | SUMMARIZE_SPOKEN_TEXT | CONTENT 0-4; FORM 0-2 MECHANICAL; GRAMMAR 0-2; VOCABULARY 0-2; SPELLING 0-2, tr.41-43 | CONTENT, FORM | 12 |
   | 12 task type khách quan (MC_READING_SINGLE, MC_READING_MULTIPLE, RE_ORDER_PARAGRAPHS, FILL_IN_THE_BLANKS_DRAG_AND_DROP, FILL_IN_THE_BLANKS_DROPDOWN, MC_LISTENING_SINGLE, MC_LISTENING_MULTIPLE, HIGHLIGHT_CORRECT_SUMMARY, SELECT_MISSING_WORD, FILL_IN_THE_BLANKS_TYPE_IN, HIGHLIGHT_INCORRECT_WORDS, WRITE_FROM_DICTATION) | không có tiêu chí; `ObjectiveRule` mô tả công thức (đúng/sai; +1/-1 sàn 0; cặp liền kề; mỗi ô; LCS theo từ), tr.40, 44 | không | - |

   `PERSONAL_INTRODUCTION` (không thuộc 22 task type, không chấm) KHÔNG vào catalog. Mô tả Pronunciation/Oral Fluency (tr.45-46) khai báo một lần, tham chiếu từ 7 task type.

2. **Gói công khai `com.pte.scoring.rubric`** (`package-info.java` với `@org.springframework.modulith.NamedInterface("rubric")`), record/enum bất biến, không Spring, không I/O:
   `TraitSource` (AI_LLM, AZURE, MECHANICAL, OBJECTIVE); `TraitScale` (cố định `max` hoặc động theo số từ N); `TraitDefinition` (khóa, tên Việt/Anh, thang, mô tả từng mức, nguồn, trang Pearson);
   `TextMetrics` (số từ, số câu, toàn chữ hoa, có dấu câu, chỉ gạch đầu dòng/câu rất ngắn); `FormBand` (khoảng số từ min/max và band); `FormRule` (các `FormBand` + quy tắc phụ cơ học; SWT thêm "đúng 1 câu") với
   **hàm thuần `bandFor(TextMetrics)`**; `ObjectiveRule`; `TaskRubric` (mã task type, kỹ năng Pearson, tiêu chí, cổng, `FormRule`/null, `ObjectiveRule`/null, trang);
   `EffectiveRubric` (tham số hiệu lực **đọc từ hàng phiên bản**: trọng số từng tiêu chí, `FormBand` hiệu lực, cờ bật/tắt cổng, phiên bản bảng Azure; **không** suy ra từ code mặc định lúc chạy);
   `TraitScoreSet` (map khóa -> số nguyên; kèm `wordCount` N cho thang động); `RubricCatalog` (`find`, `all`, `catalogVersion`, và `defaultParameters(taskType)` chỉ dùng để **vật chất hóa** ở Phase 2).
   Trọng số mặc định (khi vật chất hóa) = điểm tối đa Pearson; trọng số là **số nguyên 0-10**; tiêu chí cổng phải có trọng số > 0; tổng trọng số của một task type phải > 0 (kiểm tra ở `EffectiveRubric` và ở validator Phase 2).

3. **`RubricScorer`** (class final trong `com.pte.scoring.rubric`, hàm tĩnh thuần, không `Clock`/I/O): (a) kiểm tra đầu vào: mỗi tiêu chí có điểm nguyên trong [0, max], không thiếu, không thừa; sai -> `RubricScoreException`
   (không làm tròn/cắt); (b) áp cổng: tiêu chí cổng đang bật có điểm 0 -> điểm câu 0, vết ghi tiêu chí kích hoạt; (c) Form: band Form do `FormRule.bandFor` tính từ `TextMetrics` (hoặc truyền vào) và là một tiêu chí; band 0 kích hoạt cổng Form khi cổng bật;
   (d) tổng `Σ(trọng số × đạt / tối đa) / Σ trọng số × 100`, HALF_UP thành số nguyên (BigDecimal; vết giữ giá trị chưa làm tròn). Trả `ScoreTrace`.
   **Read Aloud**: thang Content động = N; N phải >= 1 (N = 0 là lỗi dữ liệu đề: `RubricScoreException` với mã trong `RubricConstants`); đạt Content = max(0, N − lỗi) nằm trong [0, N]; N được lưu trong `TraitScoreSet` để tính lại.

4. **Khai báo catalog** trong `com.pte.scoring.internal.rubric.catalog.{speaking,writing,objective}` + `RubricCatalogImpl` (`@Component`). Mô tả mức chép nguyên văn tiếng Anh từ Score Guide kèm số trang; tên hiển thị tiếng Việt do nhóm viết;
   tách file theo task type. Bảng ngưỡng Azure -> 0-5 khai báo ở Phase 5 với cờ `calibrated=false` và nhãn hiển thị (hằng trong `RubricConstants`). `catalogVersion = 1`;
   quy tắc: **sửa mô tả mức bắt buộc tăng `catalogVersion`**; sửa cấu trúc (khóa/thang tiêu chí) cũng tăng và tạo phiên bản rubric mới (Phase 2).

5. **Quy tắc Form mặc định** (khai báo, không hard-code trong scorer): Essay 200-300 = 2; 120-199 và 301-380 = 1; còn lại 0. SST 50-70 = 2; 40-49 và 71-100 = 1; còn lại 0. SWT: đúng một câu và 5-75 từ = 1, còn lại 0.
   Quy tắc phụ cơ học (toàn chữ hoa, không dấu câu, chỉ gạch đầu dòng/câu rất ngắn) -> band 0 cho SWT, WE, SST. Việc ĐẾM nằm ở `FormCheck` (Phase 3) nhưng **band chỉ do `FormRule.bandFor` quyết định**.

6. **Quy tắc khách quan khai báo, không thực thi**: `ObjectiveRule` chỉ chứa mô tả và hằng số hiển thị (FR-10). Thêm test đối chiếu mô tả với hành vi `ObjectiveScoringService` cho từng quy tắc.

7. **Hằng số và lỗi**: `RubricConstants` (gói `internal/constant`) cho mọi message/mã lỗi (thiếu/ngoài thang/tiêu chí lạ, N = 0, trọng số không hợp lệ) và các giới hạn kích thước (số phần tử `traitScores`, kích thước JSON tham số: LOW-3, dùng ở Phase 2, 8, 9, 10);
   `RubricScoreException` đặt trong gói `rubric` (không dồn vào `internal/exception`, đang 8 file).

8. **Test vàng** trong `app/src/test/java/com/pte/scoring/rubric/`: `RubricScorerGoldenTest`, `FormRuleBandTest` (từng khoảng và từng quy tắc phụ), `RubricCatalogCoverageTest` (22/22, trang Pearson, đủ mô tả mọi mức 0..max, tổng tối đa khớp bảng).

9. **Architecture test một nguồn** `RubricScoreSingleSourceTest` (`app/src/test/java/com/pte/architecture/`): cấm tính điểm câu cho task type AI ngoài `RubricScorer` (cấm `average()` trên map sub-score trong `vendor/**`) và **cấm tính band Form ngoài `FormRule.bandFor`**
   (ví dụ so sánh số từ với hằng 200/300/120... bên ngoài catalog). Allowlist ban đầu liệt kê scorer cũ, thu hẹp ở Phase 3 và 5 đến rỗng.

## Acceptance criteria

- 22/22 task type chuẩn có rubric; `PERSONAL_INTRODUCTION` bị từ chối rõ ràng; mọi tiêu chí không khách quan có mô tả đủ mức và trang Pearson; tổng tối đa: DI/RL/RTS/SGD = 16, WE = 26, SWT = 9, SST = 12, RS = 13.
- Ví dụ vàng (HALF_UP):
  - Essay 50 chữ (Form 0) -> 0. Essay 150 chữ: Form = 1; CONTENT 4, DSC 4, GRAMMAR 1, GLR 4, VOCABULARY_RANGE 1, SPELLING 1 -> 16/26 -> 62.
  - DI CONTENT 0, PRON 5, FLUENCY 5 -> 0; DI 4/3/4 -> 11/16 -> 69.
  - SST 45 chữ: Form = 1; SST 30 chữ: Form = 0 -> 0. SWT 2 câu hoặc toàn chữ hoa: Form = 0 -> 0.
  - **Read Aloud**: N = 1, 30, 80 với cùng tỉ lệ lỗi cho điểm đúng công thức `(N − lỗi + P + F)/(N + 10)`; N = 0 bị từ chối.
- Giá trị ngoài thang/thiếu tiêu chí/tiêu chí lạ làm `RubricScorer` ném lỗi (không cắt, không làm tròn).
- Tắt cổng: không kích hoạt nhưng điểm vẫn đúng `Σ đạt / Σ tối đa`; trọng số mặc định cho kết quả bằng `Σ đạt / Σ tối đa`; trọng số ngoài 0-10, cổng có trọng số 0, hoặc tổng trọng số 0 bị từ chối.
- `RubricScoreSingleSourceTest` xanh (kể cả quy tắc không tính band Form ngoài `FormRule`); không file > 300 dòng; không gói `internal/**` > 15 class.

## Validation commands

```powershell
cd D:\GitHub\pte-org\pte-api
.\mvnw.cmd -pl app -DskipTests compile
.\mvnw.cmd -pl app test -Dtest="RubricScorerGoldenTest,FormRuleBandTest,RubricCatalogCoverageTest,RubricScoreSingleSourceTest"
.\mvnw.cmd -pl app test -Dtest="PackageDensityTest,SourceFileSizeTest,NoDirectClockAccessTest,ModuleStructureTest"
```

## Design Constraints

- `docs/CODING_STANDARDS_API.md` bắt buộc đọc đủ: file <= 300 dòng, `internal/**` <= 15 class/gói, không `Instant.now()`/`Clock.systemUTC()` trực tiếp, message và mã lỗi trong `*Constants.java`.
- `RubricScorer` và `FormRule.bandFor` thuần: không `@Service`, không DB, không AI, không đồng hồ.
- `EffectiveRubric` chỉ được dựng từ tham số của hàng phiên bản; catalog trong code cung cấp mô tả/cấu trúc và giá trị mặc định **chỉ để vật chất hóa**, không để quyết định điểm lúc chạy.
- Mô tả mức và thang Pearson bất biến (D2/D3 ngoài phạm vi); không trường văn bản tự do nào đi vào prompt.
- Gói `com.pte.scoring.rubric` là API công khai Modulith: chỉ kiểu dữ liệu và hàm thuần.
- Chưa sửa scorer hiện có; thay đổi hành vi thuộc Phase 3 và 5.
- Preflight: đã đọc đủ `docs/CODING_STANDARDS_API.md`. Quy ước thực tế: mã lỗi là chuỗi UPPER_SNAKE trong `*Constants` (`ScoringConstants`);
  lỗi miền kế thừa `com.pte.shared.exception.DomainException(HttpStatus, code)` (ví dụ `UnsupportedTaskTypeException`); gói con công khai
  mở bằng `package-info.java` với `@org.springframework.modulith.NamedInterface`; kiểm tra Modulith ở `app/src/test/java/com/pte/ModuleStructureTest.java`
  (không nằm trong `architecture/`); ratchet ở `com/pte/architecture/{PackageDensityTest,SourceFileSizeTest,NoDirectClockAccessTest}` dùng
  `SourceDebtAllowlist`. Hằng task type có sẵn trong `ScoringConstants.TASK_TYPE_*` (internal) — gói công khai `rubric` không được import gói `internal`,
  nên mã task type trong catalog dùng chuỗi qua hằng của `RubricConstants`/catalog nội bộ. Ngoại lệ (QUAL-003): gói công khai `rubric` import `internal.constant.RubricConstants` để mã lỗi nằm đúng ở `*Constants`; hợp lệ trong cùng module,
  ghi nhận như một ngoại lệ có chủ đích. `MAX_TRAIT_SCORE_ENTRIES` chưa được áp ở Phase 1: các phase đưa điểm tiêu chí vào hệ thống (2, 8, 10) phải áp (QUAL-004).

## Quality and Testing State

- Checkpoint: Unit tests: yes (--tdd) · Quality gate: yes (--hard)
- Quality: approved (receipt: quality/phase-01-rubric-catalog-pure-scorer-receipt.json)
- Testing: passed (114 rubric tests + architecture ratchets)

## Risks

- Văn bản mô tả dài vượt 300 dòng/file: tách theo task type và nhóm mức.
- Thang động RA làm `TraitDefinition` phức tạp: hai biến thể `TraitScale`, test riêng N = 1, 30, 80.
- Mô tả khách quan lệch `ObjectiveScoringService`: test đối chiếu ở bước 6.
- Chép sai nguyên văn Pearson: kiểm chéo từng mô tả với `fresh.txt` theo trang.
