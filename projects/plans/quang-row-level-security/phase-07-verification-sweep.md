# Phase 7: Kiểm thẩm — Coverage & enforcement

## Requirements

Catalog-driven test + per-table syntax check: mọi bảng có `tenant_id` column (33 bảng) phải có RLS enabled + ≥1 policy. Duy nhất `flyway_schema_history` exempt (Flyway meta, không tenant scope). Tỷ lệ test coverage ≥80%.

Maps to: **[ADR-003](../../architecture/ADR-003-tenant-isolation-and-infrastructure.md) § Verification**

## Design Constraints

- **Catalog-driven test, không hardcode list.** Test queries `information_schema.columns` cho mọi bảng chứa `tenant_id`, kiểm `pg_class.relrowsecurity = true` + `pg_policies` có policy. Nếu bảng mới có `tenant_id` → test fail → build fail ngay. Hardcode list rots khi commercialization thêm bảng
- **Whitelist: `flyway_schema_history` duy nhất.** Không có `tenant_id` column, Flyway meta. Tất cả bảng khác có `tenant_id` → **bắt buộc** có RLS
- **Tenants table:** Có `public_id UUID NOT NULL`, được dùng làm tenant identifier. Class A policy: `public_id = current_tenant()`. Tenant chỉ thấy chính mình, platform thấy tất
- **Coverage 80%** — security-related tests (P1 role, P3 GUC, P4/P5 proof-of-activation, P6 worker, P7 catalog). Không đếm helper/reflection
- **Bảng tạo V21+** — phải có policy cùng migration. Split (V21 CREATE, V22 POLICY) → test fail vì V21 thấy `tenant_id` mà RLS chưa on

- **Đếm hàm `SECURITY DEFINER` và so với danh sách cho phép.** Mỗi hàm loại này chạy bằng quyền owner (superuser) nên **RLS không áp** — nó là một lỗ khoét xuyên qua toàn bộ cô lập tenant. Hiện có đúng **2**, cả hai cho đường tiền-xác thực ở P5 (`auth_lookup_by_username`, `auth_lookup_refresh_token`). Không có test này thì hàm thứ ba mọc ra sáu tháng sau sẽ không ai để ý, và RLS rỗng dần mà build vẫn xanh.

- **Regex kiểm nội dung policy chỉ chứng minh policy *nhắc đến* `tenant_id`, không chứng minh *logic đúng*.** Một policy viết `tenant_id != ...` vẫn khớp regex và vẫn qua test. Ghi nhận giới hạn này và **không dựa vào nó** — bằng chứng thật nằm ở test hành vi của P4/P5 (set GUC sai → đếm 0 dòng).

- **CI không có Docker thì Testcontainers không chạy.** Khi đó toàn bộ test bảo mật của plan này im lặng không chạy mà build vẫn xanh — tức là tệ hơn không có test, vì nó tạo cảm giác an toàn giả. Cấu hình để trường hợp đó **fail build**, không `@Disabled`, không skip im lặng.

## Steps

