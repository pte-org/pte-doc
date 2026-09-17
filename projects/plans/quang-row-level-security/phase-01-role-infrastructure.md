# Phase 1: Cơ sở hạ tầng vai trò & quyền

## Requirements

Tách runtime app khỏi owner: tạo role `pte_app` (không owner), chỉ có SELECT/INSERT/UPDATE/DELETE. APP_DB_USER vẫn là owner (migrations), `pte_app` là runtime user (app queries). Flyway chạy APP_DB_USER → bypass RLS tự động. App chạy `pte_app` → chịu RLS. Đặt ALTER DEFAULT PRIVILEGES để bảng tạo sau này tự động grant `pte_app`.

Maps to: **[ADR-003](../../architecture/ADR-003-tenant-isolation-and-infrastructure.md) § Implementation**

## Design Constraints

- **Owner bypass RLS là Postgres spec.** APP_DB_USER = owner bảng → tự động bypass RLS trên mọi query (Postgres behavior, không setting). Đó chính là lý do chuyển app sang `pte_app` — nếu app chạy owner, RLS trở thành trang trí. Không cần `FORCE RLS` vì `pte_app` không phải owner nên RLS áp bình thường
- **`ALTER DEFAULT PRIVILEGES` phải chạy **trong bối cảnh APP_DB_USER***.** Cái đó = current role lúc tạo schema defaults. Nếu quên hoặc chạy sai role, migration V15+ sẽ tạo bảng mà `pte_app` không có permission → `permission denied` ở runtime → app crash
- **Password từ env, không hardcode.** `docker-compose.yml` cấp `APP_DB_PASSWORD` khi start. Flyway dùng `APP_DB_PASSWORD` làm placeholder trong migration
- **`pte_app` chỉ có `LOGIN`; không `CREATEDB`, không `SUPERUSER`.** Giới hạn phạm vi tổn thất nếu credential bị lộ

## Steps

1. Migration `V14__rls_role_setup.sql` tạo role `pte_app` (chạy by Flyway as APP_DB_USER):
   ```sql
   -- Create role if not exists (idempotent for local dev)
   DO $$
   BEGIN
       CREATE ROLE pte_app WITH LOGIN PASSWORD '${pte_app_password}';
   EXCEPTION WHEN DUPLICATE_OBJECT THEN
       NULL;
   END $$;
   
   GRANT USAGE ON SCHEMA public TO pte_app;
   
   -- Current tables (V1–V13 created)
   GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO pte_app;
   GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO pte_app;
   
   -- Future tables (created by V15+)
   -- APP_DB_USER is current role here, so defaults apply when APP_DB_USER creates tables
   ALTER DEFAULT PRIVILEGES IN SCHEMA public 
     GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO pte_app;
   ALTER DEFAULT PRIVILEGES IN SCHEMA public 
     GRANT USAGE, SELECT ON SEQUENCES TO pte_app;
   ```

2. `application.yml` cấu hình DataSource cho app, Flyway cho owner:
   ```yaml
   spring:
     datasource:
       username: ${SPRING_DATASOURCE_USERNAME:pte_app}
       password: ${SPRING_DATASOURCE_PASSWORD:${APP_DB_PASSWORD:pte_app_password}}
     flyway:
       user: ${SPRING_FLYWAY_USER:postgres}  # APP_DB_USER
       password: ${SPRING_FLYWAY_PASSWORD:${POSTGRES_PASSWORD:postgres}}
       enabled: true
       placeholders:
         pte_app_password: ${APP_DB_PASSWORD:pte_app_password}
   ```

3. `docker-compose.yml` environment:
   ```yaml
   environment:
     POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
     APP_DB_PASSWORD: ${APP_DB_PASSWORD:-pte_app_dev}
     SPRING_DATASOURCE_USERNAME: pte_app
     SPRING_DATASOURCE_PASSWORD: ${APP_DB_PASSWORD:-pte_app_dev}
     SPRING_FLYWAY_USER: postgres
     SPRING_FLYWAY_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
   ```

4. `.env.example` (commit, never `.env`):
   ```
   POSTGRES_PASSWORD=<secure owner password>
   APP_DB_PASSWORD=<secure pte_app password>
   ```

5. `pom.xml` / `build.gradle`: add Testcontainers dependency (if not present):
   ```xml
   <dependency>
       <groupId>org.testcontainers</groupId>
       <artifactId>postgresql</artifactId>
       <scope>test</scope>
   </dependency>
   ```

