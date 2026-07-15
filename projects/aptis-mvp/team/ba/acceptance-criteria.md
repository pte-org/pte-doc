# Acceptance Criteria — APTIS MVP (Host-Driven Exam Distribution)

## Acceptance Criteria

### US-001 — Admin login

**Scenario: Successful login**
- **Given** an Admin account exists with a known email and credential
- **When** the Admin submits the login form with the correct email and credential
- **Then** the Admin is authenticated and redirected to the Admin dashboard
- **And** an auth session token is issued

**Scenario: Wrong credential rejected**
- **Given** an Admin account exists
- **When** the Admin submits the correct email but a wrong credential
- **Then** the system rejects the login with a generic "invalid email or credential" message
- **And** no session token is issued

**Scenario: Account does not exist**
- **Given** no Admin account exists for the submitted email
- **When** the login form is submitted
- **Then** the system returns the same generic "invalid email or credential" message as a wrong-credential attempt (no account-existence leak)

**Scenario: Empty fields**
- **Given** the Admin opens the login form
- **When** the Admin submits with email and/or credential left blank
- **Then** the system rejects the submission with a field-level validation error and makes no authentication attempt

---

### US-002 — Create exam questions

**Scenario: Create a valid multiple-choice question**
- **Given** the Admin is on the question editor
- **When** the Admin submits a question text, at least two options, and exactly one option marked correct
- **Then** the system saves the question and it appears in the question list

**Scenario: Reject question with no correct option marked**
- **Given** the Admin is creating a question
- **When** the Admin submits the question without marking any option as correct
- **Then** the system rejects the save with a validation error and the question is not created

**Scenario: Reject question with fewer than two options**
- **Given** the Admin is creating a multiple-choice question
- **When** the Admin submits only one answer option
- **Then** the system rejects the save with a validation error

**Scenario: Reject empty question text**
- **Given** the Admin is creating a question
- **When** the Admin submits with the question text field empty
- **Then** the system rejects the save with a validation error

---

### US-003 — Edit/delete exam questions

**Scenario: Edit an existing question**
- **Given** a question exists and is not yet part of any Exam assigned to students
- **When** the Admin edits its text or options and saves
- **Then** the system persists the updated question content

**Scenario: Delete an unused question**
- **Given** a question exists and is not referenced by any Exam
- **When** the Admin deletes it
- **Then** the system removes the question from the question list

**Scenario: Block deleting a question already used in an assigned Exam**
- **Given** a question belongs to an Exam that has already been assigned to at least one student batch
- **When** the Admin attempts to delete that question
- **Then** the system rejects the deletion with an explanation that the question is in use

**Scenario: Edit attempt on non-existent question**
- **Given** a question id that does not exist
- **When** the Admin requests to edit it
- **Then** the system returns a not-found error

---

### US-004 — Group questions into an Exam

**Scenario: Create an Exam with questions**
- **Given** the Admin has at least one question available
- **When** the Admin creates a new Exam and adds one or more questions to it
- **Then** the system saves the Exam and marks it assignable

**Scenario: Reject an Exam with zero questions**
- **Given** the Admin creates a new Exam
- **When** the Admin attempts to save the Exam without adding any question
- **Then** the system saves it as a draft but marks it not assignable, per BR-006

**Scenario: Remove a question from a draft Exam**
- **Given** an Exam exists in draft state with two or more questions
- **When** the Admin removes one question
- **Then** the system updates the Exam's question list and recalculates assignability

**Scenario: Duplicate Exam name**
- **Given** an Exam named "APTIS Mock A" already exists
- **When** the Admin tries to create another Exam with the exact same name
- **Then** the system rejects the save with a duplicate-name validation error

---

### US-005 — Create Host account

**Scenario: Successful Host creation**
- **Given** the Admin is on the Host management screen
- **When** the Admin submits an organization name and contact email for a new Host
- **Then** the system creates the Host account, generates a credential, and displays it once to the Admin

**Scenario: Duplicate Host email rejected**
- **Given** a Host account already exists with email "center@example.com"
- **When** the Admin tries to create another Host with the same email
- **Then** the system rejects the creation with a duplicate-email error

**Scenario: Missing organization name**
- **Given** the Admin submits the Host creation form
- **When** the organization name field is left blank
- **Then** the system rejects the submission with a validation error

**Scenario: Host credential is never displayed twice**
- **Given** a Host account was just created and its credential was shown once
- **When** the Admin reloads the Host detail page
- **Then** the system does not display the plaintext credential again (only a "reset credential" action is available)

---

### US-006 — Host login

