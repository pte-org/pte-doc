# Plan: Phân công Examiner và Host duyệt nguồn điểm

**Spec:** [spec.md](spec.md)  
**Mode:** Hard · **Test:** default (chưa bật `--tdd`)  
**Phạm vi:** P1 assignment, Examiner scoring, Host source selection/approval, Student report; P3 cấu hình tái sử dụng bị hoãn.  
**Trạng thái:** Đang triển khai — Phase 01 implementation/quality đã hoàn tất theo bằng chứng hiện có; reviewer follow-up độc lập sau remediation V59 còn pending. Người dùng xác nhận hoàn tất Phase 02 sau khi acceptance checks pass và quality APPROVED; Phase 03 đang được triển khai. Unit tests và quality gate được xác nhận cho từng Phase 03–05. Publication cutoff được chốt là chỉ publish sau khi session CLOSED.

---

## Scope challenge

- **Exists?** Một phần: Host đã xem câu trả lời và lưu `teacherScore` độc lập. Chưa có Examiner assignment/ownership, điểm Examiner có danh tính, chọn nguồn điểm, readiness gate, hoặc report snapshot ổn định.
- **Minimum:** Giao nguyên attempt trong session hiện tại theo manual Program/Class mapping hoặc random pooled cân bằng; Examiner chấm blind 0–100 trên từng câu AI-eligible; Host chọn AI/Examiner theo all/section/task type rồi duyệt và publish report bất biến.
- **Complexity:** **Hard** — nhiều module BE/FE, kiểm soát tenant/assignment/media, allocation idempotency, provenance AI, audit, aggregation và publication consistency.
- **Spec quality:** **PASS** — P1/P3 stories, tiêu chí đo được và không còn `[NEEDS CLARIFICATION]`.
- **Test strategy:** mặc định chưa ép TDD trong từng phase; do rủi ro domain/security, handoff khuyến nghị `/ck:cook --hard --tdd`.

## Phạm vi và nguyên tắc bất biến

1. Mọi assignment, batch và score decision gắn với đúng một session; không lưu mapping để tự áp dụng sang session khác.
2. Đơn vị phân công là một submitted `ExamAttempt`; mọi answer AI_SPEECH/AI_TEXT của attempt đi cùng một Examiner. Deduplicate theo attempt ID khi scope giao nhau.
3. Pool eligibility được suy ra từ scoring method trong ScoreTemplate đang pin trên answer/attempt; không lập danh sách task type hardcode. Objective và UNSCORED không tham gia Examiner queue.
4. Random là shuffle trên pool attempt hợp nhất của mọi Program/Class đã chọn, chia số lượng lệch tối đa 1. Preview phải gắn với snapshot/token đã lưu; confirm không bốc thăm lại.
5. Assignment đã commit bất biến và retry idempotent. Attempt nộp sau chỉ vào supplemental batch cho attempt chưa được giao.
6. Examiner phải active, đúng role `EXAMINER`, cùng tenant và sở hữu assignment; xác minh ở API cho list/detail/audio/submit, không dựa vào FE.
7. Examiner API/DTO là blind: không trả AI score, score source đang chọn hoặc dữ liệu Host-only; Examiner score độc lập với `rawScore` và `teacherScore`.
8. Provider stub/placeholder không phải nguồn publishable. Provenance phải được ghi tại lúc provider tạo score; không suy đoán từ cấu hình hiện tại hoặc do client truyền lên.
9. Source selection là state theo answer, thao tác all/section/task type áp dụng lên tập hiện hữu và có audit. Nguồn không xóa hai score gốc.
10. Publish preflight toàn bộ report cohort: không publish một phần khi câu AI-eligible thiếu selected publishable score. Student chỉ đọc snapshot đã publish; dữ liệu sau publish không làm report đổi âm thầm.
11. Dùng public module API/facade, không truy cập repository/package `internal` xuyên module và không thêm FK xuyên bounded context nếu kiến trúc hiện tại tránh kiểu liên kết đó.
12. Chỉ cho phép publish report sau khi session ở trạng thái CLOSED; không publish report cuối khi session còn nhận attempt. Cohort/aggregation của report được xác định từ dữ liệu hợp lệ tại cutoff đóng session.

