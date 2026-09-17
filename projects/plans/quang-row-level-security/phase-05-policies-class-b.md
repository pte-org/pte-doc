# Phase 5: Sóng 2 — Class B (nullable/global)

## Requirements

10 bảng Class B — 4 với `tenant_id UUID NULL` (platform-owned global), 6 denormalize ở P2 (NULLABLE). Policy: `USING (NULL OR match)` cho read, `WITH CHECK` cấm tenant write NULL. Fix view `identity_student_directory` → `WITH (security_invoker = true)`.

**Kèm theo trong CÙNG migration: đường tra cứu đăng nhập.** Bật RLS trên `users`/`login_hashes` mà không mở đường cho bước xác thực thì **không ai đăng nhập được nữa** — xem Design Constraint đầu tiên.

Maps to: **[ADR-003](../../architecture/ADR-003-tenant-isolation-and-infrastructure.md) § Global Content**

## Design Constraints

- **VÒNG XOAY CHẾT Ở ĐĂNG NHẬP — đọc trước khi viết bất kỳ dòng nào của phase này.**
  Xác thực phải truy vấn `users` + `login_hashes` **trước khi** hệ thống biết người dùng là ai. Chưa biết là ai → chưa có GUC → policy Class B tính `tenant_id IS NULL OR tenant_id = NULL` → với **tenant user** ra `false` → hàng bị lọc → "không tìm thấy tài khoản". Bật RLS trên `users` mà không xử lý bước này = **khoá cửa toàn bộ tenant user, vĩnh viễn**.
  **Bẫy phụ khiến lỗi này rất dễ lọt qua khâu test:** platform admin **vẫn đăng nhập bình thường** (vì `tenant_id IS NULL` đúng với vế đầu). Người test đầu tiên thường chính là admin → thấy mọi thứ chạy ngon → merge. Lỗi chỉ nổ khi tenant user thật đăng nhập.
  → Bắt buộc: **hàm `SECURITY DEFINER` hẹp cho bước tra cứu credential, nằm trong CÙNG migration `V16` với policy trên `users`.** Policy land trước hàm là sập login ngay trong khoảng giữa hai migration — đó là lý do **không tách thành phase riêng**.

- **Mỗi hàm `SECURITY DEFINER` là một lỗ khoét có chủ đích xuyên qua RLS.** Nó chạy bằng quyền owner (superuser) nên policy không áp — đó chính là thứ ta cần ở đây, và cũng chính là thứ nguy hiểm nếu mọc thêm. Luật: **chỉ viết cho đường tiền-xác thực**, trả về đúng số cột tối thiểu, tham số hẹp, và **P7 phải đếm số hàm `SECURITY DEFINER` trong schema rồi so với danh sách cho phép — mọc thêm cái thứ N+1 là build fail.**

- **`WITH CHECK` cấm ghi NULL chính là thứ biến "quên điền `tenant_id`" từ rò dữ liệu âm thầm thành lỗi ồn ào.** Nếu chỉ có `USING`, một đường ghi quên set `tenant_id` sẽ tạo hàng `NULL` = "nội dung platform" → **mọi tenant đọc được**; với `login_hashes` thì đó là thảm hoạ. Có `WITH CHECK`, INSERT đó bị **từ chối ngay tại DB**. Vì vậy `WITH CHECK` phải áp cho **đủ cả 10 bảng**, kể cả 6 bảng denormalize — bỏ sót đúng một bảng là mở lại đúng lỗ này.

