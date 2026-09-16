# Phase 3: Đường ống GUC & chẩn đoán

## Requirements

Đặt `app.current_tenant` & `app.is_platform` transaction-local trên mỗi kết nối. Override `JpaTransactionManager.doBegin()`, gọi `set_config()` với bind parameter (không string concat), lấy giá trị từ `CurrentUserContext.current()` (**`Optional`, không phải `required()`**). Test fail-closed: GUC rỗng → query 0 dòng không error.

Maps to: **[ADR-003](../../architecture/ADR-003-tenant-isolation-and-infrastructure.md) § Authorization**

## Design Constraints

- **`doBegin()` signature: `protected void doBegin(Object transaction, TransactionDefinition definition)`.** Đối tượng `transaction` là `JpaTransactionObject` (package-private). Để lấy connection đã bind, dùng `DataSourceUtils.getConnection(dataSource)` — nó trả connection hiện tại của transaction
- **Luôn dùng `current_setting('app.current_tenant', true)` với 2-arg form.** Không có arg thứ hai, Postgres ném `42704 unrecognized configuration parameter` nếu GUC chưa set. Có arg thứ hai = fail-closed (trả null, không crash)
- **Truyền empty string `''` cho platform users, không `"null"` string.** `'null'::uuid` → `22P02 invalid input syntax for type uuid`. Rồi ở policy dùng `NULLIF(current_setting('app.current_tenant', true), '')::uuid` để chuyển `''` → `NULL`
- **Fail-closed = thiết kế.** GUC = `''` (empty) → `NULLIF(..., '')` → `NULL` → `NULL = UUID` → false → 0 dòng, không error. Test bắt buộc phân biệt "RLS filter" vs "dữ liệu trống"
- **`@SpringBootTest` + Testcontainers, không `@DataJpaTest`.** DataJpaTest wrap mọi test trong transaction & wrap DataSource, nên `RlsJpaTransactionManager` không bao giờ chạy. Chỉ SpringBootTest + kết nối as `pte_app` role mới chứng minh RLS
- **SecurityContextHolder mock.** `CurrentUserContext` không có public test seam. Tạo `JwtAuthenticationToken` với user details, set vào `SecurityContextHolder.getContext()` để `CurrentUserContext.current()` đọc được

- **BẮT BUỘC dùng `CurrentUserContext.current()` (trả `Optional`), TUYỆT ĐỐI không dùng `required()`.** `required()` **ném `IllegalStateException`** khi `SecurityContextHolder` trống. Đặt nó trong `doBegin()` nghĩa là **mọi transaction mở ra khi chưa đăng nhập đều nổ** — và danh sách đó dài hơn người ta tưởng: chính endpoint đăng nhập, endpoint công khai `POST /api/applications` (commercialization P2 — nộp đơn đăng ký tổ chức, không cần auth), actuator `health`, Testcontainers lúc khởi tạo, Flyway. App chết **trước khi** RLS kịp lọc bất cứ thứ gì.
  **"Chưa đăng nhập" là trạng thái hợp lệ và thường gặp, không phải lỗi.** Không có principal → `app.current_tenant = ''`, `app.is_platform = false`. Fail-closed lo phần còn lại: request đó không đọc được dữ liệu tenant nào, đúng như mong muốn.

## Steps

