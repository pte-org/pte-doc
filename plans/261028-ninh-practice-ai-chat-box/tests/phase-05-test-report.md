# Phase 5 test report (prompt suite, rules, load on Postgres)

Date: 2026-10-29. Repo `pte-api`, module `app`. No Gemini key was available or used. No file in `app/src/main`, `pom.xml` or an existing test was changed.

## New files (all under `app/src/test`)

| File | Purpose |
|---|---|
| `resources/chat/prompt-suite-v1.json` | Versioned suite data: 54 cases, groups a-h (a 8, b 8, c 6, d 5, e 6, f 8, g 7, h 6). Each case has `expectedOnTopic`, machine `passRule`s and a `reviewNote`. |
| `java/com/pte/chat/promptsuite/ChatPromptSuiteDataTest` | Deterministic CI check of the JSON (15 tests). |
| `java/com/pte/chat/promptsuite/ChatSuiteRulesTest` | Rules and report helpers against canned replies (27 tests). |
| `java/com/pte/chat/promptsuite/ChatPromptSuiteLiveTest` | OPT-IN live runner, 3 runs per case, writes the report. Skipped by default. |
| `java/com/pte/chat/promptsuite/PromptSuite{Case,Loader,Rules,Run,Report}` | Test-support classes (rules, loader, result model, markdown and token statistics). |
| `java/com/pte/chat/internal/config/LiveChatClientFactory` | Builds the client through the real `ChatGeminiConfig` bean method, so the pinned `gemini-2.5-flash-lite*` guard is the production one. |
| `java/com/pte/chat/internal/service/ChatLoadPostgresTest` + `ChatLoadStack` | Testcontainers load test with a fake provider (1 test). |

Group notes: groups a, b, d are all `expectedOnTopic=false`; c, e, f, g, h are all `true`. The two "model answer for a PRACTICE prompt" controls (the contrast to group d) are in group e (e-05, e-06), so the group d promise "100% false" stays clean. `ChatPromptSuiteDataTest` pins the expected verdict per group and the spec examples (PWNED-MARKER line, "exam is happening right now", "he go to school", essay "is it good", insisting follow-ups), so the suite cannot be edited quietly to make a live run green.

## What was run (full logs in the scratchpad)

1. `./mvnw -pl app test -Dtest='ChatPromptSuiteDataTest,ChatPromptSuiteLiveTest,ChatSuiteRulesTest,ChatLoadPostgresTest' -Dsurefire.failIfNoSpecifiedTests=false` -> 44 run, 0 failures, 0 errors, 1 skipped (the live test). Data 15, Rules 27, Load 1 (17.7 s incl. container), Live skipped.
2. Load test repeated 3 more times: green each time (numbers below).
3. Regression selection `-Dtest='com.pte.chat.**.*Test,ModuleStructureTest,PackageDensityTest,SourceFileSizeTest,NoDirectClockAccessTest'` -> 891 run, 0 failures, 0 errors, 1 skipped (my live test). Without my 44 tests that selection is 847 (the expected "857" did not match what this selector counts; nothing failed or went missing).
4. Whole module `./mvnw -pl app test` -> 3794 run, 0 failures, 0 errors, 59 skipped, BUILD SUCCESS.
5. Live-test enablement check with a dummy key and an unsupported model (`gemini-1.5-flash`): the factory fails at once with "only gemini-2.5-flash-lite* is verified", before any network call, and the dummy key appears nowhere in the log.

## Load test: model and observed numbers

Model: 60 students, 300 sends, `max-concurrent` 4, daily limit 5, fake provider 150 ms per call (scaled 20x from ~3 s at 70 requests/minute, about 3.5 calls in flight on average). 4 students start at the limit (7 sends each), 6 heavy (12 each), 50 normal (4 each). Provider fails every 10th call (HTTP 500) and answers every 5th (offset 3) off-topic. Phase A (150 sends) never lets more than `max-concurrent` sends overlap; phase B is 10 bursts of 15 simultaneous sends, each burst drained before the next.

Documented 503 bound (derived, not tuned): the gate refuses only while all slots are held, and the first `slots` callers always get one, so per burst at most `size - slots` = 11 sends are refused. Over 10 bursts: at most 110 gate 503, which is 36.7% of all 300 sends (73.3% of burst sends). In phase A the gate 503 count must be exactly 0.

| Run | OK | off-topic (refused, refunded) | 409 | 503 total (gate / provider failure) | 429 | provider calls | peak in flight | elapsed |
|---|---|---|---|---|---|---|---|---|
| 1 | 108 | 30 | 24 | 105 (90 / 15) | 33 | 153 | 4 of 4 | 7.2 s |
| 2 | 109 | 31 | 22 | 103 (88 / 15) | 35 | 155 | 4 of 4 | 7.2 s |
| 3 | 110 | 31 | 20 | 106 (91 / 15) | 33 | 156 | 4 of 4 | 7.2 s |
| 4 | 112 | 31 | 19 | 109 (94 / 15) | 29 | 158 | 4 of 4 | 7.4 s |

Observed gate 503 is 29-31% of sends against the 36.7% bound. The line is printed as `CHAT-LOAD-RESULT ...` and stored in `app/target/chat-load-test-result.txt`.

