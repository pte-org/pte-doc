# Phase 6: Workers — truyền tenant context

## Requirements

Hai async consumer (`AiScoringWorker`, `EmailWorker`) chạy ngoài request context (không `CurrentUserContext`). Truyền `tenant_id` trong message header (RabbitMQ), worker đọc header, set GUC = tenant_id trước khi xử lý. Nếu message không có tenant_id header → set GUC = `''` (empty, tương đương platform/NULL, chỉ xử lý platform data).

Maps to: **[ADR-003](../../architecture/ADR-003-tenant-isolation-and-infrastructure.md) § Async Processing**

## Design Constraints

- **Worker chạy ngoài HTTP request cycle** → `CurrentUserContext` trống, không `@Transactional`, không Spring SecurityContext. Manual `JdbcTemplate` + `TransactionTemplate` explicit
- **Message header phải mang `tenant_id` UUID** — set lúc enqueue. Không header → worker chạy với GUC = `''` (empty), chỉ xử lý platform-owned (nullable tenant_id). Không bao giờ GUC = null (fail-closed → 0 rows)
- **Tạo transaction explicit** — `TransactionTemplate`. Worker không ai `@Transactional`, phải tự manage
- **GUC set = empty string `''` cho platform** — toàn bộ policy dùng `NULLIF(current_setting(...), '')::uuid`, nên `''` → NULL → `NULL IS NULL` → true (read global) hoặc `NULL IS NOT NULL` → false (prevent write NULL). Consistent với P3 đặc tính
- **Test bắt buộc chứng minh worker thấy dữ liệu** — không phải 0 rows do RLS, mà là dữ liệu thực tế

## Steps

1. RabbitMQ message class thêm header `tenant_id`:
   ```java
   public record ScoringMessage(
       UUID examinationId,
       List<AttemptAnswer> answers
       // Metadata: header được set bởi producer, không phần của payload
   ) {}
   
   // Producer side.
   // CHÚ Ý: ở đây dùng required(), KHÁC với doBegin() của P3 vốn phải dùng
   // current(). Khác biệt là có chủ đích: lúc enqueue một job chấm bài mà
   // không biết nó thuộc tenant nào thì đó LÀ lỗi — job sẽ không bao giờ
   // đọc lại được dữ liệu của mình. Nổ ngay tại đây tốt hơn là đẩy một
   // message vô chủ vào queue rồi worker lặng lẽ trả 0 dòng.
   // Ngược lại ở doBegin(), "chưa đăng nhập" là trạng thái bình thường.
   @Service
   public class ScoringService {
       public void requestAiScoring(UUID examinationId) {
           var tenantId = CurrentUserContext.required().tenantId();
           
           var message = new ScoringMessage(examinationId, ...);
           rabbitTemplate.convertAndSend(exchange, routingKey, message,
               msg -> {
                   // Set tenant_id header (UUID or empty string for platform)
                   String headerValue = tenantId != null 
                       ? tenantId.toString() 
                       : "";
                   msg.getMessageProperties().setHeader("tenant_id", headerValue);
                   return msg;
               });
       }
   }
   ```

2. Worker base class `TenantAwareMessageConsumer`:
   ```java
   @Component
   abstract class TenantAwareMessageConsumer {
       @Autowired
       protected JdbcTemplate jdbcTemplate;
       
       @Autowired
       protected TransactionTemplate transactionTemplate;
       
       @Autowired
       protected DataSource dataSource;
       
       /**
        * Execute work within a transaction with RLS context set.
        * @param tenantIdStr UUID string or empty string ("") for platform
        * @param work function to execute with connection
        */
       protected <T> T withTenantContext(String tenantIdStr, 
           Function<Connection, T> work) {
           
           return transactionTemplate.execute(status -> {
               Connection conn = DataSourceUtils.getConnection(dataSource);
               try {
                   String gucValue = tenantIdStr != null ? tenantIdStr : "";
                   setGucTenant(conn, gucValue);
                   return work.apply(conn);
               } finally {
                   DataSourceUtils.releaseConnection(conn, dataSource);
               }
           });
       }
       
       private void setGucTenant(Connection conn, String tenantIdValue) 
           throws SQLException {
           // Set app.current_tenant (always use 2-arg form)
           try (var pst = conn.prepareStatement(
               "SELECT set_config('app.current_tenant', ?::text, true)")) {
               pst.setString(1, tenantIdValue);  // UUID string or empty string
               pst.executeQuery().close();
           }
           // Set app.is_platform (true if empty, false if UUID)
           try (var pst = conn.prepareStatement(
               "SELECT set_config('app.is_platform', ?::text, true)")) {
               String isPlatform = tenantIdValue.isEmpty() ? "true" : "false";
               pst.setString(1, isPlatform);
               pst.executeQuery().close();
           }
       }
   }
   ```