- **10 bảng Class B**: 4 nullable sẵn (`users`, `questions`, `exam_blueprints`, `exam_snapshots`) + 6 denormalize nullable P2 (`user_roles`, `login_hashes`, `refresh_tokens`, `question_options`, `blueprint_items`, `snapshot_items`)
- **USING: `tenant_id IS NULL OR tenant_id = NULLIF(current_setting('app.current_tenant', true), '')::uuid`** — đọc platform (NULL) + chính tenant
- **WITH CHECK: cấm tenant write NULL.** SQL: `(tenant_id IS NOT NULL AND tenant_id = NULLIF(current_setting('app.current_tenant', true), '')::uuid) OR coalesce(current_setting('app.is_platform', true)::boolean, false)`. **Một CREATE POLICY per bảng (USING + WITH CHECK together)**
- **Cha = NULL → con nullable.** Platform user `users.tenant_id = NULL` → `user_roles.tenant_id = NULL` (không thể NOT NULL). Class A policy `tenant_id = X` khiến NULL ≠ X = deny → platform user không login. Class B `NULL IS NULL = true` → platform user thấy
- **`identity_student_directory` WITH (security_invoker = true)** — view chạy quyền gọi, không owner → RLS sinh hiệu lực trên `users` + `user_roles`

## Steps

1. Sửa view `identity_student_directory` (V4__enrollment.sql): `CREATE OR REPLACE VIEW` với cột cụ thể:
   ```sql
   CREATE OR REPLACE VIEW identity_student_directory
     WITH (security_invoker = true)
   AS
     SELECT u.id, u.public_id, u.username, u.email, u.full_name,
            u.student_code, u.phone, u.status, u.created_at,
            u.tenant_id, u.deleted
     FROM users u
     JOIN user_roles ur ON u.id = ur.user_id
     WHERE ur.role = 'STUDENT';
   ```

2. Migration `V16__rls_class_b.sql` — enable RLS + create policies (10 bảng):
   ```sql
   ALTER TABLE users ENABLE ROW LEVEL SECURITY;
   ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
   ALTER TABLE exam_blueprints ENABLE ROW LEVEL SECURITY;
   ALTER TABLE exam_snapshots ENABLE ROW LEVEL SECURITY;
   ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
   ALTER TABLE login_hashes ENABLE ROW LEVEL SECURITY;
   ALTER TABLE refresh_tokens ENABLE ROW LEVEL SECURITY;
   ALTER TABLE question_options ENABLE ROW LEVEL SECURITY;
   ALTER TABLE blueprint_items ENABLE ROW LEVEL SECURITY;
   ALTER TABLE snapshot_items ENABLE ROW LEVEL SECURITY;
   
   -- ONE policy per table (USING + WITH CHECK together)
   CREATE POLICY class_b_restrict ON users
     FOR ALL
     USING (tenant_id IS NULL OR tenant_id = NULLIF(current_setting('app.current_tenant', true), '')::uuid)
     WITH CHECK (
       (tenant_id IS NOT NULL AND tenant_id = NULLIF(current_setting('app.current_tenant', true), '')::uuid)
       OR coalesce(current_setting('app.is_platform', true)::boolean, false)
     );
   
   -- ... (repeat for 9 other tables with same pattern)
   ```

3. **Cùng `V16__rls_class_b.sql`, ngay sau các policy** — hàm tra cứu đăng nhập. Phải cùng file: policy land mà hàm chưa có là sập login trong khoảng giữa hai migration.
   ```sql
   -- SECURITY DEFINER: chạy bằng quyền owner -> RLS không áp.
   -- Đây là lỗ khoét DUY NHẤT được phép, chỉ cho bước tiền-xác thực.
   -- Bề mặt hẹp: tham số là username, trả đúng số cột tối thiểu để xác thực.
   CREATE OR REPLACE FUNCTION auth_lookup_by_username(p_username text)
   RETURNS TABLE (
       id            bigint,
       public_id     uuid,
       tenant_id     uuid,
       password_hash text,
       status        text
   )
   LANGUAGE sql
   STABLE
   SECURITY DEFINER
   SET search_path = public, pg_temp   -- chống search_path hijack
   AS $$
       SELECT u.id, u.public_id, u.tenant_id, lh.password_hash, u.status
       FROM users u
       JOIN login_hashes lh ON lh.user_id = u.id
       WHERE u.username = p_username
         AND u.deleted = false;
   $$;

   -- Bắt buộc: mặc định PUBLIC được EXECUTE. Quên hai dòng này là mở hàm
   -- cho mọi role, tức mở luôn đường đọc credential.
   REVOKE EXECUTE ON FUNCTION auth_lookup_by_username(text) FROM PUBLIC;
   GRANT  EXECUTE ON FUNCTION auth_lookup_by_username(text) TO pte_app;
   ```
   `SET search_path` không phải trang trí — hàm `SECURITY DEFINER` không cố định search_path là lỗ leo thang quyền kinh điển.

