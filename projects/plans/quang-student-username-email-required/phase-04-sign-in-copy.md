# Phase 04 — Sign-in copy on Practice Web and exam app

**Repos:** pte-practice, pte-app · **Depends on:** 01 · **Status:** Done

Login logic stays the same (username + password); only the wording changes so Students know what to type.

1. pte-practice: label "Username", placeholder `e.g. center.a7k2m9xq`, hint "Find it in the e-mail or file from your
   organization"; forgot-password text "Ask your organization to reset your password". Keep `requireEmail = false`.
2. pte-app: same label and hint in `AppStrings` (`loginUsernameLabel`, new `loginUsernameHint`); no e-mail format
   check.
3. Tests: existing sign-in tests updated for the new copy (vitest; `flutter test test/widget/features/auth`).
