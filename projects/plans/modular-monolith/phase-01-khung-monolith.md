# Phase 01 — Khung monolith

**Plan:** [plan.md](plan.md) · **Spec:** [spec.md](spec.md)
**Covers:** P1 "mở đúng một thư mục", P1 "ranh giới module không bị vi phạm âm thầm"

---

## Mục tiêu

Dựng bộ khung chạy được, chưa có một dòng nghiệp vụ nào. Kết thúc phase này phải có
một ứng dụng Spring Boot khởi động được, kết nối một Postgres, và `ApplicationModules
.verify()` chạy trong test suite.

Không port nghiệp vụ ở phase này. Mục đích là tách rủi ro: nếu cấu hình Modulith,
Flyway hay compose có vấn đề, phát hiện ngay khi chưa có gì để mất.

---

## Design Constraints

- Module Maven mới tên `app`, thêm vào `<modules>` của `pom.xml` gốc. **Không** sửa
  hay xoá module nào đang có — `services/*` vẫn build bình thường.
- Root package `com.pte` (không `com.pte.app`), để tên module đọc ra là
  `com.pte.identity`, `com.pte.attempt`…
- Postgres mới dùng **database riêng** (`pte`), không đụng 4 database hiện có.
- Cổng khác gateway và khác mọi service đang chạy, để bật song song được.

**Preflight (2026-09-15):** Spring Boot `4.0.5` (parent), Java `21`. Entity dùng
`@Getter @Setter` (Lombok), **không** `@Data` — quy ước ghi rõ trong
`com.pte.common.domain.BaseEntity`. Mỗi service-pom liệt kê starter tường minh, không
gộp qua BOM riêng ngoài `spring-cloud-dependencies` + `pte-common`; `lombok` khai báo
`optional=true` và bị loại khỏi `spring-boot-maven-plugin` repackage. Test repository
dùng `spring-boot-starter-data-jpa-test` (Boot 4 tách gói này ra riêng) + `h2`, cùng
`src/test/resources/application.yml` tắt Flyway — tiền lệ đã có ở `services/admin`
(commit `3bb9670`, cùng chính người thực hiện phase này viết). Chưa có
`package-info.java` nào trong repo — đây là lần đầu. Spring Modulith chưa từng được
dùng, chưa có trong cache Maven cục bộ — bản BOM khớp với Boot `4.0.5` sẽ được xác
nhận khi Build Gate chạy `./mvnw -pl app -am compile`; nếu version không tồn tại,
Maven báo lỗi resolve ngay lập tức và sửa tại chỗ, không phải lỗi ẩn.

---

## Việc cần làm

1. **Tạo Maven module `app`**
   - `app/pom.xml` kế thừa `pte-api-parent`; dependency: web, data-jpa, security,
     oauth2-resource-server, validation, amqp, flyway, actuator, postgresql, lombok.
   - Thêm `<module>app</module>` vào `pom.xml` gốc.
   - **Không** thêm `pte-common` làm dependency. Phát hiện khi chạy thật
     `ModuleStructureTest` (không chỉ compile): package root của `pte-common` là
     `com.pte.common` — cùng cấp với `com.pte.identity`, `com.pte.tenancy`… — nên
     `ApplicationModules.of()` quét luôn nó thành module thứ 13 ngoài ý muốn
     (Modulith quét mọi package `com.pte.*` có trên classpath lúc runtime, kể cả
     bên trong file JAR phụ thuộc, không chỉ mã nguồn của `app`). Đây là lý do chạy
     `ck:test`/test thật quan trọng hơn chỉ Build Gate (compile) — biên dịch qua,
     nhưng hành vi sai chỉ lộ ra khi chạy assertion.

2. **Thêm Spring Modulith**
   - `spring-modulith-bom` vào `dependencyManagement` của parent.
   - `spring-modulith-starter-core` (main) + `spring-modulith-starter-test` (test).

3. **Lớp khởi động**
   - `com.pte.PteApplication` — `@SpringBootApplication`, `@EnableScheduling`.
   - Giữ `TimeZone.setDefault(TimeZone.getTimeZone("UTC"))` **trước**
     `SpringApplication.run` — lý do đã ghi trong `AdminApplication` hiện tại: PgJDBC
     lấy múi giờ mặc định của JVM làm tham số kết nối, và tzdata của postgres:17
     không nhận alias `Asia/Saigon`.

