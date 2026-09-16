# Phase 2: Chuẩn hoá schema

## Requirements

Normalize `organizations.tenant_id` + `quota_transactions.tenant_id` từ BIGINT→UUID (sửa `CREATE TABLE` thẳng). Denormalize `tenant_id UUID` lên 12 bảng con: 6 Class A (NOT NULL) + 6 Class B (NULLABLE). Cập nhật 12 JPA entities + mọi đường ghi phải điền tenant_id trước insert. Sửa V2–V13 thẳng. Cả đội `docker compose down -v` trước P3.

Maps to: **[ADR-003](../../architecture/ADR-003-tenant-isolation-and-infrastructure.md) § Data Model**

## Design Constraints

- **Sửa V2–V13 thẳng** (không `ALTER ADD COLUMN` hay `ALTER USING`), edit `CREATE TABLE` trong migration cũ. DB trống nên rewrite đầy đủ. Từ P3 cấm sửa; chỉ V21+ được thêm
- **Cột denormalize sai lệch → RLS lọc sai, im lặng, không báo lỗi.** Tệ hơn không có RLS (RLS ít nhất báo sai). **Mọi ghi phải điền tenant_id trước insert**, không có ngoại lệ. Code review bắt buộc kiểm từng đường tạo row
- **Class B denormalize NULLABLE** (không NOT NULL) — cha có `tenant_id = NULL` (platform user, platform content), con phải theo. Platform user tạo role → `user_roles.tenant_id = NULL`. Không nullable = vi phạm khóa ngoại logic
- **Cả đội `docker compose down -v`** sau P2 merge — Flyway checksum mismatch nếu DB cũ
- **12 JPA entity + Repository cập nhật** — `ddl-auto: validate` fail nếu entity field mismatch schema

## Steps

1. **Sửa V3__tenancy.sql**: edit `CREATE TABLE organizations` và `quota_transactions` để `tenant_id` thành UUID (không dùng ALTER):
   ```sql
   CREATE TABLE organizations (
     id UUID PRIMARY KEY,
     tenant_id UUID NOT NULL REFERENCES tenants (public_id),
     name VARCHAR(255) NOT NULL,
     ...
   );
   
   CREATE TABLE quota_transactions (
     id UUID PRIMARY KEY,
     tenant_id UUID NOT NULL REFERENCES tenants (public_id),
     ...
   );
   ```
   (Thay BIGINT → UUID trong định nghĩa bảng, giữ nguyên các cột khác)

2. **Sửa V4–V13**: edit hoặc thêm `CREATE TABLE` để 12 bảng con có cột `tenant_id`:
   - **6 Class A (NOT NULL)**:
     ```sql
     CREATE TABLE question_options (
       id UUID PRIMARY KEY,
       tenant_id UUID NOT NULL,
       question_id UUID NOT NULL,
       ...
     );
     -- Similarly for: blueprint_items, snapshot_items, pinned_items, attempt_answers, attempt_heartbeats, session_compositions, programs, student_classes
     ```
   - **6 Class B (NULLABLE)** — lý do: cha có thể NULL:
     ```sql
     CREATE TABLE user_roles (
       id UUID PRIMARY KEY,
       tenant_id UUID,  -- nullable: platform user has tenant_id = NULL
       user_id UUID NOT NULL,
       role VARCHAR(32) NOT NULL,
       ...
     );
     -- Similarly for: login_hashes, refresh_tokens, question_options, blueprint_items, snapshot_items
     ```

3. **Update 12 JPA entities** để có `tenantId` field:
   ```java
   @Entity
   @Table(name = "question_options")
   public class QuestionOption {
       @Id
       private UUID id;
       
       @Column(name = "tenant_id", nullable = false)
       private UUID tenantId;  // Class A
       
       @Column(name = "question_id", nullable = false)
       private UUID questionId;
       // ...
   }
   
   @Entity
   @Table(name = "user_roles")
   public class UserRole {
       @Id
       private UUID id;
       
       @Column(name = "tenant_id")  // NO nullable = false — it's nullable
       private UUID tenantId;  // Class B
       
       @Column(name = "user_id", nullable = false)
       private UUID userId;
       // ...
   }
   ```