3. `AiScoringWorker` implement consumer:
   ```java
   @Component
   class AiScoringWorker extends TenantAwareMessageConsumer {
       @Autowired
       private ScoringAnswerRepository scoringAnswerRepository;
       
       @RabbitListener(queues = "scoring.queue")
       public void processScoringTask(
           Message message,
           Channel channel,
           @Payload ScoringMessage payload) throws Exception {
           
           String tenantId = extractTenantId(message);
           
           withTenantContext(tenantId, conn -> {
               // Query attempt data → RLS filters by tenant_id
               var answers = jdbcTemplate.queryForList(
                   "SELECT * FROM scoring_answers WHERE attempt_id = ?",
                   ScoringAnswerMapper.INSTANCE,
                   payload.examinationId());
               
               // Process AI scoring
               aiService.scoreAnswers(answers);
               
               // Update score table
               jdbcTemplate.update(
                   "UPDATE scoring_results SET score = ? WHERE id = ?",
                   scoreValue, resultId);
               
               channel.basicAck(
                   message.getMessageProperties().getDeliveryTag(), 
                   false);
               return null;
           });
       }
       
       private String extractTenantId(Message msg) {
           var header = msg.getMessageProperties()
               .getHeader("tenant_id");
           return header != null ? header.toString() : "";
       }
   }
   ```

4. `EmailWorker` tương tự:
   ```java
   @Component
   class EmailWorker extends TenantAwareMessageConsumer {
       @RabbitListener(queues = "email.queue")
       public void sendEmailNotification(
           Message message,
           Channel channel,
           @Payload EmailMessage payload) throws Exception {
           
           String tenantId = extractTenantId(message);
           
           withTenantContext(tenantId, conn -> {
               // Query user, RLS filters by tenant_id
               var user = jdbcTemplate.queryForObject(
                   "SELECT * FROM users WHERE id = ?",
                   UserRowMapper.INSTANCE,
                   payload.userId());
               
               emailService.send(user.email(), payload.subject(), ...);
               
               channel.basicAck(
                   message.getMessageProperties().getDeliveryTag(), 
                   false);
               return null;
           });
       }
       
       private String extractTenantId(Message msg) {
           var header = msg.getMessageProperties()
               .getHeader("tenant_id");
           return header != null ? header.toString() : "";
       }
   }
   ```

5. Test worker respects tenancy:
   ```java
   @SpringBootTest
   @RabbitTest
   class WorkerTenantContextTest {
       @Test
       void testAiScoringWorkerRespectsTenancy() {
           // Setup: tenant-A with scoring answer
           Tenant tenantA = tenantRepository.save(new Tenant("A"));
           Examination examA = examinationRepository.save(
               new Examination(tenantA.id(), ...));
           ScoringAnswer answerA = scoringAnswerRepository.save(
               new ScoringAnswer(examA.id(), tenantA.id(), ...));
           
           // Setup: tenant-B with different answer (interference test)
           Tenant tenantB = tenantRepository.save(new Tenant("B"));
           Examination examB = examinationRepository.save(
               new Examination(tenantB.id(), ...));
           ScoringAnswer answerB = scoringAnswerRepository.save(
               new ScoringAnswer(examB.id(), tenantB.id(), ...));
           
           // Enqueue scoring for tenant-A
           scoringService.requestAiScoring(examA.id());
           
           // Process message
           waitForAsyncCompletion();
           
           // Verify: only tenant-A answer scored
           assertThat(scoringResultRepository.findByExaminationId(examA.id()))
               .hasSize(1);
           assertThat(scoringResultRepository.findByExaminationId(examB.id()))
               .isEmpty();  // Worker RLS-filtered tenant-B data
       }
       
       @Test
       void testWorkerWithoutHeaderFallbackToEmpty() {
           // Create global question (tenant_id = NULL)
           Question globalQ = questionRepository.save(
               new Question(null, "global", Visibility.SHARED));
           
           // Create tenant-scoped question
           Tenant tenantA = tenantRepository.save(new Tenant("A"));
           Question tenantQ = questionRepository.save(
               new Question(tenantA.id(), "tenant", Visibility.SHARED));
           
           // Enqueue without tenant_id header
           var message = new Message(...);
           message.getMessageProperties().getHeaders().clear();
           
           // Worker sets GUC = "" → only sees global (tenant_id IS NULL)
           worker.processScoringTask(message, channel, payload);
           
           // Verify: only global question processed
           assertThat(processedQuestions).contains(globalQ)
               .doesNotContain(tenantQ);
       }
   }
   ```

6. Documentation:
   ```java
   /**
    * @implNote Async workers run outside request context.
    *           Must extract tenant_id from message header and set GUC.
    *           If no header, GUC = "" (platform/NULL scope).
    */
   abstract class TenantAwareMessageConsumer { ... }
   ```

7. Cảnh báo cho future `@Scheduled` jobs:
   ```java
   // WARNING: Future @Scheduled jobs must NOT run async without tenant context.
   // If adding a scheduled task:
   // 1. Run within @Transactional + mock CurrentUserContext via SecurityContextHolder
   // 2. Or explicitly set GUC before querying app data
   // Running without GUC = RLS filters to 0 rows (fail-closed).
   ```

## Success Criteria

- `TenantAwareMessageConsumer` base class với `withTenantContext()` method
- `AiScoringWorker` & `EmailWorker` extract `tenant_id` header
- Header value: UUID string (tenant) or "" (platform)
- GUC set: `app.current_tenant` + `app.is_platform` via bind parameters
- Test: worker sees correct tenant data
- Test: worker doesn't see other tenant data
- Test: no header → worker sees platform data only
- Fallback: empty header → GUC = "" (empty string, not null, not "PLATFORM")

## Quality and Testing State

- Quality gate: chưa chạy
- Testing: chưa bắt đầu

## Session Notes

_(trống)_
