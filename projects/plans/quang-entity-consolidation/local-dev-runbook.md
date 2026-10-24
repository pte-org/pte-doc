# Local dev runbook — profile `local-schema`

Giai đoạn consolidation: Hibernate dựng schema, Flyway tắt. Flyway V1 chỉ sinh một lần ở phase 11.
Mọi lệnh chạy từ `D:\GitHub\pte-org\pte-api`. Không dùng cho môi trường đã deploy.

## Bật profile

1. Trong `.env.local` (file ignore, không commit) thêm dòng `APP_SPRING_PROFILES=local-schema`.
2. Compose truyền giá trị đó vào `SPRING_PROFILES_ACTIVE` của container `app`
   (`docker-compose.services.yml`). Mặc định rỗng → không có profile → `ddl-auto: validate` + Flyway.

## Dựng lại DB trống (khi lệch schema hoặc sau thay đổi mô hình lớn)

`ddl-auto: update` của Hibernate 7 không chạy được trên DB do Flyway dựng (đòi nới cột `varchar(32)` → `255` và bị 3 view
chặn), nên dùng DB do chính Hibernate dựng.

```powershell
# 1) Sao lưu (ra ngoài repo)
docker exec pte-postgres pg_dump -U <APP_DB_USER> -d pte > $HOME\pte-local-backup-<yyyymmdd>.sql
# 2) Dừng app, drop và tạo lại DB (không đụng volume Caddy)
docker stop pte-platform-app-1
docker exec pte-postgres psql -U <APP_DB_USER> -d postgres -c "drop database pte with (force)" -c "create database pte owner \"<APP_DB_USER>\""
# 3) Build và chạy app với profile local-schema
docker compose --env-file .env.local -f docker-compose.yml -f docker-compose.services.yml up -d --no-deps --build app
```

Lần boot đầu: Hibernate tạo bảng → `db/dev-seed/000-postgres-objects.sql` (extension, function, trigger, view, exclusion
constraint, partial unique index) → `010-reference-data.sql` (task type, runtime contract, score template, settings) →
`020-local-accounts.sql` (`admin@test.local`). Các file idempotent, boot lại không lỗi.

## Gate cuối mỗi phase

- `docker inspect pte-platform-app-1 --format '{{.State.Health.Status}}'` → `healthy`.
- `POST http://localhost:8091/api/v1/auth/login` với `admin@test.local` thành công; từ phase 2 thêm `host.e2e@test.local`.
- Mật khẩu local dùng chung do người dùng cung cấp (xem memory `local-test-accounts`); seed chỉ lưu BCrypt hash.

## Lưu ý

- `db/dev-seed/*.sql` đi kèm jar nhưng chỉ chạy khi profile `local-schema` bật; hosted compose không đặt profile này.
- Seed dùng `ON CONFLICT DO NOTHING` / `WHERE NOT EXISTS`; mỗi phase cập nhật phần của mình khi bảng đổi.
- Flyway V1 (phase 11): dựng DB trống bằng profile này, `pg_dump --schema-only --no-owner --no-privileges`, ghép đối tượng Postgres
  và seed, đặt vào `db/migration/V1__baseline.sql`, chuyển 126 migration cũ sang `db/legacy-migration/`.