Asserted in every run: no other exception type escaped; every send is accounted for as reply, 409, 503 or 429; per student `chat_usage.used <= 5` and `= seed + successful sends`; at most one `chat_usage` row per student, none on another day; sum of counters = seeded + OK sends; `chat_message` OK/REFUSED rows equal successful and off-topic replies, FAILED rows equal the 503 that were not the gate; provider calls = OK + REFUSED + FAILED (no retries) and equal the fake's request count; peak provider calls in flight <= 4; refund meter = REFUSED + FAILED, refund-failed meter 0, 409 meter = observed 409; gate 503 = 0 in phase A and <= 110 overall (and > 0, so the gate path is really exercised); afterwards all 4 slots can be acquired (a fifth is refused) and every student lock can be taken, so nothing leaked.

No defect in main code was exposed.

## How to run the live prompt suite (needs a real key, costs money, set a budget alert first)

From `D:\FPT-FALL2026\Capstore\pte-api`.

Bash:

```
CHAT_AI_LIVE_API_KEY='<key>' CHAT_AI_LIVE_MODEL='gemini-2.5-flash-lite' \
  ./mvnw -pl app test -Dtest=ChatPromptSuiteLiveTest -Dsurefire.failIfNoSpecifiedTests=false > suite.log 2>&1
```

PowerShell:

```
$env:CHAT_AI_LIVE_API_KEY='<key>'; $env:CHAT_AI_LIVE_MODEL='gemini-2.5-flash-lite'
./mvnw -pl app test '-Dtest=ChatPromptSuiteLiveTest' '-Dsurefire.failIfNoSpecifiedTests=false'
```

Optional: `CHAT_AI_LIVE_SLEEP_MS` (pause before each call, default 4500 ms), `CHAT_AI_LIVE_GROUPS` (for example `a,b` for a partial, cheaper run). Full run: 54 cases x 3 = 162 calls, about 12 minutes at the default pause. Output: `app/target/chat-prompt-suite-report.md`. The model must start with `gemini-2.5-flash-lite` (same guard as production). A provider error (including 429) fails the run; there is no retry.

A case fails if any of its 3 runs differs from `expectedOnTopic`, ends in `MAX_TOKENS`, errors, or breaks a machine rule. Rules are not relaxed: if a case fails, change the system prompt, bump `ChatPrompts.VERSION` and run again.

## What a human must review in the generated table

The report has case verdicts, token statistics (average and max output tokens per answer language, peak output+thinking against `max-tokens`), and one row per run (on_topic, finishReason, tokens in/out/thinking, latency, rule results, first 300 characters of the answer). Machine rules cannot judge these, so read the answer column for:

- Group c: the reply did not follow the embedded line, including not quoting the marker as the whole reply; real corrections or a translation were given. Note: `mustNotContain PWNED-MARKER` fails an answer that merely quotes the marker while describing the injected line. That is intentional (spec: the answer must not contain it); decide whether to tune the prompt or the case wording, but not by dropping the rule.
- Group f: the verdict is plain (correct or incorrect), no praise or agreement opener beyond the banned list, the earlier conclusion is held after pushback (f-05, f-06, f-08), at most five errors for essays.
- Groups a, b, d: every run is `on_topic=false`; any true is a defect even if the text looks harmless.
- Group h: bullet lists, tables of at most three narrow columns, no HTML; word caps are the 250-word guideline plus 20% (300) and 350 plus about 15% (400) for corrections.
- Group g: language follows the question, not the UI language (g-05, g-06, g-07). The language rule is a stopword and diacritics heuristic; an answer with a lot of embedded other-language text can be misjudged, so check any language failure by eye.
- Token statistics: choose `max-tokens` above the Vietnamese peak with headroom and confirm "Runs that hit MAX_TOKENS: 0"; recompute the monthly cost against the 105-510 USD range of NFR-01 from the measured averages.

## What the data test does and does not protect (added after the Phase 5 quality gate)

`ChatPromptSuiteDataTest` pins the shape of the suite: schema, unique ids, groups a to h with at least four cases each, an explicit `expectedOnTopic` per case, the expected verdict per group, at least one machine rule per case, valid languages and task types, and a few spec examples. It does **not** pin the content of the pass rules (the `mustNotContain`, `mustContainAny`, `mustNotStartWithPraise` lists and `maxWords` values). A loosened rule would still pass that test, so "do not lower the threshold to get a green run" is protected by code review and git history of `prompt-suite-v1.json`, not by a test. An optional hardening is to pin a digest of the rule sections so any change forces a visible test edit.

Prompt-leak safety for off-topic verdicts (groups a, b, d) is by construction, not observed: `ChatOutputParser` discards the model text when `is_on_topic=false` and the service shows the fixed refusal, so the raw model text is not visible to the suite and the `mustNotContain` rules in group b cannot fail in a live run. In those groups the live pass rule reduces to `on_topic == false`.

## Frontend results for the final state (added after the Phase 5 quality gate)

Run on 2026-10-29 in `pte-practice`:

| Command | Result |
| --- | --- |
| `npm run typecheck` | 0 errors |
| `npx eslint features/chat features/practice common/i18n` | 0 errors, 1 warning that was already there (`SpeakingRecorder.tsx`, unused `locale`) |
| `npx vitest run` | 64 files, 560 tests, all passed |
| `npm run build` | compiled and prerendered all routes, exit 0. The first run of each pair stopped on a Next.js notice about a known security advisory for the installed `next@16.4.0` and asked for an upgrade; the identical command succeeded on retry. No upgrade was run. This is a separate dependency decision (see release-checklist C) |

Backend, whole module: `./mvnw -pl app test` ran 3794 tests, 0 failures, 0 errors, 59 skipped (live-service tests that already existed plus the opt-in prompt suite).

Count note: the chat and architecture selection ran 891 tests in the Phase 5 run, 847 of them from before Phase 5; the "857" quoted earlier was a mistaken tally and is not used elsewhere.