4. **Đường refresh token cũng là tiền-xác thực** — `refresh_tokens` được tra cứu khi chưa có principal. Làm hàm `auth_lookup_refresh_token(p_token_hash text)` theo đúng khuôn trên (STABLE, SECURITY DEFINER, `SET search_path`, REVOKE/GRANT).

5. `identity` đổi **đúng bước tra cứu credential** sang gọi hai hàm này (native query). **Mọi truy vấn `users` khác giữ nguyên đường JPA có RLS** — không được nhân cơ hội này mà đẩy thêm query nào qua hàm.

6. Ghi danh sách hàm `SECURITY DEFINER` được phép vào một hằng số dùng chung, để P7 so sánh. Hiện tại: đúng **2** hàm.

7. Test: tenant user ở tenant-A đăng nhập được sau khi RLS bật. **Đây là test quan trọng nhất của cả plan** — nó là thứ duy nhất phân biệt "RLS chạy đúng" với "đã khoá cửa toàn bộ khách hàng".

8. Test: đăng nhập **từng vai trò** (`STUDENT`, `HOST_ADMIN`, `PROCTOR`, `LECTURER`, `PROGRAM_COORDINATOR`, `PLATFORM_ADMIN`). Không được chỉ test `PLATFORM_ADMIN` — vai trò đó lọt qua kể cả khi thiết kế sai.

9. Test: `pte_app` **không** SELECT thẳng `users` của tenant khác được, dù hàm tồn tại — chứng minh hàm không nới rộng quyền ngoài phạm vi của nó.

10. Test: sai username → hàm trả 0 hàng (không lỗi, không lộ việc user có tồn tại hay không).

11. Integration test:
   ```java
   @SpringBootTest
   @Testcontainers
   class RlsClassBPolicyTest {
       @Container
       static PostgreSQLContainer<?> postgres =
           new PostgreSQLContainer<>(DockerImageName.parse("postgres:17"));
       
       @Autowired
       private QuestionRepository questionRepository;
       @Autowired
       private TenantRepository tenantRepository;
       
       @Test
       @Transactional
       void testClassBReadGlobalData() {
           Question globalQ = questionRepository.save(
               new Question(null, "global-q", Visibility.SHARED));
           
           Tenant tenantA = tenantRepository.save(new Tenant("A"));
           
           SecurityContextTestHelper.mockSecurityContext(
               new CurrentUser(UUID.randomUUID(), tenantA.id(),
                   List.of("HOST_ADMIN")));
           
           try {
               var questions = questionRepository.findAll();
               assertThat(questions).contains(globalQ);
           } finally {
               SecurityContextTestHelper.clearSecurityContext();
           }
       }
       
       @Test
       @Transactional
       void testClassBReadOwnPlusGlobal() {
           Question globalQ = questionRepository.save(
               new Question(null, "global", Visibility.SHARED));
           
           Tenant tenantA = tenantRepository.save(new Tenant("A"));
           Question ownQ = questionRepository.save(
               new Question(tenantA.id(), "own", Visibility.SHARED));
           
           Tenant tenantB = tenantRepository.save(new Tenant("B"));
           Question otherQ = questionRepository.save(
               new Question(tenantB.id(), "other", Visibility.SHARED));
           
           SecurityContextTestHelper.mockSecurityContext(
               new CurrentUser(UUID.randomUUID(), tenantA.id(),
                   List.of("HOST_ADMIN")));
           
           try {
               var questions = questionRepository.findAll();
               assertThat(questions)
                   .containsExactlyInAnyOrder(globalQ, ownQ)
                   .doesNotContain(otherQ);
           } finally {
               SecurityContextTestHelper.clearSecurityContext();
           }
       }
       
       @Test
       @Transactional
       void testClassBWithCheckPreventsNullWrite() {
           Tenant tenantA = tenantRepository.save(new Tenant("A"));
           
           SecurityContextTestHelper.mockSecurityContext(
               new CurrentUser(UUID.randomUUID(), tenantA.id(),
                   List.of("HOST_ADMIN")));
           
           try {
               var q = new Question(null, "fake-global", Visibility.SHARED);
               assertThatThrownBy(() -> questionRepository.save(q))
                   .isInstanceOf(DataIntegrityViolationException.class);
           } finally {
               SecurityContextTestHelper.clearSecurityContext();
           }
       }
       
       @Test
       @Transactional
       void testPlatformCanWriteNull() {
           SecurityContextTestHelper.mockSecurityContext(
               new CurrentUser(UUID.randomUUID(), null,
                   List.of("PLATFORM_AUTHOR")));
           
           try {
               var q = new Question(null, "platform-q", Visibility.SHARED);
               questionRepository.save(q);
               assertThat(q.tenantId()).isNull();
           } finally {
               SecurityContextTestHelper.clearSecurityContext();
           }
       }
   }
   ```

