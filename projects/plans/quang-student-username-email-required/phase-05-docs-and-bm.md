# Phase 05 — Docs and BM

**Depends on:** 01–04 · **Status:** Done

1. `docs/HOST_STUDENT_IMPORT_FLOW.md`: rewrite for the real flow (template download → client structure check →
   preview → `POST /api/v1/users/bulk` → credentials file / optional e-mail), field rules and error codes from
   phase 02; drop the Aptis parse/preview/confirm endpoints that were never built.
   Record that class placement from the file is deferred (plan D9).
2. `docs/TEST_SCENARIOS_IAM.md`: replace the import scenarios with the phase 02/03 cases; add "same e-mail in two
   organizations → two accounts" and "Student signs in with username, not e-mail".
3. AGENTS.md snapshot line if the endpoint count changes.
4. BM: **do not edit the BM files.** When phases 01–04 are done, give the user a list of exactly where to change
   (file, section/table, row or ID, current text, new text) so they edit it themselves. Expected places:
   - BM01 section 3, row D4 (chosen option) and section 6, F-05 acceptance;
   - BM03 table 2, change #1 (proposed content);
   - BM04 section 3, F-05 acceptance; section 6.2 (WF-02) features table F-05 and demo DS-02a
     (data, steps, expected result); add an exception case for a row without e-mail if wanted.
