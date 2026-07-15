# Business Rules — APTIS MVP (Host-Driven Exam Distribution)

## Business Rules

### BR-001: Credentials stored as hashes only

**Rule:** All Admin, Host, and Student account credentials must be stored as salted cryptographic hashes (e.g., bcrypt/argon2). The system must never write a plaintext credential to application logs, database columns, or error messages.
**Applies to:** US-001, US-005, US-006, US-008, US-011
**Rationale:** Even though a Student's plaintext credential is necessarily generated once for the Excel export, the system of record (the database) must never retain or expose it afterward — limiting blast radius if the database is compromised.

### BR-002: Generated Student credentials must be random and sufficiently strong

**Rule:** Each auto-generated Student credential must be a random string of at least 8 characters mixing letters and digits, unique per student, and generated server-side — never derived from predictable data such as the student's name or code.
**Applies to:** US-008
**Rationale:** Prevents trivial guessing or brute-forcing of exam accounts, especially since hundreds of accounts may be created in a single batch.

### BR-003: One submission per exam attempt

**Rule:** A Student's exam attempt may be submitted exactly once. Any subsequent submission request for an already-submitted attempt must be rejected without modifying the previously recorded answers or score.
**Applies to:** US-013, US-011, US-014
**Rationale:** Guarantees the integrity of the score — once an attempt is finalized, it cannot be tampered with via duplicate or replayed submit requests.

### BR-004: Roster identifiers must be unique within a Host's organization

**Rule:** Every row in an uploaded student roster must have a student code or email that is unique within that Host's organization, across all import batches. Duplicate identifiers must be rejected and reported per-row; the system must never silently overwrite an existing Student account.
**Applies to:** US-007, US-008
**Rationale:** Prevents accidental account collisions or credential overwrites that would lock a student out or merge two students' data.

### BR-005: Host data access is scoped to the Host's own organization

**Rule:** A Host may only read or write Student accounts, exam-batch assignments, and credential exports that belong to their own organization (host_id). Any request for a resource scoped to a different Host must be rejected as not-found or forbidden, regardless of how the resource id was obtained.
**Applies to:** US-006, US-007, US-008, US-009, US-010, US-015
**Rationale:** Without full database Row-Level Security in this MVP (see Assumption 5 in requirements.md), every query touching Host-owned data must enforce this filter at the application layer to prevent cross-customer data leakage.

### BR-006: An Exam must contain at least one question to be assignable

**Rule:** An Exam with zero questions must be saved as a non-assignable draft. The Exam-assignment step (US-009) must exclude any Exam that does not have at least one question.
**Applies to:** US-004, US-009
**Rationale:** Prevents Hosts from assigning a broken or empty test to students, which would make scoring meaningless.

### BR-007: Auto-scoring applies only to objective question types

**Rule:** In this MVP, the system supports and auto-scores multiple-choice questions only. The system must not present any score as AI-generated, teacher-reviewed, or applicable to subjective/open-ended content, since no such question type or scoring pipeline exists in this build.
**Applies to:** US-002, US-014
**Rationale:** Sets an honest expectation with students and Hosts about what "score" means in this MVP, avoiding the false impression that Writing/Speaking-style scoring is present.

### BR-008: Credential export files are accessible only to the triggering Host

**Rule:** A generated credentials Excel export must be downloadable only by the authenticated Host account that triggered the corresponding import-and-assign action. No public or guessable URL may grant access to the export.
**Applies to:** US-010
**Rationale:** The export file is the single channel through which plaintext student credentials exist outside the one-time generation step; access must be as tightly controlled as the credentials themselves.

### BR-009: A question already used in an assigned Exam cannot be deleted

**Rule:** If a question belongs to an Exam that has already been assigned to at least one student batch, the system must reject deletion of that question.
**Applies to:** US-003
**Rationale:** Deleting a question after students have been assigned the Exam containing it would silently change what students are tested on and corrupt scoring for in-progress or completed attempts.

### BR-010: No hardcoded secrets in code or configuration

**Rule:** No API key, credential, token, or other secret may be hardcoded anywhere in source code, configuration files, or version control. All secrets must be supplied via environment configuration excluded from the repository.
**Applies to:** All stories
**Rationale:** Baseline security requirement carried over from the full `aptis-lms` project's BR-025; applies equally to a 1-week MVP since the credential-generation flow makes this codebase a high-value target if compromised.