## Kiến trúc và ownership đề xuất

| Năng lực | Owner đề xuất | Ranh giới |
|---|---|---|
| Candidate AI work, assignment, Examiner score, score provenance, selected source/audit | `scoring` | `ScoringAnswer` là canonical work state; assignment key `(session, attempt)`; score riêng theo answer. Expose public facade cho caller ngoài module. |
| Session scope, session state, selected Class IDs | `session` | Scoring lấy scope qua public API; không đọc `SessionClassAssignmentRepository` trực tiếp. |
| Program/Class membership và roster | `enrollment` | Resolve membership qua public tenant-scoped API; không truy vấn repository nội bộ. |
| Examiner identity/role/status | `identity` | Mở public query/facade dựa trên `ExamStaffQueryService`; backend kiểm tra active + tenant + role ở cả preview/commit. |
| Report readiness, final aggregation và Student publication | `reporting` | Gọi scoring facade để preflight/lấy score đã chọn; snapshot report và publication barrier do Reporting sở hữu. |
| Host per-session controls | `tenant-web` exam detail | Gắn assignment/review vào `SessionDetailView`; giữ nguyên Host-only access. |
| Examiner work queue | `tenant-web` Examiner area | Route/layout/navigation riêng cho role EXAMINER; không mở Host navigation/API cho Examiner. |

### Mô hình dữ liệu mục tiêu (logical; tên/bố cục chốt khi cook đọc migration hiện hành)

- **Assignment batch:** session/tenant, creator, mode, selected scope, random seed/snapshot, state, preview expiry/version, counts, timestamps. Persist preview intent để confirm dùng đúng phân bổ đã xem.
- **Attempt assignment:** session/tenant/attempt/examiner, batch, assignment actor/time; unique `(session, attempt)` và không có nhiều examiner active trên một attempt.
- **Examiner score:** answer/attempt/session/tenant, examiner, integer 0–100, submittedAt/status; unique answer trong MVP vì sửa/reopen nằm ngoài scope.
- **AI provenance:** provider category (real/stub), provider/model/version và thời điểm tạo cùng AI result. Legacy score thiếu provenance mặc định không publishable.
- **Current score decision + append-only audit:** source AI/EXAMINER theo answer và audit thao tác/actor/time/scope/count. Không dùng `teacherScore` cho Examiner.
- **Publication snapshot:** phiên bản/cutoff/cohort, pinned template identity, answer-level selected inputs hoặc đủ snapshot dữ liệu để tái tạo, aggregate theo section/overall, approver/publishedAt. Chặn sửa nguồn đã publish; Student đọc snapshot.

**Ranh giới scope đã làm rõ:** spec yêu cầu một attempt có thể khớp nhiều scope Class/Program được chọn; không giả định một Student đồng thời thuộc nhiều Class. Research phát hiện `ClassMembership` hiện có unique constraint trên `student_public_id`, nên không thay đổi enrollment membership trong feature này. Khi các scope đã chọn giao nhau (ví dụ Program và Class), union/deduplicate theo attempt; nếu manual mapping gán cùng attempt cho Examiner khác nhau thì trả conflict và không commit.

## Thứ tự triển khai và dependency

```text
P01 scoring contracts/provenance
  └─ P02 host assignment + durable preview
       └─ P03 Examiner blind queue/scoring
            └─ P04 Host source selection/review
                 └─ P05 readiness, aggregation, immutable publish snapshot
```

P01 dựng public contracts/migration trước; P02/P03 cùng dùng assignment owner check; P04 cần cả hai nguồn score; P05 tiêu thụ source decision và đóng vòng report. Không gộp P04/P05: source selection và report publication có invariant/transaction riêng, cần quality gate độc lập.

