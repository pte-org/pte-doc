# Quang — acceptance matrix: host exam app preview
All rows start NOT RUN. This is an executable checklist, not proof of implementation.
Use isolated local/test identities: H1 HOST_ADMIN tenant A; H2 HOST_ADMIN tenant B;
S1 STUDENT tenant A; M1 HOST_ADMIN+STUDENT tenant A; X1 PROCTOR/EXAMINER/platform-only.
Never copy actual credentials into this file.

## Acceptance cases
| ID | Setup / action | Required result | Test level |
|---|---|---|---|
| CL01 | Re-read staged+unstaged app changes | Only reviewed flag-only hunks discarded; recoverable binary patch exists | source/patch check |
| CL02 | Additional edit appears in one of five files | Preserve additional edit; remove flag surgically | controlled diff check |
| AU01 | H1 logs in | Host exam list; no student code/device-check page | unit/widget/Windows |
| AU02 | S1 logs in after H1 logout | Student flow, normal guards, no host navigation | unit/widget/Windows mocks |
| AU03 | M1 logs in | Explicit hostPreview context; cannot enter student attempt through preview | unit/widget |
| AU04 | X1 logs in | Existing access-denied screen | unit/widget |
| AU05 | Unauthenticated/forged role UI calls preview | Server 401/403; no content shown | API integration |
| AU06 | H1 sends tenant B session id | Existing not-found/forbidden tenant policy; no data leak | API integration |
| AU07 | Session expires/refresh fails during playback/recording | Stop media/timers, clear preview RAM/temp, login route | unit/widget |
| AU08 | Previous student's pending answer/media/violation queues exist, H1 logs in | No queue flush under host token; rows preserved for legitimate owner | unit/network |
| AP01 | H1 selects READY with snapshot | Preview opens, session status/snapshot/version unchanged | API + app |
| AP02 | H1 selects SCHEDULED/OPEN/CLOSED/CANCELLED with snapshot | Same read-only access, no status mutation | parameterized API |
| AP03 | DRAFT without snapshot | Preview disabled, direct GET returns common not-ready error | API/widget |
| AP04 | Compare student and host resolved timing/runtime for same snapshot | Same canonical contract and timing inputs; section timer display documented | resolver test |
| AP05 | Snapshot item duplicates source question | Distinct snapshotItemPublicId, independent RAM responses | unit/contract |
| AP06 | Inspect serialized preview | No correctAnswerText/referenceAnswerText/isCorrect/scoring answer metadata | contract test |
| AP07 | Blank groups/options/order | Exact grouping, option order and text retained | contract/adapter |
| AP08 | Expired signed URL | One protected re-fetch; same snapshot validated; no infinite retry | unit/network |
| AP09 | Refetch returns changed snapshot id | End old local state; ask to reload fresh preview; no mixing | unit/widget |
| AP10 | Missing/unsupported runtime or required media | Common error/skippable task; no fixture replacement | unit/widget |
| UI01 | Initial Read Aloud render | Instruction -> centered recorder -> passage -> bottom-right navigation | screenshot/manual |
| UI02 | Answer controls | Typing/selection/fill/reorder/highlight work with shared real presentation | widget |
| UI03 | Every canonical task | Next visible, enabled outside transition; no student navigation API | parameterized widget |
| UI04 | Next during preparation/audio/recording | Stops old session once before next begins | unit/fake audio |
| UI05 | Double Next / stale timer/audio callback | Exactly one transition, no off-by-one or old mic restart | unit |
| UI06 | Previous | First disabled; valid prior item loads, text answers RAM only, audio resets | widget |
| UI07 | Final Next / Finish preview | Returns list; no submit/score; RAM cleared | widget/network |
| UI08 | Timer expires | Completed state, no upload/auto-next | unit |
| UI09 | Mic denied or media fetch error | Brief error, Next usable, no permission loop/upload fallback | unit/widget |
| DA01 | Host types/records, navigates and exits | No answer/media/outbox DB writes; temp deleted; RAM cleared | spies/filesystem |
| DA02 | Crash leaves owned temp | Next launch removes preview-only files; student files unaffected | filesystem test |
| DA03 | Host preview request trace | Only auth/read routes and required media GET; no uploads/scoring/attempt writes | network |
| DA04 | Quota baseline after creation vs after preview | Exam/scoring/media-upload quota unchanged by preview | DB/test spy |
| SC01 | Host starts/resumes/minimizes/closes preview | No fullscreen/close/process/clipboard/shortcut guard calls or host violations | native mocks/Windows |
| SC02 | Student takes normal exam after host logout | Existing enforcement activation and delivery behavior restored | regression |
| NO01 | First successful generation commits | One SESSION_PREVIEW_READY inbox item for generating actor in tenant | Postgres/event |
| NO02 | READY generate replay / request retry | No second inbox item | Postgres/concurrency |
| NO03 | Generate transaction rolls back | No durable inbox item | Postgres/transaction |
| NO04 | READY commits but later publish fails | Ready notification remains valid; host can preview READY | integration |
| NO05 | Draft creator != generation actor | Actor receives message; no invented creator field lookup | event unit |
| NO06 | Existing exam + new app login | No backfill/new notification side effect | integration |
| NO07 | Actual Flyway fresh + upgrade with existing rows | New type accepted, all old types/data preserved, checksum valid | Postgres/Flyway |
| NO08 | Bell/history/unread/read click | Common UI renders message and exam link; read count correct | web |
| NO09 | Same event key with changed payload/audience | Existing inbox conflict semantics preserved | repository test |
| RG01 | Existing student task/auto-advance/security tests | Pass; no changes in student behavior justified as preview work | regression |
| RG02 | Release Windows host login | Preview works without DEV_SKIP_AUTH/global security disable defines | Windows smoke |

