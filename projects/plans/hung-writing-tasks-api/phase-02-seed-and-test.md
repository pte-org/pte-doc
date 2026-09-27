# Phase 2: Seed & Manual Test Guide

## Prerequisites

All services running (`docker compose up` or individual services). You'll need two tokens:
- `<DEV_PLATFORM_ADMIN_TOKEN>` — has `PLATFORM_ADMIN` role, used for authoring commands
- `<DEV_STUDENT_TOKEN>` — has `STUDENT` role, used for attempt flow

## Seed Step 1 — Create SWT Question

```bash
curl -X POST http://localhost:8083/api/authoring/questions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <DEV_PLATFORM_ADMIN_TOKEN>" \
  -d '{
    "pteTaskType": "SUMMARIZE_WRITTEN_TEXT",
    "visibility": "SHARED",
    "title": "[DEV] Urban Public Health — SWT",
    "promptText": "Urban population growth in the twentieth century placed enormous strain on public health systems. Municipal authorities were forced to expand water supply networks, build sewage treatment plants, and establish municipal hospitals. These investments were partly driven by periodic cholera and typhoid outbreaks that killed thousands. By mid-century, many cities had established public health departments with sweeping powers to inspect buildings, quarantine residents, and mandate vaccinations. The long-term effect was a sustained decline in infectious disease mortality across all age groups.",
    "referenceAnswerText": "Urban growth drove major public health investments, leading to a sustained decline in infectious disease mortality.",
    "minWordCount": 5,
    "maxWordCount": 75
  }'
```

**Expected:** HTTP 201, body có `"publicId":"<some-UUID>"`. Copy UUID đó — gọi là `<SWT_UUID>`.

---

## Seed Step 2 — Create Essay Question

```bash
curl -X POST http://localhost:8083/api/authoring/questions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <DEV_PLATFORM_ADMIN_TOKEN>" \
  -d '{
    "pteTaskType": "WRITE_ESSAY",
    "visibility": "SHARED",
    "title": "[DEV] Technology and Employment — Essay",
    "promptText": "Technology has replaced many jobs that used to be done by humans. To what extent do you agree or disagree with this statement? Give reasons for your answer and include any relevant examples from your own knowledge.",
    "minWordCount": 200,
    "maxWordCount": 300
  }'
```

**Expected:** HTTP 201, body có `"publicId":"<some-UUID>"`. Copy UUID đó — gọi là `<ESSAY_UUID>`.

---

## Seed Step 3 — Create Blueprint

```bash
curl -X POST http://localhost:8083/api/authoring/blueprints \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <DEV_PLATFORM_ADMIN_TOKEN>" \
  -d '{
    "title": "[DEV] Writing Tasks Smoke Blueprint",
    "status": "PUBLISHED",
    "items": [
      { "questionPublicId": "<SWT_UUID>", "section": "WRITING", "orderIndex": 1 },
      { "questionPublicId": "<ESSAY_UUID>", "section": "WRITING", "orderIndex": 2 }
    ]
  }'
```

**Expected:** HTTP 201, body có `"publicId":"<some-UUID>"`. Copy UUID đó — gọi là `<BLUEPRINT_UUID>`.

---

## Seed Step 4 — Create Pinned Snapshot

```bash
curl -X POST http://localhost:8083/api/authoring/snapshots/pin \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <DEV_PLATFORM_ADMIN_TOKEN>" \
  -d '{
    "blueprintPublicId": "<BLUEPRINT_UUID>",
    "items": [
      { "questionPublicId": "<SWT_UUID>", "orderIndex": 1 },
      { "questionPublicId": "<ESSAY_UUID>", "orderIndex": 2 }
    ]
  }'
```

**Expected:** HTTP 201, body có `"publicId":"<some-UUID>"`. Copy UUID đó — gọi là `<SNAPSHOT_UUID>`.

---

## Seed Step 5 — Create Exam Session

```bash
curl -X POST http://localhost:8083/api/scheduling/sessions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <DEV_STUDENT_TOKEN>" \
  -d '{
    "pinnedSnapshotPublicId": "<SNAPSHOT_UUID>",
    "studentPublicId": "<DEV_STUDENT_UUID>"
  }'
```