## Bản đồ phase

| Phase | Stories | Kết quả có thể kiểm chứng |
|---|---|---|
| [01 — Scoring foundation](phase-01-scoring-foundation.md) | P1 Examiner, Host source review; FR-02–04, 09–18 nền tảng | **Complete (2026-09-23):** quality APPROVED; 126 Maven tests pass; V1–V59 validated on disposable empty/legacy PostgreSQL databases with relational-constraint smoke checks. Reviewer follow-up after V59 remediation remains pending. |
| [02 — Host assignment](phase-02-host-assignment.md) | P1 manual/random; FR-01–08, 18 | **Completed (2026-09-23; hard-mode confirmation received).** Quality APPROVED; 169 prior backend regression tests + 2 H2 database integration tests passed; concurrent confirm persisted one assignment under the batch-row lock (session-row lock mocked), 40-attempt/2-Examiner service+repository p95 was 129 ms across 20 runs, and Host browser smoke passed. HTTP/PostgreSQL performance was not measured; no assignment was committed to the seeded local session. |
| [03 — Examiner queue](phase-03-examiner-workflow.md) | P1 Examiner; FR-03, 04, 09–11, 18 | **In progress (2026-09-23).** Examiner private list/detail/audio and blind 0–100 submission, with server-enforced ownership. Unit tests and quality gate: yes. |
| [04 — Host score review](phase-04-host-score-review.md) | P1 Host chọn nguồn/duyệt; FR-11–15, 18 | Review hai nguồn và trạng thái; preview/apply all/section/task type; audit/availability đúng subset. |
| [05 — Reporting publication](phase-05-report-publication.md) | P1 Host approval + Student report; FR-12, 15–18 | Readiness gate, selected-score aggregation + pinned weights, atomic visibility/snapshot, Student result không drift. |

P3 tái sử dụng mapping giữa session được giữ ngoài MVP; không tạo bảng/template config dùng chung trong các phase này.

## Test và verification order

1. **Trước mỗi phase:** đọc migration/entity/service/DTO cụ thể, kiểm tra working tree và hợp đồng FE/BE hiện hành; giữ nguyên thay đổi có sẵn. Chốt API/schema theo module boundary, không suy diễn từ plan.
2. **Theo phase:** unit test domain/service và controller authorization; integration test persistence/transaction/migration; FE typecheck/build và component/route checks tương ứng. Dùng fixture provider real/stub tách biệt.
3. **Security:** negative tests cho tenant khác, Examiner inactive/wrong role, attempt không assign, answer ID đoán được, media URL; xác minh cả response/error không làm lộ nội dung/AI score.
4. **Concurrency/integrity:** preview-confirm race, duplicate/retry, overlapping scopes, parallel score submit/source update/publish; kiểm tra unique constraint + transaction lock/idempotency.
5. **End-to-end:** Host preview→confirm assignment→Examiner chấm toàn bộ eligible answers→Host chọn nguồn→approval/publish→Student chỉ đọc report snapshot.
6. **Performance:** integration benchmark preview/commit 40 attempts/2 examiners đạt p95 ≤ 2 giây local; ghi rõ môi trường/dataset. Không tính media/AI latency.
7. Sau mỗi phase chạy test mục tiêu và regression phù hợp; trước handoff chạy backend suite/build, tenant-web checks, migration validation và `ck:quality --gate`. Đây là kế hoạch kiểm chứng, chưa có kết quả chạy.

## Acceptance mapping

