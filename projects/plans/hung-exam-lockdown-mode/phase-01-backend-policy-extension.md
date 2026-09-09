# Phase 1: Backend Policy Extension (LockdownMode)

**Status:** Ready
**Estimated effort:** 1 week
**Dependencies:** None

---

## Goal

Extend `ExamPolicy` entity in `scheduling` service with `LockdownMode` enum and field, update default policies per exam mode, and propagate the field through all DTOs to `exam-delivery` service's `AttemptTaskResponse`.

## Steps

### Step 1: Create LockdownMode Enum

**File:** `services/scheduling/src/main/java/com/pte/scheduling/domain/enums/LockdownMode.java`

```java
package com.pte.scheduling.domain.enums;

/**
 * Defines the exam lockdown enforcement level for desktop clients.
 * Pinned at StartAttempt; never re-fetched during an attempt's lifetime.
 */
public enum LockdownMode {
    /** No lockdown enforcement (PRACTICE mode default). */
    NONE,
    
    /** Warning-only mode - violations detected and reported but not blocked (MOCK_TEST default). */
    STANDARD,
    
    /** Strict enforcement - fullscreen mandatory, clipboard blocked, forbidden apps terminated (REAL_EXAM default). */
    STRICT
}
```

### Step 2: Add lockdownMode Field to ExamPolicy

**File:** `services/scheduling/src/main/java/com/pte/scheduling/domain/ExamPolicy.java`

Add import and field:

```java
import com.pte.scheduling.domain.enums.LockdownMode;

@Enumerated(EnumType.STRING)
@Column(name = "lockdown_mode")
private LockdownMode lockdownMode;
```

Update default policy methods:

```java
public static ExamPolicy practiceDefault() {
    return build(ReplayPolicy.unlimited(), false, false, 
                 AnswerIntegrityLevel.STANDARD, LockdownMode.NONE);
}

public static ExamPolicy mockTestDefault() {
    return build(ReplayPolicy.limited(3), true, false, 
                 AnswerIntegrityLevel.STANDARD, LockdownMode.STANDARD);
}

public static ExamPolicy realExamDefault() {
    return build(ReplayPolicy.limited(1), true, true, 
                 AnswerIntegrityLevel.STRICT, LockdownMode.STRICT);
}

private static ExamPolicy build(ReplayPolicy replayPolicy, boolean deviceCheckRequired,
                                 boolean proctorRequired, AnswerIntegrityLevel answerIntegrityLevel,
                                 LockdownMode lockdownMode) {
    ExamPolicy policy = new ExamPolicy();
    policy.setReplayPolicy(replayPolicy);
    policy.setDeviceCheckRequired(deviceCheckRequired);
    policy.setProctorRequired(proctorRequired);
    policy.setAnswerIntegrityLevel(answerIntegrityLevel);
    policy.setLockdownMode(lockdownMode);
    return policy;
}
```

Update `backfillLegacyDefaults()`:

```java
@PostLoad
void backfillLegacyDefaults() {
    if (replayPolicyType == null) {
        ExamPolicy fallback = mockTestDefault();
        this.replayPolicyType = fallback.replayPolicyType;
        this.replayPolicyLimit = fallback.replayPolicyLimit;
        this.deviceCheckRequired = fallback.deviceCheckRequired;
        this.proctorRequired = fallback.proctorRequired;
        this.answerIntegrityLevel = fallback.answerIntegrityLevel;
        this.lockdownMode = fallback.lockdownMode; // NEW
    }
}
```

### Step 3: Update DTOs in Scheduling Service

**File:** `services/scheduling/src/main/java/com/pte/scheduling/dto/response/ExamPolicyResponse.java`

Add field to record:

```java
public record ExamPolicyResponse(
        ReplayPolicyResponse replayPolicy,
        Boolean deviceCheckRequired,
        Boolean proctorRequired,
        AnswerIntegrityLevel answerIntegrityLevel,
        LockdownMode lockdownMode  // NEW
) {
}
```

**File:** `services/scheduling/src/main/java/com/pte/scheduling/dto/request/PatchExamPolicyRequest.java`

Add optional field:

```java
public record PatchExamPolicyRequest(
        @Valid ReplayPolicyRequest replayPolicy,
        Boolean deviceCheckRequired,
        Boolean proctorRequired,
        AnswerIntegrityLevel answerIntegrityLevel,
        LockdownMode lockdownMode  // NEW - optional override
) {
}
```

Update mapper in `SessionService.patchPolicy()`:

```java
if (request.lockdownMode() != null) {
    policy.setLockdownMode(request.lockdownMode());
}
```

#### CreateSessionRequest — Teacher Override (FR-07)

**File:** `services/scheduling/src/main/java/com/pte/scheduling/dto/request/CreateSessionRequest.java`

Add optional 6th field for teacher override:

```java
public record CreateSessionRequest(
        @NotBlank String name,
        @NotNull UUID snapshotPublicId,
        @NotNull @Future Instant opensAt,
        @NotNull Instant closesAt,
        /** Null defaults to MOCK_TEST. */
        ExamMode examMode,
        /** Optional teacher override — null means use ExamMode default.
         *  Validation: STRICT is not allowed when examMode is PRACTICE. */
        LockdownMode lockdownMode  // NEW
) {
}
```

Update `SessionService.create()` to honor override:

```java
ExamMode mode = request.examMode() != null ? request.examMode() : ExamMode.MOCK_TEST;
ExamPolicy policy = ExamPolicy.forMode(mode);

// Teacher override: lockdownMode takes precedence if set
if (request.lockdownMode() != null) {
    if (mode == ExamMode.PRACTICE && request.lockdownMode() == LockdownMode.STRICT) {
        throw new IllegalArgumentException(
                "LockdownMode.STRICT is not allowed for PRACTICE exams");
    }
    policy.setLockdownMode(request.lockdownMode());
}

session.setPolicy(policy);
```

Add 3 test cases to `SessionServiceLockdownTest`:
- `create_withTeacherOverride_lockdownModeOverridesDefault` — PRACTICE override to STANDARD
- `create_withTeacherOverride_strictOnRealExam_usesStrict` — REAL_EXAM explicit STRICT
- `create_withTeacherOverride_strictOnPractice_rejected` — PRACTICE + STRICT → 400 reject

### Step 4: Propagate Through Exam-Delivery Service

**File:** `services/exam-delivery/src/main/java/com/pte/examdelivery/client/dto/SchedulingEntitlementResponse.java`

Add to record:

```java
public record SchedulingEntitlementResponse(
        // ... existing fields
        Boolean proctorRequired,
        String answerIntegrityLevel,
        String lockdownMode  // NEW - String to match serialization pattern
) {
}
```

**File:** `services/exam-delivery/src/main/java/com/pte/examdelivery/domain/PinnedExamSnapshot.java`

Add column:

```java
@Column(name = "lockdown_mode", length = 20)
private String lockdownMode;
```

Update `SnapshotPinService.pin()`:

```java
pinned.setLockdownMode(entitlement.policy().lockdownMode());
```

**File:** `services/exam-delivery/src/main/java/com/pte/examdelivery/dto/response/AttemptTaskResponse.java`

Add field to expose to client:

```java
public record AttemptTaskResponse(
        String attemptPublicId,
        String attemptStatus,
        boolean completed,
        TaskView task,
        String encryptionPublicKey,
        String lockdownMode  // NEW
) {
}
```

Update `AttemptMapper.toTaskResponse()`:

```java
public AttemptTaskResponse toTaskResponse(ExamAttempt attempt, PinnedItemView item, 
                                          TimerState timer, int totalTasks) {
    return new AttemptTaskResponse(
        // ... existing fields
        attempt.getSnapshot().getLockdownMode()  // NEW
    );
}
```

### Step 5: Database Migration

**File:** `services/scheduling/src/main/resources/db/migration/V{next}__add_lockdown_mode_to_exam_policy.sql`