1. Test class `RlsArchitectureTest`:
   ```java
   @SpringBootTest
   @Testcontainers
   class RlsArchitectureTest {
       @Container
       static PostgreSQLContainer<?> postgres = 
           new PostgreSQLContainer<>(DockerImageName.parse("postgres:17"));
       
       @Autowired
       private DataSource dataSource;
       
       // Only flyway_schema_history is exempt (Flyway meta, no tenant_id)
       private static final Set<String> RLS_EXEMPT = Set.of(
           "flyway_schema_history"
       );

       // SECURITY DEFINER bypasses RLS entirely. Every entry here is a
       // deliberate hole. Adding one is a security decision, not a refactor.
       private static final Set<String> ALLOWED_SECURITY_DEFINER = Set.of(
           "auth_lookup_by_username",      // P5 — pre-auth credential lookup
           "auth_lookup_refresh_token"     // P5 — pre-auth token lookup
       );
   ```

   ```java
       @Test
       void noUndeclaredSecurityDefinerFunctions() throws SQLException {
           var found = queryForStrings("""
               SELECT p.proname
               FROM pg_proc p
               JOIN pg_namespace n ON n.oid = p.pronamespace
               WHERE n.nspname = 'public' AND p.prosecdef = true
               """);

           assertThat(found)
               .as("""
                   Hàm SECURITY DEFINER chạy bằng quyền owner nên RLS KHÔNG áp.
                   Mỗi hàm là một lỗ khoét xuyên cô lập tenant. Nếu test này đỏ:
                   đừng thêm tên vào allowlist cho xanh — hãy hỏi vì sao hàm đó
                   cần bỏ qua RLS, và liệu có cách nào không cần.
                   """)
               .containsExactlyInAnyOrderElementsOf(ALLOWED_SECURITY_DEFINER);
       }

       @Test
       void securityDefinerFunctionsPinSearchPath() throws SQLException {
           // SECURITY DEFINER không cố định search_path = lỗ leo thang quyền
           // kinh điển: kẻ tấn công tạo schema riêng che khuất bảng thật.
           var unpinned = queryForStrings("""
               SELECT p.proname
               FROM pg_proc p
               JOIN pg_namespace n ON n.oid = p.pronamespace
               WHERE n.nspname = 'public'
                 AND p.prosecdef = true
                 AND (p.proconfig IS NULL
                      OR NOT EXISTS (SELECT 1 FROM unnest(p.proconfig) c
                                     WHERE c LIKE 'search_path=%'))
               """);

           assertThat(unpinned).isEmpty();
       }

       @Test
       void securityDefinerFunctionsAreNotExecutableByPublic() throws SQLException {
           var publicExecutable = queryForStrings("""
               SELECT p.proname
               FROM pg_proc p
               JOIN pg_namespace n ON n.oid = p.pronamespace
               WHERE n.nspname = 'public'
                 AND p.prosecdef = true
                 AND has_function_privilege('public', p.oid, 'EXECUTE')
               """);

           assertThat(publicExecutable)
               .as("REVOKE EXECUTE ... FROM PUBLIC bị quên — hàm mở cho mọi role")
               .isEmpty();
       }
   ```

2. **Catalog-driven test** — the real enforcement:
   ```java
       @Test
       void allTablesWithTenantIdHaveRlsEnabled() throws SQLException {
           try (Connection conn = dataSource.getConnection()) {
               // Find all tables with tenant_id column (excluding exempt)
               String sql = 
                   "SELECT t.tablename " +
                   "FROM pg_tables t " +
                   "WHERE t.schemaname = 'public' " +
                   "AND EXISTS (" +
                   "  SELECT 1 FROM information_schema.columns c " +
                   "  WHERE c.table_schema = 'public' " +
                   "  AND c.table_name = t.tablename " +
                   "  AND c.column_name = 'tenant_id'" +
                   ") " +
                   "AND t.tablename NOT IN ('flyway_schema_history')";
               
               try (var stmt = conn.createStatement();
                    var rs = stmt.executeQuery(sql)) {
                   
                   List<String> tablesWithTenantId = new ArrayList<>();
                   while (rs.next()) {
                       tablesWithTenantId.add(rs.getString(1));
                   }
                   
                   assertThat(tablesWithTenantId)
                       .as("Should find ~33 tables with tenant_id column")
                       .isNotEmpty();
                   
                   // Verify each has RLS enabled + policy
                   for (String table : tablesWithTenantId) {
                       boolean rlsEnabled = isRlsEnabled(conn, table);
                       assertThat(rlsEnabled)
                           .as("Table %s has tenant_id but RLS not enabled", table)
                           .isTrue();
                       
                       int policyCount = getPolicyCount(conn, table);
                       assertThat(policyCount)
                           .as("Table %s has RLS enabled but no policies", table)
                           .isGreaterThan(0);
                   }
               }
           }
       }
       
       private boolean isRlsEnabled(Connection conn, String tableName) 
           throws SQLException {
           
           String sql = 
               "SELECT relrowsecurity FROM pg_class " +
               "WHERE relname = ? AND relnamespace = 'public'::regnamespace";
           
           try (var pst = conn.prepareStatement(sql)) {
               pst.setString(1, tableName);
               try (var rs = pst.executeQuery()) {
                   return rs.next() && rs.getBoolean(1);
               }
           }
       }
       
       private int getPolicyCount(Connection conn, String tableName) 
           throws SQLException {
           
           String sql = 
               "SELECT COUNT(*) FROM pg_policies " +
               "WHERE tablename = ? AND schemaname = 'public'";
           
           try (var pst = conn.prepareStatement(sql)) {
               pst.setString(1, tableName);
               try (var rs = pst.executeQuery()) {
                   rs.next();
                   return rs.getInt(1);
               }
           }
       }
   ```