**Expected:** HTTP 201, body có `"publicId":"<some-UUID>"`. Copy UUID đó — gọi là `<SESSION_UUID>`.

---

## Test Step A — Start Attempt ( SWT )

```bash
curl -s -X POST http://localhost:8080/api/exam-delivery/attempts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <DEV_STUDENT_TOKEN>" \
  -d "{\"sessionPublicId\": \"<SESSION_UUID>\"}"
```

**Expected:**
- HTTP 200
- `taskType` = `"SUMMARIZE_WRITTEN_TEXT"`
- `minWordCount` = `5`, `maxWordCount` = `75`
- `responseSeconds` = `600`
- `prepSeconds` = `0`
- `options` = `[]` (empty — writing tasks have no options)

Copy `attemptPublicId` từ response — gọi là `<ATTEMPT_UUID>`.
Copy `pinnedItemPublicId` từ task trong response — gọi là `<SWT_PINNED_UUID>`.

**Fail if:** `taskType` missing, `minWordCount`/`maxWordCount` null, `responseSeconds` missing/0.

---

## Test Step B — Submit SWT Answer

```bash
curl -s -X POST "http://localhost:8080/api/exam-delivery/attempts/<ATTEMPT_UUID>/answers" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <DEV_STUDENT_TOKEN>" \
  -d "{\"pinnedItemPublicId\": \"<SWT_PINNED_UUID>\", \"payload\": \"Urban growth drove major public health investments, leading to a sustained decline in infectious disease mortality across all age groups.\"}"
```

**Expected:** HTTP 200, response trả về task tiếp theo (WRITE_ESSAY).

---

## Test Step C — Get Next Task (Essay)

```bash
curl -s -X GET "http://localhost:8080/api/exam-delivery/attempts/<ATTEMPT_UUID>/next-task" \
  -H "Authorization: Bearer <DEV_STUDENT_TOKEN>"
```

**Expected:**
- HTTP 200
- `taskType` = `"WRITE_ESSAY"`
- `minWordCount` = `200`, `maxWordCount` = `300`
- `responseSeconds` = `1200`
- `options` = `[]`

Copy `pinnedItemPublicId` từ response — gọi là `<ESSAY_PINNED_UUID>`.

**Fail if:** `taskType` = `"SUMMARIZE_WRITTEN_TEXT"` (still on SWT), or `minWordCount`/`maxWordCount` wrong.

---

## Test Step D — Submit Essay Answer

```bash
curl -s -X POST "http://localhost:8080/api/exam-delivery/attempts/<ATTEMPT_UUID>/answers" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <DEV_STUDENT_TOKEN>" \
  -d "{\"pinnedItemPublicId\": \"<ESSAY_PINNED_UUID>\", \"payload\": \"I strongly agree that technology has replaced many jobs. First, automation has eliminated repetitive manufacturing roles. Second, AI now handles customer service queries. Third, self-checkout machines have reduced retail staffing needs. In conclusion, while technology creates new jobs, its net effect on employment is significant and undeniable.\"}"
```

**Expected:** HTTP 200, `completed: true`, `task: null` (no more tasks).

---

## Test Step E — Verify correctAnswerText NOT leaked

Kiểm tra response ở Step A, C — đảm bảo không có trường nào chứa nội dung câu trả lời đúng.

**Expected:** Không có field `correctAnswerText` hay `referenceAnswerText` trong response.

---

## Checklist

| # | Check | Expected |
|---|-------|---------|
| 1 | Step 1 — SWT question created | HTTP 201, publicId returned |
| 2 | Step 2 — Essay question created | HTTP 201, publicId returned |
| 3 | Step 3 — Blueprint created | HTTP 201, includes 2 items |
| 4 | Step 4 — Pinned snapshot created | HTTP 201, pinnedItems include timing from task-timing.json |
| 5 | Step 5 — Session created | HTTP 201 |
| 6 | Step A — Start attempt | SWT, 5/75 words, 600s, empty options |
| 7 | Step B — Submit SWT | HTTP 200, next task returned |
| 8 | Step C — Next task | WRITE_ESSAY, 200/300 words, 1200s, empty options |
| 9 | Step D — Submit essay | `completed: true`, `task: null` |
| 10 | Step E — Answer not leaked | No correctAnswerText in any response |