4. Test view `identity_student_directory`:
   ```java
   @Test
   void testStudentDirectorySecurityInvoker() {
       Tenant tenantA = tenantRepository.save(new Tenant("A"));
       User studentA = userRepository.save(
           new User(tenantA.id(), "student-a"));
       userRoleRepository.save(
           new UserRole(studentA.id(), "STUDENT", tenantA.id()));
       
       Tenant tenantB = tenantRepository.save(new Tenant("B"));
       User studentB = userRepository.save(
           new User(tenantB.id(), "student-b"));
       userRoleRepository.save(
           new UserRole(studentB.id(), "STUDENT", tenantB.id()));
       
       SecurityContextTestHelper.mockSecurityContext(
           new CurrentUser(UUID.randomUUID(), tenantA.id(),
               List.of("STUDENT")));
       
       try (var conn = DriverManager.getConnection(...)) {
           var students = conn.createStatement().executeQuery(
               "SELECT username FROM identity_student_directory");
           
           var usernames = new ArrayList<String>();
           while (students.next()) {
               usernames.add(students.getString(1));
           }
           
           assertThat(usernames)
               .containsExactly("student-a")
               .doesNotContain("student-b");
       } finally {
           SecurityContextTestHelper.clearSecurityContext();
       }
   }
   ```

## Success Criteria

- 10 bảng RLS enabled
- Mỗi bảng có một CREATE POLICY (USING + WITH CHECK)
- USING: `NULL OR = current_setting(...)`
- WITH CHECK: `(NOT NULL AND = current_setting(...)) OR is_platform`
- Test: read global (NULL) — OK
- Test: read own + global, not other tenant — OK
- Test: prevent write NULL — OK (tenant rejected)
- Test: platform write NULL — OK
- View `identity_student_directory` with `security_invoker` — OK
- **Tenant user thật đăng nhập được sau khi RLS bật** — tiêu chí quan trọng nhất của cả plan. Không tính nếu chỉ test bằng `PLATFORM_ADMIN`: vai trò đó vào được kể cả khi thiết kế sai
- **Đăng nhập được với đủ 6 vai trò**: `STUDENT`, `HOST_ADMIN`, `PROCTOR`, `LECTURER`, `PROGRAM_COORDINATOR`, `PLATFORM_ADMIN`
- Hàm `SECURITY DEFINER` có `SET search_path`, đã `REVOKE ... FROM PUBLIC`, chỉ `pte_app` được `EXECUTE`
- `pte_app` vẫn **không** SELECT thẳng được `users` của tenant khác, dù hàm tồn tại
- Refresh token hoạt động (đường tiền-xác thực thứ hai)
- Flyway V16 OK — policy và hàm auth **trong cùng một file**
- App boots

## Quality and Testing State

- Quality gate: chưa chạy
- Testing: chưa bắt đầu

## Session Notes

_(trống)_
