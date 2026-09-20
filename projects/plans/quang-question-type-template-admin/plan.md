# Plan: Question Type Catalog + Question Template Admin

Status: Implemented in the working tree; verification recorded, no commit or push performed
Date: 2026-09-19
Scope: `pte-api` + `pte-web` + `@pte/api-client`
Primary actors: Platform Admin, Platform Author
Related areas: itembank question authoring, score template administration, vendor-web Content navigation

## Objective

Chuyển Question Type thành catalog được quản lý trong database và dùng chung cho:

1. Màn hình Question Types: admin có thể xem, tạo, sửa, bật/tắt và xóa mềm question type.
2. Màn hình Question Templates: admin có thể tạo/sửa/xóa template theo lifecycle DRAFT/ACTIVE/RETIRED.
3. Mapping item trong template: chọn Section trước, sau đó task type dropdown chỉ hiển thị các type đang active thuộc section đó.
4. Không còn import JSON trong luồng quản trị sau khi hoàn tất việc chuyển dữ liệu; dữ liệu mới được tạo qua giao diện.

## Scope decisions

- Database là source of truth cho các type mà Question Bank và Template Editor sử dụng.
- Backend cung cấp danh sách 23 PTE task code chuẩn từ `PteTaskType` qua endpoint `GET /api/v1/question-types/supported`. Đây là vocabulary để admin chọn khi tạo, không phải seed data và không thay thế catalog persisted.
- Migration `V37__question_type_catalog.sql` không được thêm `INSERT`. Admin phải vào UI tạo từng type; không có direct API import và không có JSON import UI.
- Vì question entity đang lưu `PteTaskType`, create Question Type chỉ nhận các code chuẩn mà backend hỗ trợ. Section, scored và authoring requirements canonical được backend suy ra từ task code.
- Question Type delete là soft delete: `deleted = true`, `active = false`. Metadata của type đã bị xóa vẫn được đọc cho validation/delivery của question cũ; type không còn xuất hiện trong danh sách active để tạo question/template mới.
- Score Template chỉ cho phép chỉnh sửa toàn bộ item list khi còn DRAFT. ACTIVE/RETIRED immutable; chỉ DRAFT được delete.
- Section và task type trong scoretemplate vẫn là string để giữ ranh giới module; UI dùng persisted Question Type catalog để lọc và mapping.
- Export JSON của template vẫn tồn tại; chỉ các chức năng Import JSON và các import DTO/API tương ứng bị loại bỏ.

## Phases

- [x] Phase 1: Persisted Question Type catalog và CRUD API/UI.
- [x] Phase 2: Question Template CRUD, Section-first mapping và loại bỏ Import JSON.
- [x] Phase 3: Verification, review fixes và handoff notes.

Chi tiết từng phase nằm trong:

- [phase-01-question-type-catalog-crud.md](phase-01-question-type-catalog-crud.md)
- [phase-02-question-template-crud-and-section-mapping.md](phase-02-question-template-crud-and-section-mapping.md)
- [phase-03-verification-and-handoff.md](phase-03-verification-and-handoff.md)

## Backend contract

### Question Types

All endpoints are protected by `PLATFORM_ADMIN` or `PLATFORM_AUTHOR`:

```text
GET    /api/v1/question-types?activeOnly=true|false
GET    /api/v1/question-types/supported
GET    /api/v1/question-types/{publicId}
POST   /api/v1/question-types
PUT    /api/v1/question-types/{publicId}
DELETE /api/v1/question-types/{publicId}
```

Create request fields:

```text
code, displayName, shortName, section, displayOrder, active
```

The server normalizes the code to uppercase, verifies it against `PteTaskType`, validates that the requested section matches the canonical section, and derives `scored` plus all canonical authoring flags.

### Question Templates

Template mutation endpoints remain `PLATFORM_ADMIN` only:

```text
GET    /api/v1/score-templates
POST   /api/v1/score-templates                 # create empty DRAFT
GET    /api/v1/score-templates/{publicId}
POST   /api/v1/score-templates/{publicId}/clone
PUT    /api/v1/score-templates/{publicId}/items
DELETE /api/v1/score-templates/{publicId}      # DRAFT only
POST   /api/v1/score-templates/{publicId}/activate
```

## Admin UI behavior

- Content navigation order is `Question Bank` → `Question Types` → `Question Templates`.
- `/admin/question-types` has `+ Create question type`, row-level `Edit`, and row-level `Delete` actions.
- Create Question Type selects a supported task code, includes a required Section field, auto-fills display metadata, and shows canonical requirements before saving.
- Edit preserves the stable task code and section mapping; presentation, active state, display order and authoring flags can be curated.
- `/admin/question-template` has `Create template`, `Edit/View`, `Clone to new draft`, and `Delete` for DRAFT rows.
- In a template editor, the add flow selects Section first. The task dropdown is filtered to active Question Type rows in that Section. Existing rows have the same Section-first/task-type mapping controls.
- The old file picker, JSON parser, import mutation, import DTOs and import endpoints were removed.

## Data onboarding procedure

The standard template table contains 22 scored rows; the backend supported vocabulary contains 23 task codes because `PERSONAL_INTRODUCTION` is also a supported question type. To populate a local database:

1. Open `/admin/question-types` as a platform admin/author.
2. Click `Create question type`.
3. Select one supported task type and confirm its Section.
4. Review display name, short name, order and availability, then save.
5. Repeat for the required standard types.
6. Open `/admin/question-template`, create an empty DRAFT, choose a Section and add the persisted types from the filtered dropdown.

No seed script, migration insert, direct import API or JSON import is required by this flow.

## Verification summary

- Targeted backend tests: 10 tests passed (`QuestionTypeServiceTest` + `QuestionTypeControllerSecurityTest`).
- `corepack pnpm --filter vendor-web build`: passed, including TypeScript and static generation.
- `@pte/api-client` and `@pte/ui` typecheck: passed during focused review checks.
- `vendor-web` lint: 0 errors; two existing warnings remain outside this feature (`PlanCatalogView` unused `Badge`, `QuestionEditorForm` `<img>` warning).
- Targeted Prettier check: passed.
- `git diff --check`: no whitespace errors; only normal CRLF conversion warnings were reported.
- Full backend suite, API-client Vitest suite and browser E2E were not completed. The API-client Vitest attempt was blocked by Windows `EPERM` while Vitest tried to create a temporary `ssr` directory.

## Working-tree and release boundary

- No commit, push, deployment or production data import was performed.
- Existing unrelated worktree changes in commercialization, dashboard, tenant-web and shared UI files were preserved and not reset.
- This record describes the Question Type/Question Template scope; unrelated dirty files are not treated as part of this feature.
- The implementation is code-complete for the requested admin flow, but a real authenticated browser walkthrough and full release verification remain follow-up gates.
