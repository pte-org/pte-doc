# Phase 05: Regression, migration rehearsal và bàn giao

Status: IN PROGRESS; full regression currently blocked by reproduced baseline failures. Stories: P1/P2. Depends on: phases01–04.

## Cook preflight

User confirmed tests=yes and quality=yes for all five phases. Standard (not TDD).
Use an isolated loopback PostgreSQL 17 container only; no production data or credentials.
Browser fixture authentication is explicitly mocked, not real authorization E2E.
Full-suite failures must be compared against a clean HEAD, reported and never hidden.
No commit, push or deployment is authorized.

## Tasks

- [x] Prepare isolated PostgreSQL test environment, migrations cleanDB + representative legacyDB. Không seed credentials thật hoặc xóa production.
- [ ] Execute transition/authorization/history matrix, not only happy paths. Correlate HTTP result, actor/audit và persisted state after commit.
- [ ] Race scenarios: delete/activate/archive Plan; issue/archive/entitlement-edit; delete/submit/publish/revision Question; reference creation/delete; membership/class-remove và class/program-remove guards nếu touched semantics.
- [x] Ít nhất10 repeated race runs với barrier/separate transactions; assertion về invariant, không chỉ check mộtrequestsuccess. Những race chưa được sửa ở enrollment không claim đã fix vì chỉ đổi text.
- [x] Fault injection rollback sau guard/audit để kiểm tra tombstone không commit nửa vời; idempotent repeat-delete no duplicate audit.
- [x] Read pinned exam/snapshot và old billing receipt; compare immutable content/expiry/cap với beforefixture.
- [ ] Browser thật admin + tenant, role-specific route checks; mocked failures dùng riêng để chứng minh UI error states, không gọi mocked session là E2E authorization proof.
- [x] Validate expand migration compatibility và client cũ: stale archiveDRAFT409 có clearmessage, newserver+oldUI không deleteexistinghistory. RollbackUI giữ schema/tombstone/audit, không undelete đại trà.
- [x] Review diff/source theo code-review; ghi failed gates kể cả unrelated dirtyworktree. Không mark phase done khi critical/high/current-change findings unresolved.
- [x] Write test-report, checklist, release-notes, rollback instructions và remaininglimitations trong thư mục plan; chờ user quyết định commit/push/deploy.

## Backend commands dự kiến

```powershell
# cwd: pte-api; tên suite mới bổ sung theo code thực tế
.\mvnw.cmd -pl app '-Dtest=PlanServiceTest,LicenseCodeServiceTest,ItembankServiceTest,QuestionControllerSecurityTest,QuestionRepositoryTest,ProgramServiceTest,ClassServiceTest' test
.\mvnw.cmd -pl app -DskipTests compile
.\mvnw.cmd -pl app test
```

Tổng regression còn cần suites integration mới và assessment/module tests. Không dùng targeted command trên như proof race nếu suite chỉ Mockito. Nếu Docker/PostgreSQL unavailable, báo integration gate pending và không claim complete.

## Design Constraints

- Không rollout production/mutate/delete thực khi chưa được phép; no secrets in reports.
- DBread after commit ở transaction khác; transactionaltest rollback-only không chứng minh durability.
- Không cập nhật archived legacy/deleted legacy bulk. PolicyblockingUNKNOWN phải ghi limitation rõ để admin không tưởng dữ liệu mất.
- Restore/trash và snapshot license ngoài scope; không dùng rollback để đảo guard nghiệp vụ.

## Required evidence

| Gate | Evidence |
|---|---|
| Contract | DELETE status/body, role/scoping, errorcodes, parser, capabilities |
| Persistence | Before/after rows và audit an toàn, migration classification |
| Concurrency | Requests/interleavings + postcommit invariants |
| History | Old exam/billing artifacts vẫn resolve đúng |
| UI | Actions bystate, pending/conflict/error, Remove text |
| Regression | Fresh compile/test/lint/build output, failures ghi rõ |

## Exit Criteria

Mọi spec criterion có receipt hoặc limitation explicit; không có unresolved data-integrity finding. Bàn giao uncommitted và chưa deployed nếu user chưa cho phép.

## Quality and Testing State

- User test choice: yes, all phases.
- Quality: APPROVED for reviewed changes, inline audit; [report](quality/phase-05-regression-and-handoff-quality-report.json), [receipt](quality/phase-05-regression-and-handoff-receipt.json). This is not release approval.
- Testing: scoped unit/HTTP/PostgreSQL/browser checks passed; full regression FAILED on 11 baseline failures reproduced on clean HEAD. See [test report](test-report.md).
- Live authenticated browser/API E2E remains unverified. Publish/revision/reference-creation races are not claimed as exercised; tested Question races are delete/submit plus deterministic stale write. Enrollment races were not changed or fixed.
- Phase remains incomplete; do not silently waive the full-suite gate or fix unrelated suites without separate scope approval.