**Scenario: Successful Host login**
- **Given** a Host account exists with an issued credential
- **When** the Host submits the correct email and credential
- **Then** the Host is authenticated and redirected to the Host dashboard scoped to their organization

**Scenario: Wrong credential rejected**
- **Given** a Host account exists
- **When** the Host submits a wrong credential
- **Then** the system rejects the login with a generic invalid-login message

**Scenario: Host attempts to access another Host's data via direct URL**
- **Given** Host A is authenticated
- **When** Host A requests a student or exam-batch resource belonging to Host B by id
- **Then** the system returns a not-found/forbidden error per BR-005

**Scenario: Deactivated Host account**
- **Given** an Admin has deactivated a Host account
- **When** that Host attempts to log in
- **Then** the system rejects the login even with correct credentials

---

### US-007 — Upload student roster Excel

**Scenario: Successful roster upload**
- **Given** the Host is on the roster import screen
- **When** the Host uploads a valid .xlsx file with full name and unique student code/email per row
- **Then** the system parses every row and proceeds to the validation report step

**Scenario: Reject non-Excel file**
- **Given** the Host attempts to upload a file
- **When** the file is not a valid .xlsx (e.g., a .txt or corrupted file)
- **Then** the system rejects the upload with a file-format error and creates no accounts

**Scenario: Reject empty file**
- **Given** the Host uploads an .xlsx file with a header row but zero data rows
- **When** the system parses it
- **Then** the system rejects the upload stating no valid rows were found

**Scenario: Oversized file rejected**
- **Given** the Host uploads a file exceeding the platform's configured maximum roster size
- **When** the system receives it
- **Then** the system rejects the upload before parsing, with a size-limit error

---

### US-008 — Roster row validation report

**Scenario: Mixed valid and invalid rows**
- **Given** an uploaded roster has some rows missing required fields and some rows duplicated within the same file
- **When** the system validates the file
- **Then** the system reports each invalid row with its row number and reason, and proceeds to create accounts only for the valid rows, per BR-004

**Scenario: Duplicate identifier across two upload batches**
- **Given** a student code was already imported in a previous batch for the same Host
- **When** the Host uploads a new roster containing that same student code
- **Then** the system flags that row as a duplicate and does not create a second account for it

**Scenario: All rows valid**
- **Given** every row in the uploaded roster passes validation
- **When** the system finishes validating
- **Then** the system reports zero errors and proceeds directly to account creation

**Scenario: All rows invalid**
- **Given** every row in the uploaded roster is missing required fields
- **When** the system finishes validating
- **Then** the system reports every row as invalid and creates zero student accounts

---

### US-009 — Assign Exam to imported batch

**Scenario: Assign an assignable Exam**
- **Given** the Host has just imported a batch of valid students and at least one Exam with questions exists
- **When** the Host selects that Exam and confirms assignment
- **Then** the system links every student in the batch to that Exam, per BR-006

**Scenario: Attempt to assign a non-assignable (empty) Exam**
- **Given** an Exam exists with zero questions
- **When** the Host attempts to select it for assignment
- **Then** the system excludes it from the selectable list and shows none if no other Exam qualifies

**Scenario: No Exam available**
- **Given** the Admin has not yet created any assignable Exam
- **When** the Host reaches the assignment step
- **Then** the system shows an empty state explaining no Exam is currently available, and import remains pending assignment

**Scenario: Re-assign after partial failure**
- **Given** an import batch was created but assignment was not completed (e.g., session expired)
- **When** the Host returns to the batch later
- **Then** the system allows the Host to resume and complete the Exam assignment for that batch

---

### US-010 — Download generated credentials Excel

**Scenario: Successful export after assignment**
- **Given** a batch of students has been imported and assigned an Exam
- **When** the Host requests the credentials export
- **Then** the system generates an .xlsx file with full name, username, generated credential, and Exam name for each student in that batch, and the Host can download it, per BR-008

**Scenario: Unauthorized download attempt**
- **Given** a credentials export exists for Host A's batch
- **When** an unauthenticated request or a request from Host B attempts to download that export
- **Then** the system rejects the request with a forbidden/not-found error, per BR-005 and BR-008

**Scenario: Download before assignment is complete**
- **Given** a batch has been imported but no Exam has yet been assigned
- **When** the Host attempts to download the credentials export
- **Then** the system blocks the download and prompts the Host to complete Exam assignment first

**Scenario: Re-download same export**
- **Given** a Host already downloaded the export once
- **When** the Host requests the same export again
- **Then** the system allows the re-download (credentials are not invalidated by viewing), since the file is the system of record for distribution