```sql
-- Add lockdown_mode column to exam_sessions table
-- (ExamPolicy is @Embeddable, so columns live on exam_sessions)
ALTER TABLE exam_sessions 
ADD COLUMN lockdown_mode VARCHAR(20) DEFAULT 'NONE';

-- Backfill existing rows based on their exam_mode
UPDATE exam_sessions 
SET lockdown_mode = CASE 
    WHEN exam_mode = 'PRACTICE' THEN 'NONE'
    WHEN exam_mode = 'MOCK_TEST' THEN 'STANDARD'
    WHEN exam_mode = 'REAL_EXAM' THEN 'STRICT'
    ELSE 'NONE'
END
WHERE lockdown_mode IS NULL;

-- Make NOT NULL after backfill
ALTER TABLE exam_sessions 
ALTER COLUMN lockdown_mode SET NOT NULL;
```

**File:** `services/exam-delivery/src/main/resources/db/migration/V{next}__add_lockdown_mode_to_pinned_snapshot.sql`

```sql
-- Add lockdown_mode to pinned_exam_snapshots
ALTER TABLE pinned_exam_snapshots 
ADD COLUMN lockdown_mode VARCHAR(20);

-- Backfill existing snapshots (conservative: default to NONE for legacy)
UPDATE pinned_exam_snapshots 
SET lockdown_mode = 'NONE'
WHERE lockdown_mode IS NULL;
```

### Step 6: Unit Tests

**Test file:** `services/scheduling/src/test/java/com/pte/scheduling/domain/ExamPolicyTest.java`

```java
@Test
void practiceDefaultHasNoLockdown() {
    ExamPolicy policy = ExamPolicy.practiceDefault();
    assertThat(policy.getLockdownMode()).isEqualTo(LockdownMode.NONE);
}

@Test
void mockTestDefaultHasStandardLockdown() {
    ExamPolicy policy = ExamPolicy.mockTestDefault();
    assertThat(policy.getLockdownMode()).isEqualTo(LockdownMode.STANDARD);
}

@Test
void realExamDefaultHasStrictLockdown() {
    ExamPolicy policy = ExamPolicy.realExamDefault();
    assertThat(policy.getLockdownMode()).isEqualTo(LockdownMode.STRICT);
}

@Test
void backfillLegacyDefaultsIncludesLockdownMode() {
    ExamPolicy policy = new ExamPolicy();
    // Trigger @PostLoad
    policy.backfillLegacyDefaults();
    assertThat(policy.getLockdownMode()).isEqualTo(LockdownMode.STANDARD);
}
```

**Test file:** `services/scheduling/src/test/java/com/pte/scheduling/service/SessionServiceTest.java`

```java
@Test
void patchPolicyUpdatesLockdownMode() {
    // Setup: create session with PRACTICE mode (lockdownMode = NONE)
    ExamSession session = createSession(ExamMode.PRACTICE);
    
    // Patch to STRICT
    PatchExamPolicyRequest request = new PatchExamPolicyRequest(
        null, null, null, null, LockdownMode.STRICT
    );
    
    sessionService.patchPolicy(session.getPublicId(), request, hostCaller());
    
    ExamSession updated = sessionRepository.findByPublicId(session.getPublicId()).orElseThrow();
    assertThat(updated.getPolicy().getLockdownMode()).isEqualTo(LockdownMode.STRICT);
}
```

**Test file:** `services/exam-delivery/src/test/java/com/pte/examdelivery/service/SnapshotPinServiceTest.java`

```java
@Test
void pinCopiesLockdownModeFromEntitlement() {
    SchedulingEntitlementResponse entitlement = new SchedulingEntitlementResponse(
        // ... existing fields
        "STRICT"  // lockdownMode
    );
    
    PinnedExamSnapshot pinned = snapshotPinService.pin(attempt, sessionPublicId, studentPublicId);
    
    assertThat(pinned.getLockdownMode()).isEqualTo("STRICT");
}
```

### Step 7: Integration Test (End-to-End DTO Flow)

**Test file:** `services/exam-delivery/src/test/java/com/pte/examdelivery/service/AttemptServiceIntegrationTest.java`

