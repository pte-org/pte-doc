# Sequence Diagrams — APTIS LMS

## Sequence Diagrams

### Flow: Tenant-scoped login and refresh rotation

```mermaid
sequenceDiagram
    actor User
    participant API
    participant Tenant
    participant IAM
    participant DB
    User->>API: POST /api/v1/auth/login on tenant host
    API->>Tenant: resolve host to tenant context
    Tenant-->>API: tenant_id
    API->>IAM: authenticate(email, password, tenant_id)
    IAM->>DB: verify user + roles + bcrypt hash
    DB-->>IAM: scoped identity
    IAM->>DB: store refresh token hash
    IAM-->>User: access token + rotating refresh token
```

### Flow: Per-answer persistence with stale-write protection

```mermaid
sequenceDiagram
    actor Student
    participant Client
    participant API
    participant Delivery
    participant DB
    Student->>Client: change answer
    Client->>API: PATCH answer {sequence_number}
    API->>Delivery: saveAnswer command
    Delivery->>DB: conditional upsert if sequence is newer
    alt accepted
        DB-->>Client: 200 saved + server version
    else stale or part closed
        DB-->>Client: 409 current state
        Client->>Client: reconcile without overwriting newer answer
    end
```

### Flow: Disconnect and resume

```mermaid
sequenceDiagram
    actor Student
    participant Client
    participant API
    participant DB
    Client-xAPI: connectivity lost
    Client->>Client: buffer unacknowledged answers/audio
    Client->>API: reconnect + GET active attempt
    API->>DB: load attempt, answers, timer, shuffle seed
    DB-->>API: server-authoritative snapshot
    API-->>Client: snapshot + remaining time
    Client->>Client: reconcile buffered sequence numbers
    Client->>API: flush newer unacknowledged writes
```

### Flow: Submission and asynchronous scoring

```mermaid
sequenceDiagram
    actor Student
    participant API
    participant DB
    participant Queue
    participant Worker
    participant AI
    participant Teacher
    Student->>API: POST attempt/finalize
    API->>DB: transaction: submit + outbox event
    API-->>Student: 202 results pending
    Queue->>Worker: scoring job
    Worker->>DB: auto-score Reading/Listening
    Worker->>AI: STT then LLM via adapters
    AI-->>Worker: structured draft
    Worker->>DB: persist non-visible draft
    Worker-->>Teacher: review notification
    Teacher->>API: confirm/override score
    API->>DB: persist final result
```

### Flow: Live monitor across horizontally scaled API nodes

```mermaid
sequenceDiagram
    participant Student
    participant API1
    participant Redis
    participant API2
    participant Coordinator
    Student->>API1: answer/progress/violation event
    API1->>Redis: publish session event
    Redis-->>API2: fan-out event
    API2-->>Coordinator: WebSocket update
    Coordinator->>API2: extend time with reason
    API2->>Redis: publish timer changed
    Redis-->>API1: timer event
    API1-->>Student: authoritative time update
```

### Flow: Provider failure and manual-review fallback

```mermaid
sequenceDiagram
    participant Worker
    participant Queue
    participant Provider
    participant DB
    participant Teacher
    Queue->>Worker: scoring job
    Worker->>Provider: STT/LLM request
    Provider--xWorker: timeout, rate limit, or invalid output
    Worker->>Queue: retry with exponential backoff
    Queue->>Worker: final retry
    Provider--xWorker: permanent failure
    Worker->>DB: mark provider failure + manual review priority
    Worker-->>Teacher: actionable fallback notification
```