---

### US-011 — Student login

**Scenario: Successful first login**
- **Given** a Student account was generated with a username and credential
- **When** the Student logs in with those exact values
- **Then** the Student is authenticated and taken to their assigned Exam's entry screen

**Scenario: Wrong credential rejected**
- **Given** a Student account exists
- **When** the Student submits a wrong credential
- **Then** the system rejects the login with a generic invalid-login message

**Scenario: Login with no Exam assigned yet**
- **Given** a Student account exists but the Host has not yet assigned an Exam to that batch
- **When** the Student logs in
- **Then** the system shows a "no exam assigned yet" state instead of an exam entry screen

**Scenario: Login after exam already submitted**
- **Given** the Student has already submitted their one allowed attempt
- **When** the Student logs in again
- **Then** the system shows the Student's score/result screen instead of allowing a new attempt, per BR-003

---

### US-012 — View and answer exam questions

**Scenario: Answer and navigate questions**
- **Given** a Student has an assigned, not-yet-submitted Exam attempt
- **When** the Student selects an answer for a question and moves to the next question
- **Then** the system records the selected answer for that question and displays the next question

**Scenario: Change an answer before submission**
- **Given** the Student already answered a question
- **When** the Student returns to that question and selects a different option
- **Then** the system overwrites the previously recorded answer with the new one

**Scenario: Leave a question unanswered**
- **Given** the Student has not selected any option for a question
- **When** the Student navigates away without answering
- **Then** the system records no answer for that question and allows the Student to continue (unanswered = incorrect at scoring time)

**Scenario: Resume after closing the browser mid-exam**
- **Given** the Student has answered some questions but not submitted
- **When** the Student logs back in before submitting
- **Then** the system restores the in-progress attempt with previously recorded answers intact

---

### US-013 — Submit exam (single attempt)

**Scenario: Successful single submission**
- **Given** a Student has an in-progress, not-yet-submitted attempt
- **When** the Student clicks submit
- **Then** the system marks the attempt as submitted, locks all answers from further edits, and triggers scoring, per BR-003

**Scenario: Reject a second submission**
- **Given** a Student's attempt was already submitted
- **When** the Student (or a replayed/duplicate request) attempts to submit again
- **Then** the system rejects the second submission and makes no change to the already-recorded answers, per BR-003

**Scenario: Submit with some questions unanswered**
- **Given** a Student has answered only part of the Exam
- **When** the Student clicks submit
- **Then** the system accepts the submission, treating unanswered questions as incorrect during scoring

**Scenario: Confirmation before final submit**
- **Given** the Student clicks submit
- **When** the system detects one or more unanswered questions
- **Then** the system shows a confirmation prompt listing the unanswered question count before finalizing the submission

---

### US-014 — View immediate score

**Scenario: Score shown right after submission**
- **Given** a Student's attempt was just submitted
- **When** scoring completes
- **Then** the system displays the Student's number-correct score and percentage immediately on the result screen

**Scenario: Score is deterministic from recorded answers**
- **Given** a Student's recorded answers for each question are known
- **When** the system scores the attempt
- **Then** the resulting score exactly matches the count of recorded answers that match each question's marked-correct option, per BR-007

**Scenario: Returning to view a past result**
- **Given** a Student already has a submitted, scored attempt
- **When** the Student logs in again later
- **Then** the system shows the same previously computed score (scoring is not recalculated or changed)

**Scenario: Subjective-question disclaimer (none present in MVP)**
- **Given** the MVP only contains multiple-choice questions per BR-007
- **When** a Student views their result
- **Then** the system shows only an objective score with no AI-generated or subjective scoring claim

---

### US-015 — Admin Host activity overview

**Scenario: List shows all Hosts with counts**
- **Given** two or more Host accounts exist with varying numbers of imported students
- **When** the Admin opens the Host list
- **Then** the system shows each Host's organization name, student count, and whether an Exam has been assigned to their latest batch

**Scenario: Host with zero students**
- **Given** a Host account was just created with no roster imported yet
- **When** the Admin views the Host list
- **Then** the system shows that Host with a student count of zero and an "no import yet" status

**Scenario: Filter or search by organization name**
- **Given** many Host accounts exist
- **When** the Admin searches by organization name
- **Then** the system returns only Hosts whose organization name matches the search term

**Scenario: Deactivated Host still visible**
- **Given** a Host account has been deactivated by Admin
- **When** the Admin views the Host list
- **Then** the system still shows that Host with a clear "deactivated" status rather than hiding it