## Canonical task coverage (22 distinct codes, not 22 questions)
For EACH row: check correct content/renderer; input response works; Next anytime; cleanup;
no persistence/upload; comparison to student shared UI; record status and evidence.
| Group | Task code | Response | Audio path |
|---|---|---|---|
| Speaking | READ_ALOUD | local recording | prep -> record |
| Speaking | REPEAT_SENTENCE | local recording | listen -> record |
| Speaking | DESCRIBE_IMAGE | image + local recording | prep -> record |
| Speaking | RE_TELL_LECTURE | local recording | listen -> prep -> record |
| Speaking | ANSWER_SHORT_QUESTION | local recording | listen -> record |
| Speaking | SUMMARIZE_GROUP_DISCUSSION | local recording | listen -> prep -> record |
| Speaking | RESPOND_TO_A_SITUATION | local recording | follow current runtime prompt sequence |
| Writing | SUMMARIZE_WRITTEN_TEXT | free text + word count | none |
| Writing | WRITE_ESSAY | free text + word count | none |
| Reading | FILL_IN_THE_BLANKS_DROPDOWN | grouped select | none |
| Reading | MC_READING_MULTIPLE | multi-select | none |
| Reading | MC_READING_SINGLE | single-select | none |
| Reading | RE_ORDER_PARAGRAPHS | reorder | none |
| Reading | FILL_IN_THE_BLANKS_DRAG_AND_DROP | drag/drop | none |
| Listening | SUMMARIZE_SPOKEN_TEXT | free text + word count | listen |
| Listening | MC_LISTENING_MULTIPLE | multi-select | listen |
| Listening | FILL_IN_THE_BLANKS_TYPE_IN | typed blanks | listen |
| Listening | HIGHLIGHT_CORRECT_SUMMARY | single-select | listen |
| Listening | MC_LISTENING_SINGLE | single-select | listen |
| Listening | SELECT_MISSING_WORD | single-select | listen |
| Listening | HIGHLIGHT_INCORRECT_WORDS | token toggle | listen |
| Listening | WRITE_FROM_DICTATION | free text | listen |

Canonicalize via existing registry, not hardcoded alias guesses.
PERSONAL_INTRODUCTION is optional extra coverage if included in the snapshot; do not count it as one of these 22.
Custom runtime item uses supported allowlisted contract; unsupported screen stays explicit/skippable without auto executing metadata.

## Evidence record format
For every case: ID, status (PASS/FAIL/SKIPPED/NOT RUN), command or manual steps, environment/build SHA,
expected/actual, file/log/screenshot reference. Test spies demonstrate prohibited calls = 0;
a successful screenshot alone does not prove quota/no-storage properties.
Fixture-only coverage is separately labeled from actual API snapshot and Windows checks.

## Verification ledger — 2026-10-29

The entries below record the current automated evidence. `PASS` means the
specified unit/widget/contract evidence passed; it does not imply a live API,
Postgres, quota, or Windows manual check unless the evidence says so.