```java
@Test
void startAttemptReturnsLockdownModeForStrictSession() {
    // Given: REAL_EXAM session (lockdownMode = STRICT)
    UUID sessionPublicId = seedRealExamSession();
    UUID studentPublicId = createStudent();
    enrollStudent(sessionPublicId, studentPublicId);
    
    // When: StartAttempt
    AttemptTaskResponse response = attemptService.startOrResume(
        sessionPublicId, true, testCaller(studentPublicId)
    );
    
    // Then: lockdownMode present in response
    assertThat(response.lockdownMode()).isEqualTo("STRICT");
}

@Test
void startAttemptReturnsNoneLockdownForPracticeSession() {
    UUID sessionPublicId = seedPracticeSession();
    UUID studentPublicId = createStudent();
    enrollStudent(sessionPublicId, studentPublicId);
    
    AttemptTaskResponse response = attemptService.startOrResume(
        sessionPublicId, true, testCaller(studentPublicId)
    );
    
    assertThat(response.lockdownMode()).isEqualTo("NONE");
}
```

## Acceptance Criteria

- [ ] `LockdownMode` enum created with NONE, STANDARD, STRICT values
- [ ] `ExamPolicy` has `lockdownMode` field with appropriate defaults per exam mode
- [ ] Database migration adds `lockdown_mode` column and backfills existing rows
- [ ] `PatchExamPolicyRequest` accepts optional `lockdownMode` override
- [ ] `SchedulingEntitlementResponse` carries `lockdownMode` to exam-delivery
- [ ] `PinnedExamSnapshot` stores `lockdownMode` immutably at pin time
- [ ] `AttemptTaskResponse` exposes `lockdownMode` to Flutter client
- [ ] All unit tests pass (policy defaults, patch endpoint, pin service)
- [ ] Integration test confirms end-to-end flow from session → attempt → response

## Quality and Testing State

- **Quality:** APPROVED (0 blocking findings, 1 LOW advisory)
- **Testing:** Skipped by user (no unit tests for Phase 1)
- **Receipt:** quality/phase-01-backend-policy-extension-receipt.json
- **Notes:** Implementation already exists in codebase. All lockdownMode fields, DTOs, and mapping logic confirmed present and following existing patterns (mirrors answerIntegrityLevel architecture).

### FR-07 Extension (2026-09-09)

Extension done via `lockdown-mode-override` plan (separate plan).

- **Quality:** skipped_by_user
- **Testing:** 12/12 passed (`SessionServiceLockdownTest`)
- **Files added:**
  - `services/scheduling/src/main/java/com/pte/scheduling/dto/request/CreateSessionRequest.java` (+6th field)
  - `services/scheduling/src/main/java/com/pte/scheduling/service/SessionService.java` (override logic + validation)
  - `services/scheduling/src/test/java/com/pte/scheduling/service/SessionServiceLockdownTest.java` (+3 tests, +3 null args)

## Files Changed

- `services/scheduling/src/main/java/com/pte/scheduling/domain/enums/LockdownMode.java` (new)
- `services/scheduling/src/main/java/com/pte/scheduling/domain/ExamPolicy.java`
- `services/scheduling/src/main/java/com/pte/scheduling/dto/response/ExamPolicyResponse.java`
- `services/scheduling/src/main/java/com/pte/scheduling/dto/request/PatchExamPolicyRequest.java`
- `services/scheduling/src/main/java/com/pte/scheduling/service/SessionService.java`
- `services/exam-delivery/src/main/java/com/pte/examdelivery/client/dto/SchedulingEntitlementResponse.java`
- `services/exam-delivery/src/main/java/com/pte/examdelivery/domain/PinnedExamSnapshot.java`
- `services/exam-delivery/src/main/java/com/pte/examdelivery/service/SnapshotPinService.java`
- `services/exam-delivery/src/main/java/com/pte/examdelivery/dto/response/AttemptTaskResponse.java`
- `services/exam-delivery/src/main/java/com/pte/examdelivery/mapper/AttemptMapper.java`
- `services/scheduling/src/main/resources/db/migration/V{next}__add_lockdown_mode_to_exam_policy.sql` (new)
- `services/exam-delivery/src/main/resources/db/migration/V{next}__add_lockdown_mode_to_pinned_snapshot.sql` (new)
- Test files (8 new test cases)
