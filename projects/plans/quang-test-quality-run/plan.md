# Plan: Chạy unit test và quality gate cho đợt dọn maintainability (chỉ chạy, chỉ báo)

- Tác giả: quang
- Ngày: 2026-10-26
- Repo: `D:\GitHub\pte-org\pte-api`, nhánh `quang/refactor/api-maintainability`
- Người thực hiện: agent kiểm thử (không phải agent đã viết code)

## 1. Mục tiêu

Kiểm tra đợt dọn code cuối của plan `quang-api-maintainability`. Agent chỉ chạy lệnh, đọc kết quả và viết báo cáo lỗi.

Đợt dọn gồm ba thay đổi:

1. Test chuyển từ `Clock.systemUTC()` sang `com.pte.TestClocks.fixed()` (53 file test).
2. Gỡ các constructor production chỉ phục vụ test (khoảng 30 lớp service). Gỡ luôn fallback `clock != null ? clock : Clock.systemUTC()`. Tạo `com.pte.itembank.ItembankFixtures` cho test.
3. Xoá khoảng 70 import thừa trong main và test.

## 2. Luật bắt buộc

| Được làm | Không được làm |
|---|---|
| Chạy compile, test, ck:quality ở chế độ chỉ báo cáo | Sửa bất kỳ file `.java`, `.sql`, `.yml` nào |
| Đọc code để chẩn đoán nguyên nhân | Tắt test, thêm `@Disabled`, sửa allowlist ratchet |
| Viết báo cáo vào `pte-doc/plans/reports/` | Commit, push, stash, `git reset`, `git checkout --` |
| Ghi đề xuất sửa trong báo cáo | Gọi `ck:fix` hoặc tự áp dụng fix |
| Khởi động container Postgres test | `docker compose down -v`, xoá volume |

Nếu có lỗi, ghi vào báo cáo rồi chạy tiếp các bước còn lại. Không dừng ở lỗi đầu tiên trừ khi compile hỏng (khi đó bước 4 trở đi không chạy được).

Không in mật khẩu hay nội dung file env ra log hoặc vào báo cáo.

## 3. Chuẩn bị

1. Đọc `docs/CODING_STANDARDS_API.md`, đặc biệt mục "Package density and time source". Đây là chuẩn dùng cho quality gate.
2. Ghi lại trạng thái ban đầu vào báo cáo:

   ```bash
   cd /d/GitHub/pte-org/pte-api
   git branch --show-current
   git status --short | wc -l
   git diff --stat | tail -1
   ```

3. Postgres cho test tích hợp (bước 5): container `pte-test-pg` trên `127.0.0.1:55439`. Cách dựng DB test dùng một lần nằm trong `pte-doc/projects/plans/quang-entity-consolidation/local-dev-runbook.md`. Nếu thiếu thông tin đăng nhập, hỏi người dùng. Không đoán mật khẩu.

## 4. Các bước chạy

### Bước 1: Biên dịch sạch từ đầu

Biên dịch tăng dần có thể che lỗi, nên phải xoá output cũ trước.

```bash
cd /d/GitHub/pte-org/pte-api
rm -rf app/target/classes app/target/test-classes
./mvnw.cmd -q -pl app test-compile 2>&1 | tee /tmp/qa-compile.log
grep -E "ERROR.*\.java:\[" /tmp/qa-compile.log
```

Đạt khi không có dòng `ERROR`. Nếu `rm` báo thư mục bị khoá, đợi vài giây rồi chạy lại.

### Bước 2: Ratchet kiến trúc

```bash
./mvnw.cmd -pl app test -Dtest='NoDirectClockAccessTest,SourceFileSizeTest,PackageDensityTest' 2>&1 | tail -40
```

Đạt khi cả ba lớp xanh. Allowlist trong `app/src/test/resources/architecture/` phải giữ nguyên là rỗng.

### Bước 3: Toàn bộ unit test (không có Postgres)

```bash
./mvnw.cmd -pl app test 2>&1 | tee /tmp/qa-unit.log
grep -E "Tests run:|FAIL|ERROR\]" /tmp/qa-unit.log | tail -30
```

Mốc trước đợt dọn (theo `AGENTS.md`): 2852 test, 0 failure, 58 skipped (42 test Postgres bị gate theo env và 16 AI spike). Ghi con số thực tế vào báo cáo, kể cả khi bằng mốc.

### Bước 4: Spring context khởi động được

Unit test không bắt được lỗi một bean có hai constructor mà thiếu `@Autowired`. Chạy riêng các test `@SpringBootTest` hoặc `@ApplicationModuleTest`:

```bash
grep -rlE "@SpringBootTest|@ApplicationModuleTest" app/src/test/java | sed 's#.*/##; s#\.java##' | paste -sd, -
./mvnw.cmd -pl app test -Dtest='<danh sách vừa in>' 2>&1 | tail -40
```

Nếu bước 3 đã chạy các test này, chỉ cần trích kết quả từ `/tmp/qa-unit.log`. Ghi các lỗi `BeanInstantiationException`, `No default constructor` hoặc `UnsatisfiedDependencyException`, nếu có.

### Bước 5: Test tích hợp Postgres

Cần container ở mục 3. Các biến:

- `INBOX_TEST_DB_URL`, `INBOX_TEST_DB_USER` và `INBOX_TEST_DB_PASSWORD`: biến môi trường.
- `-Dlifecycle.test.db.url=jdbc:postgresql://127.0.0.1:55439/lifecycle_test?currentSchema=migration_clean`: system property.

```bash
./mvnw.cmd -pl app test "-Dlifecycle.test.db.url=jdbc:postgresql://127.0.0.1:55439/lifecycle_test?currentSchema=migration_clean" 2>&1 | tee /tmp/qa-pg.log
grep -E "Tests run:|FAIL" /tmp/qa-pg.log | tail -30
```

Mốc trước đợt dọn: 42 test Postgres chạy và xanh, chỉ còn 16 skipped (các AI spike bị gate bởi `SCORING_AI_SPIKE`). Nếu không có Postgres, ghi "không chạy được bước 5" và nêu lý do.

### Bước 6: Quality gate (chỉ báo cáo)

Chạy `ck:quality` ở chế độ audit trên phần chưa commit:

```text
/ck:quality --changed --save
```

Phạm vi là các file đổi trong đợt dọn. Đối chiếu với `docs/CODING_STANDARDS_API.md`, tập trung vào:

- Không còn constructor production chỉ để test, trừ constructor tương thích của record/DTO. Những constructor đó là API, cố ý giữ lại.
- Không bean nào có hai constructor mà thiếu `@Autowired`.
- Clock luôn được inject. `Clock.systemUTC()` chỉ được xuất hiện ở `ClockConfig` và factory tĩnh `ProviderGuard` (`scoring/internal/vendor/ProviderGuard.java`).
- Không còn import thừa: `grep` hoặc cảnh báo của compiler.
- `TestClocks` và `ItembankFixtures` nằm trong `src/test`, không rò vào `src/main`.

Kết quả ghi theo mức BLOCKER / HIGH / MEDIUM / LOW, không sửa code.

## 5. Điểm cần soi kỹ

Đây là những rủi ro đã biết, vì đợt dọn chưa được chạy test:

| # | Rủi ro | Dấu hiệu |
|---|---|---|
| R1 | Test truyền `null` làm Clock vào constructor chính, trong khi fallback null đã bị bỏ | `NullPointerException` tại `clock.instant()` / `Instant.now(clock)` |
| R2 | `ItembankFixtures` dựng `ItembankService` với `QuestionMediaReferenceValidator(null)` và không có `QuestionTypeService` / `AuditLogService` | NPE trong `ItembankServiceTest`, `ItembankOverviewQueriesTest`, `QuestionTypeServiceTest`, `ArchiveLifecyclePostgresIntegrationTest` |
| R3 | `TestClocks.fixed()` đóng băng thời gian lúc nạp lớp; test nào còn so với `Instant.now()` thật sẽ lệch | Assertion về hạn/expiry/"trước/sau" fail ngắt quãng |
| R4 | Script gỡ constructor viết lại sai thứ tự tham số ở chỗ gọi `new X(...)` trong test | Compile lỗi kiểu, hoặc mock bị truyền nhầm vị trí và test fail logic |
| R5 | `CloudinaryMediaService` được gộp còn một constructor `@Autowired` | Context Spring không khởi động được, hoặc `CloudinaryMediaServiceTest` fail |
| R6 | Xoá import làm mất import chỉ dùng trong javadoc `{@link}` | Cảnh báo javadoc (không chặn build), chỉ ghi LOW |

## 6. Báo cáo đầu ra

File báo cáo: `pte-doc/plans/reports/261026-quang-api-maintainability-cleanup-test-report.md`. Log thô và JSON để ở `pte-doc/plans/reports/assets/261026-quang-api-maintainability-cleanup-test-report/`.

Mẫu báo cáo:

```markdown
# Báo cáo test và quality gate: dọn maintainability (2026-10-26)

## Tóm tắt
| Bước | Kết quả | Con số |
|---|---|---|
| 1 Compile sạch | PASS/FAIL | n lỗi |
| 2 Ratchet | PASS/FAIL | |
| 3 Unit test | PASS/FAIL | run / fail / error / skipped |
| 4 Spring context | PASS/FAIL | |
| 5 Postgres | PASS/FAIL/NOT RUN | |
| 6 Quality | APPROVED/CHANGES REQUESTED | BLOCKER/HIGH/MEDIUM/LOW |

## Lỗi test
| Test | Lỗi (nguyên văn, dòng đầu) | Nghi do (R1–R6 / khác) | File:dòng production liên quan | Gợi ý sửa |

## Phát hiện quality
| Mức | File:dòng | Mô tả | Gợi ý |

## Không chạy được / giới hạn
```

Mỗi lỗi phải có: tên test, thông điệp lỗi nguyên văn, file và dòng, và nghi nguyên nhân thuộc rủi ro nào. Agent chỉ đề xuất cách sửa, không áp dụng.

## 7. Điều kiện hoàn tất

- Đủ 6 bước, mỗi bước PASS / FAIL / NOT RUN có lý do.
- Báo cáo nằm đúng đường dẫn ở mục 6.
- `git status` sau khi chạy khớp với lúc bắt đầu: không file code nào bị đổi. Chỉ thêm file trong `pte-doc/plans/reports/`.