1. Tạo lớp `RlsJpaTransactionManager` trong `com.pte.shared.security`:
   ```java
   @Configuration
   public class RlsTransactionConfig {
       @Bean
       public JpaTransactionManager transactionManager(
           EntityManagerFactory emf,
           DataSource dataSource) {
           return new RlsJpaTransactionManager(emf, dataSource);
       }
   }
   
   class RlsJpaTransactionManager extends JpaTransactionManager {
       private final DataSource dataSource;
       
       public RlsJpaTransactionManager(EntityManagerFactory emf, DataSource ds) {
           super(emf);
           this.dataSource = ds;
       }
       
       @Override
       protected void doBegin(Object transaction, TransactionDefinition definition) {
           super.doBegin(transaction, definition);
           // After super.doBegin(), connection is bound to transaction
           Connection conn = DataSourceUtils.getConnection(dataSource);
           try {
               // current() -> Optional. KHÔNG dùng required(): nó ném khi
               // chưa đăng nhập, và đường chưa-đăng-nhập là hợp lệ (login,
               // POST /api/applications, actuator health, Flyway, test init).
               setRlsContext(conn, CurrentUserContext.current().orElse(null));
           } catch (SQLException e) {
               throw new RuntimeException("Failed to set RLS context", e);
           }
       }
       
       /** @param user null khi request chưa xác thực — hợp lệ, không phải lỗi. */
       private void setRlsContext(Connection conn, CurrentUser user) 
           throws SQLException {
           
           // Empty string (not the literal "null": 'null'::uuid -> 22P02).
           // Không có principal -> '' -> NULLIF -> NULL -> policy false -> 0 dòng.
           String tenantId = (user != null && user.tenantId() != null)
               ? user.tenantId().toString() 
               : "";
           String isPlatform = (user != null && user.isPlatformUser())
               ? "true" : "false";
           
           // Set app.current_tenant (always use 2-arg form)
           try (PreparedStatement pst = conn.prepareStatement(
               "SELECT set_config('app.current_tenant', ?::text, true)")) {
               pst.setString(1, tenantId);
               pst.executeQuery().close();
           }
           
           // Set app.is_platform
           try (PreparedStatement pst = conn.prepareStatement(
               "SELECT set_config('app.is_platform', ?::text, true)")) {
               pst.setString(1, isPlatform);
               pst.executeQuery().close();
           }
       }
   }
   ```

2. Update `application.yml` to ensure the new bean is used (no need if `@Configuration` auto-scanned):
   ```yaml
   spring:
     jpa:
       properties:
         hibernate.dialect: org.hibernate.dialect.PostgreSQLDialect
   ```

3. Create test seam for SecurityContext mocking in `com.pte.shared.testing`:
   ```java
   public class SecurityContextTestHelper {
       public static void mockSecurityContext(CurrentUser user) {
           var auth = new JwtAuthenticationToken(
               new JwtPrincipal(user.userId().toString()),
               null,
               user.roles().stream()
                   .map(SimpleGrantedAuthority::new)
                   .collect(Collectors.toList()));
           
           var context = SecurityContext.create(auth);
           SecurityContextHolder.setContext(context);
       }
       
       public static void clearSecurityContext() {
           SecurityContextHolder.clearContext();
       }
       
       public record JwtPrincipal(String userId) {}
   }
   ```

4. Test GUC not set outside transaction:
   ```java
   @SpringBootTest
   @Testcontainers
   class RlsGucPlumbingTest {
       @Container
       static PostgreSQLContainer<?> postgres = 
           new PostgreSQLContainer<>(DockerImageName.parse("postgres:17"));
       
       @Autowired
       private DataSource dataSource;
       
       @Test
       void testGucNotSetWithoutSecurityContext() throws SQLException {
           // Get connection directly (no transaction, no SecurityContext)
           Connection conn = dataSource.getConnection();
           try (var rs = conn.createStatement().executeQuery(
               "SELECT current_setting('app.current_tenant', true)")) {
               rs.next();
               assertThat(rs.getString(1)).isNull();
           }
       }
       
       @Test
       @Transactional
       void testGucSetWithinTransaction() throws SQLException {
           UUID tenantId = UUID.randomUUID();
           SecurityContextTestHelper.mockSecurityContext(
               new CurrentUser(UUID.randomUUID(), tenantId, 
                   List.of("STUDENT")));
           
           // Within @Transactional, RlsJpaTransactionManager sets GUC
           Connection conn = DataSourceUtils.getConnection(dataSource);
           try (var rs = conn.createStatement().executeQuery(
               "SELECT current_setting('app.current_tenant', true)")) {
               rs.next();
               assertThat(rs.getString(1))
                   .isEqualTo(tenantId.toString());
           } finally {
               DataSourceUtils.releaseConnection(conn, dataSource);
               SecurityContextTestHelper.clearSecurityContext();
           }
       }
       
       @Test
       @Transactional
       void testPlatformUserGucSetToEmpty() throws SQLException {
           SecurityContextTestHelper.mockSecurityContext(
               new CurrentUser(UUID.randomUUID(), null, 
                   List.of("PLATFORM_ADMIN")));
           
           Connection conn = DataSourceUtils.getConnection(dataSource);
           try (var rs = conn.createStatement().executeQuery(
               "SELECT current_setting('app.current_tenant', true)")) {
               rs.next();
               // Platform users: empty string (not "null" string, not NULL)
               assertThat(rs.getString(1)).isEmpty();
           } finally {
               DataSourceUtils.releaseConnection(conn, dataSource);
               SecurityContextTestHelper.clearSecurityContext();
           }
       }
   }
   ```

