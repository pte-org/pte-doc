# Phase 4: Sóng 1 — Class A (strict)

## Requirements

Bật RLS trên 23 bảng Class A (15 đã có sẵn cột + 2 chuẩn hoá + 6 denormalize), áp policy: `tenant_id = NULLIF(current_setting('app.current_tenant', true), '')::uuid`. **Một policy per bảng với cả USING và WITH CHECK.** Proof-of-activation test bắt buộc.

Maps to: **[ADR-003](../../architecture/ADR-003-tenant-isolation-and-infrastructure.md) § RLS Policies**

## Design Constraints

- **23 bảng Class A (strict `tenant_id UUID NOT NULL`)**: 15 đã có cột từ P1+P2 (exam_attempts, pinned_exam_snapshots, exam_sessions, enrollments, proctor_assignments, scoring_answers, proctor_sessions, violation_events, media_objects, attempt_reports, audit_logs, notification_logs, class_memberships, lecturer_assignments, program_coordinator_assignments, organizations, quota_transactions), 6 denormalize ở P2 (pinned_items, attempt_answers, attempt_heartbeats, session_compositions, programs, student_classes)
- **Một CREATE POLICY per bảng với BOTH USING và WITH CHECK.** Postgres spec: multiple permissive policies OR nhau. Nếu split thành hai:
  ```sql
  CREATE POLICY read_policy ON table USING (tenant_id = X);
  CREATE POLICY write_policy ON table WITH CHECK (tenant_id = X);
  ```
  Postgres nội bộ: `write_policy` không có USING → USING mặc định = `true`. So khi check read: `(tenant_id = X) OR (true)` = always true → mở cửa. **Luôn gộp USING + WITH CHECK vào một policy**
- **`current_setting('app.current_tenant', true)::uuid` với NULLIF**: 2-arg form, bind parameter. Ngoài transaction → NULL → `NULLIF(NULL, '')` → `NULL` → `NULL = UUID` → false → 0 rows, không crash
- **Proof-of-activation bắt buộc** — RLS im lặng khi deny. Test phải chứng minh (a) policy tồn tại (`pg_policies`), (b) rows thực sự filter (row count assert)
- **App-layer `WHERE tenant_id`  STAY** — RLS là lưới, không thay thế
- **`ENABLE RLS` không `FORCE`** — owner bypass tự nhiên
- **`@SpringBootTest` + Testcontainers** không `@DataJpaTest` (nó wrap DataSource, kill `RlsJpaTransactionManager`)

## Steps

1. Migration `V15__rls_class_a.sql` — enable RLS + create policies trên 23 bảng:
   ```sql
   -- 15 tables đã có sẵn column
   ALTER TABLE exam_attempts ENABLE ROW LEVEL SECURITY;
   ALTER TABLE pinned_exam_snapshots ENABLE ROW LEVEL SECURITY;
   ALTER TABLE exam_sessions ENABLE ROW LEVEL SECURITY;
   ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
   ALTER TABLE proctor_assignments ENABLE ROW LEVEL SECURITY;
   ALTER TABLE scoring_answers ENABLE ROW LEVEL SECURITY;
   ALTER TABLE proctor_sessions ENABLE ROW LEVEL SECURITY;
   ALTER TABLE violation_events ENABLE ROW LEVEL SECURITY;
   ALTER TABLE media_objects ENABLE ROW LEVEL SECURITY;
   ALTER TABLE attempt_reports ENABLE ROW LEVEL SECURITY;
   ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
   ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;
   ALTER TABLE class_memberships ENABLE ROW LEVEL SECURITY;
   ALTER TABLE lecturer_assignments ENABLE ROW LEVEL SECURITY;
   ALTER TABLE program_coordinator_assignments ENABLE ROW LEVEL SECURITY;
   
   -- 2 tables normalized BIGINT→UUID
   ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
   ALTER TABLE quota_transactions ENABLE ROW LEVEL SECURITY;
   
   -- 6 tables denormalized in P2
   ALTER TABLE pinned_items ENABLE ROW LEVEL SECURITY;
   ALTER TABLE attempt_answers ENABLE ROW LEVEL SECURITY;
   ALTER TABLE attempt_heartbeats ENABLE ROW LEVEL SECURITY;
   ALTER TABLE session_compositions ENABLE ROW LEVEL SECURITY;
   ALTER TABLE programs ENABLE ROW LEVEL SECURITY;
   ALTER TABLE student_classes ENABLE ROW LEVEL SECURITY;
   
   -- ONE policy per table (USING + WITH CHECK together)
   -- Helper: all Class A use the same pattern
   CREATE POLICY class_a_restrict ON exam_attempts
     FOR ALL USING (tenant_id = NULLIF(current_setting('app.current_tenant', true), '')::uuid)
     WITH CHECK (tenant_id = NULLIF(current_setting('app.current_tenant', true), '')::uuid);
   
   CREATE POLICY class_a_restrict ON pinned_exam_snapshots
     FOR ALL USING (tenant_id = NULLIF(current_setting('app.current_tenant', true), '')::uuid)
     WITH CHECK (tenant_id = NULLIF(current_setting('app.current_tenant', true), '')::uuid);
   
   -- ... (repeat for all 23 tables with same pattern)
   ```

