# Phase 08: corpus học thuật, security, concurrency và live synthetic smoke

Status: planned. Dependencies: 01..07 và decisions cho released features. Stories: US-01..11 được xác nhận in-scope. Requirements: PR-01..15.

## Work packages và bằng chứng cần thu

1. Academic Manager duyệt corpus theo task/rubric revision: đề xuất tối thiểu 8 bài chuẩn cho mỗi scored task, phân bố tốt/trung bình/yếu/empty/invalid/edge và có reference/evidence labels. Lưu source/provenance/approval, không dùng bài Student thật khi chưa có data handling approval. Criterion coverage và content broken cases quan trọng hơn chỉ đếm bài.
2. Objective gold acceptance: mọi policy/normalization/penalty/partial cases khớp expected; phân biệt legitimate empty/incorrect answer và malformed/missing source reference. No answer-key leaks trong API/UI/HTML/storage trước submit. External model không được thay expected correctness.
3. Gemini evaluation tách ba phép kiểm: persisted replay stable; schema/evidence valid; pedagogical/factual quality do học thuật kiểm. 3 independent calls cho approved subset để đo variability, không gọi cached result ba lần rồi kết luận model consistent. Critical contradiction với verified answer = release blocker; evidence refs 100% hợp lệ. Usefulness threshold và assessor sign-off phải chốt trước chạy, không tự sửa metric sau thấy kết quả.
4. D06 đã chốt Writing/Speaking rubric feedback trước, numeric AI sau kiểm định. Initial release nghiệm thu qualitative/limited feedback, không bị block bởi thiếu numeric AI. Capability numeric sau đó cần gold rated corpus, agreement/error tolerance, bias/task/level segmentation, missing-audio limits và release rule do học thuật duyệt. Không dùng “rubric có weight” làm proof calibration; chưa đạt thì không bật numeric score.
5. Security matrix: owner/context isolation mọi route/media/job; OTP expired/reused/throttled/enumeration; entitlement POST và historical GET; draft/rejected rubric; input prompt injection; forged evidence/criterion; unsupported audio; expired signed read; account switch/local storage cleanup; secrets/client bundle/log redaction. Validate SSRF/file types/size cho provider media path.
6. Race/fault integration: 20 concurrent POST cùng logical identity, different headers; different answers after submit; stale worker fence; double message; DB commit→broker failure; worker crash before/after provider; reservation races; model disabled/revoked version; retry cap. Confirm recovery ≤2 configured reconciliation cycles không Host revisit. Xem DB/metrics evidence, không chỉ HTTP success.
7. Delivery regression: từng task in-scope có content/media fixtures và UI→API→storage→review path. Migration/rolling backward compatibility và exam selector regression mandatory. Verify saved answers/recordings qua actual supported browser/OS; mocks không thay device permission/network recovery.
8. Live smoke chỉ sau approved feature/data/budget, dùng synthetic answer/audio, backend config secret hiện có; kiểm tra model actual version, quota/auth/schema/timeout và metrics. Không gửi bài thật hoặc in `.env`. Planning hiện tại chưa thực hiện live call và chưa chứng minh key hợp lệ.

## Proposed execution commands và boundary

Sau cook check choices và reading gate, dùng scripts hiện có, recheck package khi code thay đổi:

- `pte-api`: `.\mvnw.cmd -pl app -DskipTests compile`; `.\mvnw.cmd -pl app test` khi test execution được chọn.
- `pte-practice`: `npm run lint`, `npm run typecheck`, `npm run test:unit`, `npm run build`; tests chỉ sau choice, required checks theo standards.
- `pte-web`: `pnpm --filter vendor-web lint`, `pnpm --filter vendor-web typecheck`, `pnpm --filter vendor-web test`, `pnpm --filter vendor-web build`; thêm tenant-web nếu shared client/contracts ảnh hưởng.
- PostgreSQL integration suite có `@EnabledIfSystemProperty` dùng `lifecycle.test.db.url`; phải cấp **throwaway scratch DB** được suite cho phép, kiểm strict allowed scratch URLs của migration test. Không dùng DB hiện có/production, không suy default skipped tests là integration pass. Ghi actual enabled/skipped counts, exact suite và database isolation mà không log credentials.

## Proposed files / evidence

Owned tests bên `pte-api/app/src/test`, `pte-practice/features/**` và project-supported browser harness chỉ sau user/cook choice; corpus fixtures không chứa sensitive data; migration/config checks theo standards. Canonical review report `pte-doc/plans/reports/YYMMDD-quang-pte-practice-release-verification.md`; screenshots/JSON sanitized dưới matching assets directory, lưu command/commit/config version/expected/actual và boundaries.

## Design Constraints

Không biến test proposal thành kết quả PASS. Không hứa production-ready từ local compile, fake provider hoặc cached reads. Giáo viên/academic approval không được giả lập bằng agent tự ghi “approved”. Bài không assessable do source issue không bị Student zero.

## Failure paths và remediation

Sai factual/evidence/security → block release affected feature; giữ submission/standard result khả dụng. Model drift → pause new generation, evaluate version mới, giữ stored historical reads. Rubric lỗi → retire future selection, version correction, explicit regeneration policy; không rewrite history. Corpus thiếu → task chưa ready, không giảm acceptance ngầm.

## Exit criteria

Actual task matrix có evidence links cho every in-scope row; objective/authorization/no-leak invariants đạt; concurrency/recovery evidence; academic corpus sign-off; live smoke thành công nếu AI enabled. Mọi unexecuted check, environment limitation hoặc known defect ghi rõ owner/risk/gate. Numeric AI chỉ enabled khi calibration sign-off.

## Quality and Testing State

Quality: not evaluated. Testing: not started. TDD và execution chưa được chọn trong planning. `ck:cook` xác nhận checks; nếu user không chọn chạy coverage cần cho release, gate vẫn pending, không đánh dấu achieved. Mandatory standards checks luôn áp dụng khi code.