| ID | Status | Evidence |
|---|---|---|
| CL01 | PASS | Phase 1 preflight/discard report and recoverable patch |
| CL02 | PASS | Phase 1 controlled diff review |
| AU01 | PASS | App auth-gate and host route unit/widget tests |
| AU02 | PASS | App auth-gate student route regression tests |
| AU03 | PASS | Mixed-role host precedence unit tests |
| AU04 | PASS | Access-policy denied-role tests |
| AU05 | PASS | Read-only API contract and repository tests; live 401/403 not run |
| AU06 | PASS | Tenant-scoped repository/policy tests; live cross-tenant request not run |
| AU07 | PASS | Auth/session and preview lifecycle unit/widget coverage |
| AU08 | PASS | Queue isolation/source audit tests; live token trace not run |
| AP01 | PASS | Snapshot-required preview repository/cubit/widget tests |
| AP02 | PASS | Read-only session handling tests; live status matrix not run |
| AP03 | PASS | Draft-without-snapshot list/widget and API error contract tests |
| AP04 | PASS | Shared runtime/timing resolver contract tests |
| AP05 | PASS | Snapshot item identity and RAM answer-key tests |
| AP06 | PASS | Preview DTO excludes answer-bearing fields tests |
| AP07 | PASS | Option/order/group adapter tests |
| AP08 | PASS | Repository retry/error boundary tests |
| AP09 | PASS | Snapshot identity boundary tests |
| AP10 | PASS | Unsupported runtime/media error-state tests |
| UI01 | PASS | Preview widget layout tests; no manual screenshot |
| UI02 | PASS | Shared renderer/answer-controller widget coverage |
| UI03 | PASS | Canonical task adapter and navigation tests |
| UI04 | PASS | Local audio/navigation lifecycle tests |
| UI05 | PASS | Cubit transition/timer stale-callback tests |
| UI06 | PASS | Local previous/navigation state tests |
| UI07 | PASS | Final Next/Finish RAM-only widget tests |
| UI08 | PASS | Timer-expiry no-auto-next tests |
| UI09 | PASS | Media failure and usable-Next tests |
| DA01 | PASS | RAM/temp-media unit tests; no live Drift/network trace |
| DA02 | PASS | Preview-owned orphan cleanup filesystem tests |
| DA03 | SKIPPED | Live host request trace requires controlled API/session |
| DA04 | SKIPPED | Live quota baseline requires controlled DB/API |
| SC01 | SKIPPED | Native Windows host guard smoke not manually run; no student lockdown activated |
| SC02 | PASS | Student security coordinator and regression tests; Windows smoke not run |
| NO01 | SKIPPED | Unit event emission passed, durable inbox/Postgres check skipped |
| NO02 | SKIPPED | Unit READY replay passed, durable dedup/concurrency check skipped |
| NO03 | SKIPPED | Transaction rollback requires Postgres |
| NO04 | SKIPPED | Commit/failure ordering requires integration environment |
| NO05 | PASS | Generating actor and tenant membership listener tests |
| NO06 | SKIPPED | Live existing-exam login/backfill check not run |
| NO07 | SKIPPED | Flyway fresh/upgrade suite skipped: no `INBOX_TEST_DB_*` variables |
| NO08 | SKIPPED | Shared web transport/type tests passed; live bell/history integration not run |
| NO09 | SKIPPED | Repository conflict semantics require Postgres integration |
| RG01 | PASS | Full Flutter suite and focused student security tests |
| RG02 | SKIPPED | Windows release build passed; controlled host READY/student login smoke not run |

### Canonical task coverage

All 22 canonical codes below have `PASS` fixture/adapter/widget evidence and
`NOT RUN` actual snapshot/Windows evidence:

`READ_ALOUD`, `REPEAT_SENTENCE`, `DESCRIBE_IMAGE`, `RE_TELL_LECTURE`,
`ANSWER_SHORT_QUESTION`, `SUMMARIZE_GROUP_DISCUSSION`,
`RESPOND_TO_A_SITUATION`, `SUMMARIZE_WRITTEN_TEXT`, `WRITE_ESSAY`,
`FILL_IN_THE_BLANKS_DROPDOWN`, `MC_READING_MULTIPLE`, `MC_READING_SINGLE`,
`RE_ORDER_PARAGRAPHS`, `FILL_IN_THE_BLANKS_DRAG_AND_DROP`,
`SUMMARIZE_SPOKEN_TEXT`, `MC_LISTENING_MULTIPLE`,
`FILL_IN_THE_BLANKS_TYPE_IN`, `HIGHLIGHT_CORRECT_SUMMARY`,
`MC_LISTENING_SINGLE`, `SELECT_MISSING_WORD`,
`HIGHLIGHT_INCORRECT_WORDS`, `WRITE_FROM_DICTATION`.

The detailed command totals and skipped boundaries are in
`pte-doc/plans/reports/261029-quang-host-exam-app-preview-verification.md`.