4. **Update Repository** cho 12 entities với query method:
   ```java
   public interface QuestionOptionRepository extends JpaRepository<QuestionOption, UUID> {
       Optional<QuestionOption> findByIdAndTenantId(UUID id, UUID tenantId);
       boolean existsByIdAndTenantId(UUID id, UUID tenantId);
   }
   
   public interface UserRoleRepository extends JpaRepository<UserRole, UUID> {
       List<UserRole> findByUserIdAndTenantId(UUID userId, UUID tenantId);
       Optional<UserRole> findByIdAndTenantId(UUID id, UUID tenantId);
   }
   ```

5. **Update every write path** to fill `tenantId` before insert:
   ```java
   // BAD (missing tenantId)
   public void createQuestionOption(CreateOptionRequest req) {
       var option = new QuestionOption(req.questionId(), req.text());
       optionRepository.save(option);  // tenantId = null → RLS filters later = silent bug
   }
   
   // GOOD (explicit tenantId)
   public void createQuestionOption(CreateOptionRequest req) {
       var currentUser = CurrentUserContext.required();
       var option = new QuestionOption(
           req.questionId(),
           currentUser.tenantId(),  // ← explicit
           req.text());
       optionRepository.save(option);
   }
   ```

6. **Update bulkers/seeders** (if any):
   ```java
   public class QuestionOptionBulkWriter {
       public void writeBatch(List<QuestionOption> options, UUID tenantId) {
           options.forEach(opt -> opt.setTenantId(tenantId));  // ← fill before write
           optionRepository.saveAll(options);
       }
   }
   ```

7. **SQL sanity check** — all 12 have `tenant_id`:
   ```sql
   SELECT tablename, COUNT(*) FROM information_schema.columns
   WHERE table_name IN (
     'question_options', 'blueprint_items', 'snapshot_items', 'pinned_items',
     'attempt_answers', 'attempt_heartbeats', 'session_compositions',
     'user_roles', 'login_hashes', 'refresh_tokens', 'programs', 'student_classes'
   )
   AND column_name = 'tenant_id'
   GROUP BY tablename;
   -- Expected: 12 rows, count=1 each
   ```

8. **Flyway validation**: `flyway info` → V1–V13 xanh, checksum OK

9. **Entity validation**: app startup with `ddl-auto: validate` must pass:
   ```bash
   mvn spring-boot:run
   # Should not error on entity<→schema mismatch
   ```

## Success Criteria

- 12 denormalized bảng có `tenant_id` column (6 NOT NULL Class A, 6 NULLABLE Class B)
- `organizations` + `quota_transactions` converted BIGINT→UUID
- 12 JPA entities have `tenantId` field with correct `nullable` attribute
- 12 Repository classes have `findByIdAndTenantId()` method
- Every write path explicitly fills `tenantId` before insert
- Flyway V1–V13 migrate OK
- App boots with `ddl-auto: validate`, no entity mismatch errors
- SQL sanity check confirms 12 columns exist

## Design Constraint Notes

**Denormalization = liability if not filled correctly.** Code review must check:
1. Every `new ClassName(...)` that includes `tenantId` parameter
2. Every `repository.save(entity)` where entity was created — is `tenantId` set?
3. Every bulk writer/seeder — is tenantId filled before batch insert?

Forgetting this is silent — RLS will filter future queries, but developer will see 0 rows and assume data never existed. Always test by querying raw SQL (bypass RLS) to confirm data was actually written, then verify RLS filters it correctly (via policy checks in P4/P5).

## Quality and Testing State

- Quality gate: chưa chạy
- Testing: chưa bắt đầu

## Session Notes

_(trống)_