2. Verify policies in catalog:
   ```sql
   SELECT tablename, COUNT(*) FROM pg_policies 
   WHERE schemaname = 'public' AND policyname = 'class_a_restrict'
   GROUP BY tablename;
   -- Expected: 23 rows
   ```

3. Integration test (proof-of-activation):
   ```java
   @SpringBootTest
   @Testcontainers
   class RlsClassAPolicyTest {
       @Container
       static PostgreSQLContainer<?> postgres = 
           new PostgreSQLContainer<>(DockerImageName.parse("postgres:17"));
       
       @Autowired
       private ExamSessionRepository sessionRepository;
       
       @Autowired
       private TenantRepository tenantRepository;
       
       @Test
       @Transactional
       void testClassAPolicyEnforcesIsolation() {
           Tenant tenantA = tenantRepository.save(new Tenant("A"));
           Tenant tenantB = tenantRepository.save(new Tenant("B"));
           
           ExamSession sessionA = sessionRepository.save(
               new ExamSession(tenantA.id(), "exam-a"));
           ExamSession sessionB = sessionRepository.save(
               new ExamSession(tenantB.id(), "exam-b"));
           
           // Query as tenant-B → should see only sessionB
           SecurityContextTestHelper.mockSecurityContext(
               new CurrentUser(UUID.randomUUID(), tenantB.id(), 
                   List.of("HOST_ADMIN")));
           
           try {
               var sessions = sessionRepository.findAll();
               assertThat(sessions).hasSize(1)
                   .extracting(ExamSession::id)
                   .contains(sessionB.id());
           } finally {
               SecurityContextTestHelper.clearSecurityContext();
           }
       }
       
       @Test
       void testAllClassAPoliciesExist() throws SQLException {
           try (Connection conn = DriverManager.getConnection(
               postgres.getJdbcUrl(), "postgres", "test")) {
               
               var rs = conn.createStatement().executeQuery(
                   "SELECT COUNT(*) FROM pg_policies " +
                   "WHERE schemaname = 'public' AND policyname = 'class_a_restrict'");
               
               rs.next();
               assertThat(rs.getInt(1)).isEqualTo(23);
           }
       }
       
       @Test
       void testFailClosedWhenGucNotSet() throws SQLException {
           Tenant tenantA = tenantRepository.save(new Tenant("A"));
           sessionRepository.save(new ExamSession(tenantA.id(), "exam"));
           
           // Query outside transaction → GUC not set → NULL
           Connection conn = DriverManager.getConnection(
               postgres.getJdbcUrl(), "pte_app", "pte_app_password");
           try (var rs = conn.createStatement().executeQuery(
               "SELECT COUNT(*) FROM exam_sessions")) {
               rs.next();
               assertThat(rs.getLong(1)).isZero();
           }
       }
       
       @Test
       @Transactional
       void testWithCheckPreventsWrongTenant() {
           Tenant tenantA = tenantRepository.save(new Tenant("A"));
           Tenant tenantB = tenantRepository.save(new Tenant("B"));
           
           SecurityContextTestHelper.mockSecurityContext(
               new CurrentUser(UUID.randomUUID(), tenantB.id(), 
                   List.of("HOST_ADMIN")));
           
           try {
               var session = new ExamSession(tenantA.id(), "exam");
               assertThatThrownBy(() -> sessionRepository.save(session))
                   .isInstanceOf(DataIntegrityViolationException.class);
           } finally {
               SecurityContextTestHelper.clearSecurityContext();
           }
       }
   }
   ```

4. Code scan: every `repository.findAll()` on Class A tables, verify it's `@Transactional` (GUC set), or add `@PolicyBoundary` + Javadoc.

## Success Criteria

- 23 bảng RLS enabled
- Mỗi bảng có một CREATE POLICY (USING + WITH CHECK together)
- Policy dùng `NULLIF(..., '')::uuid`
- Proof-of-activation: wrong tenant GUC → 0 rows (no error)
- Policy catalog: `pg_policies` shows 23 policies
- Fail-closed test: GUC not set → 0 rows
- WITH CHECK rejects wrong tenant_id
- Flyway V15 OK
- App boots, login OK

## Quality and Testing State

- Quality gate: chưa chạy
- Testing: chưa bắt đầu

## Session Notes

_(trống)_