5. Test fail-closed: GUC not set (or wrong tenant) → query returns 0 rows, no error:
   ```java
   @Test
   @SpringBootTest
   @Testcontainers
   void testFailClosedWhenGucNotSet() throws SQLException {
       // Setup: create a user in tenant-A
       Tenant tenantA = tenantRepository.save(new Tenant("A"));
       User userA = userRepository.save(new User(tenantA.id(), "userA"));
       
       // Query outside transaction (no GUC set) → 0 rows
       Connection conn = dataSource.getConnection();
       try (var rs = conn.createStatement().executeQuery(
           "SELECT COUNT(*) FROM users")) {
           rs.next();
           assertThat(rs.getLong(1)).isZero();
       }
       
       // Query as wrong tenant → 0 rows (RLS policy denies)
       SecurityContextTestHelper.mockSecurityContext(
           new CurrentUser(UUID.randomUUID(), UUID.randomUUID(), 
               List.of("STUDENT")));
       try {
           userRepository.findAll();
           // RLS policy filters out tenant-A users
       } finally {
           SecurityContextTestHelper.clearSecurityContext();
       }
   }
   ```

6. Test row count assertions (not EXPLAIN message):
   ```java
   @Test
   @Transactional
   void testCorrectTenantReturnsRows() {
       Tenant tenantA = tenantRepository.save(new Tenant("A"));
       User userA = userRepository.save(new User(tenantA.id(), "userA"));
       
       SecurityContextTestHelper.mockSecurityContext(
           new CurrentUser(UUID.randomUUID(), tenantA.id(), 
               List.of("STUDENT")));
       
       var users = userRepository.findAll();
       assertThat(users).hasSize(1);
       assertThat(users.get(0).username()).isEqualTo("userA");
       
       SecurityContextTestHelper.clearSecurityContext();
   }
   
   @Test
   @Transactional
   void testWrongTenantReturnsZeroRows() {
       Tenant tenantA = tenantRepository.save(new Tenant("A"));
       User userA = userRepository.save(new User(tenantA.id(), "userA"));
       
       Tenant tenantB = tenantRepository.save(new Tenant("B"));
       
       SecurityContextTestHelper.mockSecurityContext(
           new CurrentUser(UUID.randomUUID(), tenantB.id(), 
               List.of("STUDENT")));
       
       var users = userRepository.findAll();
       assertThat(users).isEmpty();
       
       SecurityContextTestHelper.clearSecurityContext();
   }
   ```

7. Test GUC in pg_settings (verify it's set, don't assert EXPLAIN message):
   ```java
   @Test
   @Transactional
   void testGucAppearInPgSettings() throws SQLException {
       UUID tenantId = UUID.randomUUID();
       SecurityContextTestHelper.mockSecurityContext(
           new CurrentUser(UUID.randomUUID(), tenantId, 
               List.of("STUDENT")));
       
       Connection conn = DataSourceUtils.getConnection(dataSource);
       try (var rs = conn.createStatement().executeQuery(
           "SELECT setting FROM pg_settings WHERE name = 'app.current_tenant'")) {
           rs.next();
           assertThat(rs.getString(1)).isEqualTo(tenantId.toString());
       } finally {
           DataSourceUtils.releaseConnection(conn, dataSource);
           SecurityContextTestHelper.clearSecurityContext();
       }
   }
   ```

8. Note: Do NOT test `EXPLAIN (FORMAT json)` for "Rows removed by security policy" message — that only appears in `EXPLAIN ANALYZE` output, and assertion on message text is brittle. Use row count assertions instead.

## Success Criteria

- `RlsJpaTransactionManager.doBegin()` set GUC via `DataSourceUtils.getConnection()`
- GUC `app.current_tenant` set to tenant UUID (or empty string for platform)
- GUC `app.is_platform` set to `"true"`/`"false"`
- Always use 2-arg form `current_setting(..., true)` (fail-closed, not crash)
- Test: GUC not set outside transaction
- Test: GUC set within transaction
- Test: fail-closed — GUC = null/wrong → 0 rows, no error
- Test: correct GUC → >0 rows
- Test: platform user GUC = empty string (not "null")
- No string concatenation, use PreparedStatement bind parameters
- App boots, first query (RLS still off) returns 0 rows as expected

## Quality and Testing State

- Quality gate: chưa chạy
- Testing: chưa bắt đầu

## Session Notes

_(trống)_