3. Test policy SQL syntax (sample 5):
   ```java
       @Test
       void allPolicySqlAreValid() throws SQLException {
           try (Connection conn = dataSource.getConnection()) {
               var policies = queryAllPoliciesFromDb(conn);
               
               assertThat(policies).isNotEmpty();
               
               var random = new Random(42);
               var sample = policies.stream()
                   .skip(Math.max(0, random.nextInt(Math.max(1, policies.size() - 5))))
                   .limit(5)
                   .collect(Collectors.toList());
               
               for (Map<String, Object> policy : sample) {
                   String qual = (String) policy.get("qual");
                   String table = (String) policy.get("table_name");
                   
                   assertThat(qual)
                       .as("Policy on %s should have USING clause", table)
                       .isNotBlank();
                   
                   assertThat(qual)
                       .as("Policy on %s USING should reference tenant_id or GUC", table)
                       .matches(".*(?:tenant_id|current_setting).*");
               }
           }
       }
       
       private List<Map<String, Object>> queryAllPoliciesFromDb(Connection conn)
           throws SQLException {
           
           String sql = 
               "SELECT schemaname, tablename, policyname, qual, with_check " +
               "FROM pg_policies WHERE schemaname = 'public' " +
               "ORDER BY tablename, policyname";
           
           try (var stmt = conn.createStatement();
                var rs = stmt.executeQuery(sql)) {
               
               List<Map<String, Object>> policies = new ArrayList<>();
               while (rs.next()) {
                   var p = new HashMap<String, Object>();
                   p.put("schema_name", rs.getString("schemaname"));
                   p.put("table_name", rs.getString("tablename"));
                   p.put("policy_name", rs.getString("policyname"));
                   p.put("qual", rs.getString("qual"));
                   p.put("with_check", rs.getString("with_check"));
                   policies.add(p);
               }
               return policies;
           }
       }
   ```

4. Documentation: `docs/SECURITY.md`:
   ```markdown
   # Row-Level Security
   
   ## Summary
   33 application tables + 1 exempt (flyway_schema_history).
   
   ### Class A (23 tables): strict tenant isolation
   15 existing, 2 BIGINT→UUID, 6 denormalized
   Policy: `tenant_id = NULLIF(current_setting(...), '')::uuid`
   
   ### Class B (10 tables): tenant + platform global
   4 existing nullable, 6 denormalized nullable
   Policy: `USING (NULL OR match)`, `WITH CHECK (NOT NULL AND match) OR platform`
   
   ### Tenants table
   Has policy `public_id = current_setting(...)` — tenant sees own, platform sees all
   
   ## Verification
   Catalog-driven test (P7) queries `information_schema` for every table with 
   `tenant_id` column, ensures RLS enabled + policy exists.
   
   If a new table is added with `tenant_id` in V21+, P7 will fail until 
   the table has RLS + policy.
   ```

## Success Criteria

- Catalog test: all ~33 `tenant_id` tables have RLS enabled + policy
- Only `flyway_schema_history` exempt (no `tenant_id`)
- Policy samples (5) have valid Postgres expressions
- Đúng **2** hàm `SECURITY DEFINER` trong schema, khớp allowlist; hàm thứ 3 làm **build fail**
- Mọi hàm `SECURITY DEFINER` đều có `SET search_path` và **không** `EXECUTE` được bởi `PUBLIC`
- Test coverage ≥80% on security-related tests
- `mvn test -Dtest=RlsArchitectureTest` passes
- Build fails if new table has `tenant_id` but no RLS
- **CI thiếu Docker → build fail**, không skip im lặng (test bảo mật không chạy mà build xanh là tệ hơn không có test)

## Quality and Testing State

- Quality gate: chưa chạy
- Testing: chưa bắt đầu

## Session Notes

_(trống)_