| Spec success criterion | Phase |
|---|---|
| Random pooled 40 attempt/2 Examiner đúng 20/20; N/M lệch ≤1; retry không đổi | 02 |
| Scope đúng session; dedupe; manual conflict bị chặn; supplemental chỉ thêm attempt mới | 02 |
| Examiner list/detail/media/submit chỉ trên assignment cùng tenant | 03 |
| Examiner score truy nguyên được; không ghi đè AI/objective/Host score | 01, 03 |
| Source all/section/task type áp dụng chính xác, action hẹp ghi đè subset; scores gốc giữ nguyên | 04 |
| Stub score bị loại; thiếu source/score chặn approval và publish toàn cohort | 01, 04, 05 |
| Aggregate lấy selected score + pinned weights; objective semantics giữ nguyên | 05 |
| Report student ẩn trước publish và không đổi sau publish | 05 |

## Rủi ro và quyết định cần xác nhận

| Rủi ro | Giảm thiểu/điểm quyết định |
|---|---|
| Selected Program/Class scopes có thể giao nhau dù membership hiện chỉ cho một Class/student | Resolve effective scope qua Enrollment API, union/dedupe theo attempt; không thay membership schema; conflict khi manual mappings khác Examiner. |
| Membership/roster đổi giữa preview và confirm | Lưu snapshot batch, revalidate tenant/session/status/eligibility lúc confirm; assignment đã commit không phụ thuộc roster tương lai. Nêu rõ cách xử lý attempt rời audience trong khoảng preview. |
| Publish khi session còn mở có thể bỏ lỡ attempt nộp sau cutoff | **Decision A (2026-09-23):** chỉ publish report sau khi session CLOSED; không snapshot/publish final report khi session còn mở. |
| Stub/legacy AI rawScore không có provenance | Chặn nguồn AI mặc định; không backfill provenance từ config hiện tại. Xác định quy trình local seed/re-score để kiểm thử AI publication. |
| Session-level publish lớn khó làm trong một DB transaction | Dùng publication state/barrier; snapshot có thể staging nhưng không Student-visible cho tới khi toàn bộ cohort sẵn sàng. Retry phải idempotent. |
| Hai examiner score/source/publish chạy đồng thời | Row/version lock hoặc optimistic version và unique keys; các mutation sau published bị reject; test race. |
| Một attempt khớp nhiều scope Program/Class được chọn | Resolve bằng API enrollment; tập hợp/union và dedupe theo attempt; manual mapping nhiều Examiner trên cùng attempt là conflict, không last-write-wins. |
| FE ẩn field nhưng API trả score nhạy cảm | DTO tách riêng và test serialized payload; media presign xác thực assignment trước khi cấp URL. |
| Thay đổi session/identity module gây dependency cycle | Expose minimal public facade; kiểm tra modulith graph; nếu cycle phát sinh thì điều chỉnh owner qua facade/event, không import `internal`. |

## Trạng thái kiểm thử và quality

| Phase | Quality | Testing |
|---|---|---|
| 01 | APPROVED | passed — 126 Maven tests; V1–V59 empty/legacy migration and constraints smoke checks |
| 02 | APPROVED (inline fallback; zero open blocking findings) | passed — 169 backend regression tests + 2 H2 service/repository integration tests; 40/2 p95 129 ms; Host browser smoke passed. HTTP/PostgreSQL p95 not measured. |
| 03 | not evaluated | not started |
| 04 | not evaluated | not started |
| 05 | not evaluated | not started |

Đây là trạng thái kế hoạch. Không có source code hay kiểm thử được chạy trong bước lập plan.

## Handoff

Publication cutoff đã được xác nhận là chỉ publish sau khi session CLOSED. Các phase còn lại đã được chọn unit tests=yes và quality=yes; tiếp tục theo hard-mode bằng:

```text
/ck:cook --hard pte-doc/projects/plans/quang-examiner-assignment-score-selection/plan.md
```

Không bật `--tdd`; các checkpoint đã lưu `unit tests=yes` và `ck:quality=yes` cho Phase 03–05. Hard mode vẫn cần xác nhận người dùng sau gate từng phase, trước khi đánh dấu phase đó hoàn tất.