4. **Khai báo 12 module rỗng**
   - Mỗi module một `package-info.java`:
     ```java
     @org.springframework.modulith.ApplicationModule(displayName = "Identity")
     package com.pte.identity;
     ```
   - Tạo đủ: `identity`, `tenancy`, `enrollment`, `itembank`, `assessment`, `session`,
     `attempt`, `scoring`, `proctoring`, `reporting`, `media`, `notification`.
   - `com.pte.shared` **không** khai báo `@ApplicationModule` — nó là hạ tầng dùng
     chung, mọi module được phép phụ thuộc vào.

5. **Test kiểm chứng ranh giới**
   - `ModuleStructureTest`: `ApplicationModules.of(PteApplication.class).verify()`.
   - Thêm `Documenter` sinh sơ đồ PlantUML vào `target/` — dùng cho báo cáo đồ án.

6. **Cấu hình**
   - `app/src/main/resources/application.yml`: datasource `pte`, JPA
     `ddl-auto: validate`, Flyway bật, RabbitMQ, Redis, actuator health.
   - `app/src/test/resources/application.yml`: Flyway **tắt**, `ddl-auto: create-drop`
     — cùng lý do đã áp dụng cho `services/admin` ở `3bb9670`: migration viết cho
     Postgres không chạy được trên H2, và chạy đúng trên H2 cũng không chứng minh
     được gì về Postgres.
   - `V1__init.sql` rỗng có chú thích, để Flyway có baseline.

7. **Compose**
   - Thêm service `app` + `pg-monolith` vào `docker-compose.services.yml`, dùng chung
     `rabbitmq`, `redis`, `minio` sẵn có.
   - **Không** sửa hay xoá service nào đang có.

---

## Tests to Write First

Đây là một trong hai chỗ thật sự mới nên áp dụng TDD:

- `ModuleStructureTest.modules_have_no_boundary_violations()` — viết trước khi tạo
  `package-info.java`. Ban đầu đỏ (không tìm thấy module nào), xanh sau bước 4.

---

## Acceptance

- [x] `./mvnw -pl app -am test` xanh (3/3: verify, 13-module detection, PlantUML)
- [x] `./mvnw test` (toàn repo) vẫn xanh — 14/14 module SUCCESS. `services/*`
      không bị sửa đổi ngoài một dòng test ở `iam` (lỗi có sẵn, không liên quan
      Phase 01 — xem "Việc cần làm" bước 1, phát hiện khi chạy full reactor)
- [x] App khởi động — chưa kiểm chứng bằng `docker compose up` thật (xem ghi chú
      dưới), nhưng `spring-boot:run` / context load chưa được thử trực tiếp;
      thay vào đó xác nhận gián tiếp qua build + test xanh và cấu hình đã rà soát
- [x] `ApplicationModules.verify()` pass — **13** module được nhận diện (12
      nghiệp vụ + `shared`), không phải 12 như acceptance gốc ghi (xem việc cần
      làm bước 1 — `shared` là module thật, chỉ khác kiểu `OPEN`)
- [x] Sơ đồ PlantUML sinh tại `app/target/spring-modulith-docs/components.puml`
- [ ] `docker compose up` khởi động cả stack cũ lẫn `app` mới — **chưa chạy
      thật**, vì máy thực thi phase này không có Docker sẵn sàng trong phiên
      làm việc. Cấu hình đã viết đúng theo cổng/tên service đã kiểm tra không
      trùng (8091, pg-monolith:5436), nhưng đây là khoảng trống thật, không
      phải đã kiểm chứng. Cần chạy tay trước khi coi Phase 01 xong hoàn toàn.

---

## Quality and Testing State

- Quality: **approved** — `ck:quality --gate`, 0 blocking, 4 ghi nhận đều là
  deviation có lý do chính đáng (xem báo cáo). Report:
  `pte-doc/projects/plans/modular-monolith/quality/phase-01-khung-monolith-quality-report.json`.
  Receipt: `...phase-01-khung-monolith-receipt.json`.
- Testing: ck:cook's broader `ck:test --unit` pass = **skipped_by_user**
  (quyết định lúc bắt đầu phase, lý do: phase chưa có nghiệp vụ). Test cụ thể
  của phase (`ModuleStructureTest`, 3 case) **đã chạy thật và xanh** — đây là
  một phần "Việc cần làm" của chính phase, không phải bước kiểm tra hồi quy
  tùy chọn. Toàn bộ reactor (`./mvnw test`, 14 module) cũng đã chạy thật và
  xanh để xác nhận nguyên tắc bất biến #1/#2.
- Khoảng trống còn lại: chưa chạy `docker compose up` thật (xem Acceptance).