6. Integration test `RlsRoleInfrastructureTest`:
   ```java
   @SpringBootTest
   @Testcontainers
   class RlsRoleInfrastructureTest {
       @Container
       static PostgreSQLContainer<?> postgres = 
           new PostgreSQLContainer<>(
               DockerImageName.parse("postgres:17"))
           .withDatabaseName("pte_test")
           .withUsername("postgres")
           .withPassword("test_owner");
       
       @DynamicPropertySource
       static void registerProperties(DynamicPropertyRegistry registry) {
           registry.add("spring.datasource.url", postgres::getJdbcUrl);
           registry.add("spring.datasource.username", () -> "pte_app");
           registry.add("spring.datasource.password", () -> "test_app");
           registry.add("spring.flyway.user", () -> "postgres");
           registry.add("spring.flyway.password", () -> "test_owner");
       }
       
       @Autowired
       private DataSource dataSource;
       
       @BeforeAll
       static void setupRoleBeforeMigration() throws SQLException {
           // Flyway will create pte_app role via V14, but test needs it earlier
           // so we create it manually for this test scenario
           try (Connection conn = DriverManager.getConnection(
               postgres.getJdbcUrl(), "postgres", "test_owner")) {
               conn.createStatement().execute(
                   "CREATE ROLE pte_app WITH LOGIN PASSWORD 'test_app'");
               conn.commit();
           } catch (SQLException e) {
               if (!e.getMessage().contains("already exists")) throw e;
           }
       }
       
       @Test
       void testPteAppRoleCanSelect() throws SQLException {
           try (Connection conn = DriverManager.getConnection(
               postgres.getJdbcUrl(), "pte_app", "test_app")) {
               var rs = conn.createStatement().executeQuery(
                   "SELECT 1");
               assertThat(rs.next()).isTrue();
           }
       }
       
       @Test
       void testPteAppCanInsertUpdateDelete() throws SQLException {
           // Insert as owner, verify pte_app can modify
           try (Connection owner = DriverManager.getConnection(
               postgres.getJdbcUrl(), "postgres", "test_owner")) {
               owner.createStatement().execute(
                   "INSERT INTO users (id, username, email, tenant_id) " +
                   "VALUES ('550e8400-e29b-41d4-a716-446655440000', " +
                   "'testuser', 'old@example.com', NULL)");
           }
           
           try (Connection app = DriverManager.getConnection(
               postgres.getJdbcUrl(), "pte_app", "test_app")) {
               app.createStatement().execute(
                   "UPDATE users SET email = 'new@example.com' " +
                   "WHERE username = 'testuser'");
               
               var rs = app.createStatement().executeQuery(
                   "SELECT email FROM users WHERE username = 'testuser'");
               rs.next();
               assertThat(rs.getString(1)).isEqualTo("new@example.com");
           }
       }
       
       @Test
       void testPteAppCannotCreateTable() throws SQLException {
           try (Connection app = DriverManager.getConnection(
               postgres.getJdbcUrl(), "pte_app", "test_app")) {
               assertThatThrownBy(() ->
                   app.createStatement()
                       .execute("CREATE TABLE hack_table (id INT)"))
                   .isInstanceOf(SQLException.class);
           }
       }
       
       @Test
       void testDefaultPrivilegesApplyToNewTable() throws SQLException {
           try (Connection owner = DriverManager.getConnection(
               postgres.getJdbcUrl(), "postgres", "test_owner")) {
               // Create new table after defaults are set
               owner.createStatement().execute(
                   "CREATE TABLE future_table (" +
                   "  id UUID PRIMARY KEY, " +
                   "  tenant_id UUID NOT NULL, " +
                   "  data TEXT)");
               
               // Verify pte_app inherited INSERT/SELECT via default privileges
               owner.createStatement().execute(
                   "SELECT grantee, privilege_type FROM " +
                   "information_schema.role_table_grants " +
                   "WHERE table_name='future_table'");
           }
           
           try (Connection app = DriverManager.getConnection(
               postgres.getJdbcUrl(), "pte_app", "test_app")) {
               app.createStatement().execute(
                   "INSERT INTO future_table (id, tenant_id, data) " +
                   "VALUES ('550e8400-e29b-41d4-a716-446655440001', " +
                   "'550e8400-e29b-41d4-a716-446655440002', 'test')");
           }
       }
   }
   ```

7. Startup checklist script (`docs/SETUP.md`):
   ```markdown
   ## First-time setup
   
   1. Copy `.env.example` to `.env`, fill in secure passwords
   2. `docker compose down -v` (drop old volume if it exists)
   3. `docker compose up` (Flyway creates `pte_app` role via V14)
   4. `mvn clean verify` (tests verify role has correct grants)
   
   If you see `permission denied for schema public` at startup:
   - The role exists but grants failed → check V14 executed as owner
   - Re-run: `docker compose down -v && docker compose up`
   ```

## Success Criteria

- Role `pte_app` được tạo trong V14 migration
- Password được lấy từ `APP_DB_PASSWORD` environment variable
- `pte_app` có `SELECT/INSERT/UPDATE/DELETE` trên toàn bộ tables
- `pte_app` có `USAGE/SELECT` trên sequences
- Default privileges đặt: bảng tạo V15+ tự động grant `pte_app`
- Integration test: `pte_app` INSERT/UPDATE/SELECT thành công
- Integration test: `pte_app` CREATE TABLE được reject
- Integration test: future table (tạo sau khi defaults đặt) `pte_app` có permission
- App khởi động bằng `pte_app` user, không permission error

## Quality and Testing State

- Quality gate: chưa chạy
- Testing: chưa bắt đầu

## Session Notes

_(trống)_
