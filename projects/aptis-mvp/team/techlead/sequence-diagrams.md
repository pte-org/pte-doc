# Sequence Diagrams — APTIS MVP (Host-Driven Exam Distribution)

## Sequence Diagrams

### Flow 1: Admin creates a Host account (happy path)

```mermaid
sequenceDiagram
    actor Admin
    participant Web
    participant API
    participant DB

    Admin->>Web: Fill org name + contact email, submit
    Web->>API: POST /admin/hosts {organizationName, contactEmail}
    API->>DB: SELECT host WHERE contact_email = ?
    DB-->>API: no match
    API->>API: generate random credential, hash it
    API->>DB: INSERT INTO host (..., credential_hash)
    DB-->>API: host row created
    API-->>Web: 201 {hostId, contactEmail, credentialPlaintext}
    Web-->>Admin: Show credential once (no second retrieval)
```

### Flow 2: Host uploads student roster — happy path

```mermaid
sequenceDiagram
    actor Host
    participant Web
    participant API
    participant XL as Excel Engine
    participant DB

    Host->>Web: Select .xlsx roster file, submit
    Web->>API: POST /host/imports {file}
    API->>XL: parse(file)
    XL-->>API: rows[]
    API->>DB: SELECT existing student_identifier WHERE host_id = ?
    DB-->>API: existing identifiers
    API->>API: validate each row (required fields, BR-004 uniqueness)
    API->>DB: INSERT INTO import_batch (host_id, status=VALIDATED)
    loop each valid row
        API->>API: generate random credential, hash it
        API->>DB: INSERT INTO student (..., credential_hash, credential_plaintext_pending, batch_id)
    end
    DB-->>API: batch + students created
    API-->>Web: 201 {batchId, createdCount, errorCount: 0}
    Web-->>Host: Show "{createdCount} students created, proceed to assign Exam"
```

### Flow 3: Host uploads student roster — error path (invalid/duplicate rows)

```mermaid
sequenceDiagram
    actor Host
    participant Web
    participant API
    participant XL as Excel Engine
    participant DB

    Host->>Web: Select .xlsx roster file, submit
    Web->>API: POST /host/imports {file}
    API->>XL: parse(file)
    XL-->>API: rows[]
    API->>DB: SELECT existing student_identifier WHERE host_id = ?
    DB-->>API: existing identifiers
    API->>API: validate each row
    Note over API: Row 3 missing full_name; Row 7 duplicates existing identifier
    API->>DB: INSERT INTO import_batch (host_id, status=PARTIAL)
    loop each valid row only
        API->>DB: INSERT INTO student (...)
    end
    API-->>Web: 201 {batchId, createdCount, errors: [{row:3, reason:"missing full_name"}, {row:7, reason:"duplicate identifier"}]}
    Web-->>Host: Show validation report — valid rows created, invalid rows listed with reasons
```

### Flow 4: Host assigns an Exam to a batch and generates the credential export

```mermaid
sequenceDiagram
    actor Host
    participant Web
    participant API
    participant XL as Excel Engine
    participant DB

    Host->>Web: Select assignable Exam for batch, confirm
    Web->>API: POST /host/imports/{batchId}/assign {examId}
    API->>DB: SELECT exam WHERE id = ? AND is_assignable = true
    DB-->>API: exam found
    API->>DB: UPDATE import_batch SET exam_id = ?
    API->>DB: SELECT students WHERE batch_id = ? (with credential_plaintext_pending)
    DB-->>API: student rows incl. pending plaintext
    API->>XL: generate({students, examName})
    XL-->>API: workbook blob
    API->>DB: INSERT INTO credential_export (batch_id, host_id, file_blob)
    API->>DB: UPDATE student SET credential_plaintext_pending = NULL WHERE batch_id = ?
    DB-->>API: committed
    API-->>Web: 200 {exportId, ready: true}
    Web-->>Host: "Export ready — download credentials"
```

### Flow 5: Host downloads the credential export

```mermaid
sequenceDiagram
    actor Host
    participant Web
    participant API
    participant DB

    Host->>Web: Click "Download credentials"
    Web->>API: GET /host/exports/{exportId}
    API->>DB: SELECT credential_export WHERE id = ?
    DB-->>API: export row {host_id, file_blob}
    API->>API: check export.host_id == jwt.host_id (BR-008)
    alt host mismatch
        API-->>Web: 403 Forbidden
        Web-->>Host: "Not authorized to access this export"
    else authorized
        API-->>Web: 200 application/xlsx {file_blob}
        Web-->>Host: File download starts
    end
```

### Flow 6: Student logs in, answers questions, submits, and views score

```mermaid
sequenceDiagram
    actor Student
    participant Web
    participant API
    participant DB

    Student->>Web: Submit username + credential
    Web->>API: POST /auth/login {username, credential}
    API->>DB: SELECT student WHERE username = ?
    DB-->>API: student row {credential_hash, exam_id}
    API->>API: verify credential hash
    API-->>Web: 200 {jwt}
    Web->>API: GET /student/exam (with jwt)
    API->>DB: SELECT exam_attempt WHERE student_id = ?
    alt no attempt yet
        API->>DB: INSERT INTO exam_attempt (student_id, exam_id, started_at)
    end
    DB-->>API: attempt + exam questions
    API-->>Web: 200 {questions[], attemptState}
    loop each answered question
        Student->>Web: Select option
        Web->>API: PUT /student/attempts/{id}/answers {questionId, optionId}
        API->>DB: UPSERT answer (attempt_id, question_id, selected_option_id)
    end
    Student->>Web: Click Submit
    Web->>API: POST /student/attempts/{id}/submit
    API->>DB: SELECT exam_attempt WHERE id = ?
    alt already submitted
        API-->>Web: 409 Conflict — already submitted
        Web-->>Student: Show existing score (no re-score)
    else not yet submitted
        API->>DB: SELECT answers + correct options for attempt
        API->>API: compute score (BR-007, multiple-choice only)
        API->>DB: UPDATE exam_attempt SET submitted_at = now(), score = ?
        DB-->>API: committed
        API-->>Web: 200 {score, total}
        Web-->>Student: Show immediate score
    end
```
