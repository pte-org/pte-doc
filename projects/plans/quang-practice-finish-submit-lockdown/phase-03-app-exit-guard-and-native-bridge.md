# Phase 3 — App-level exit guard and native Windows bridge

## Objective

Keep the active student attempt inside the Windows app until terminal submission is acknowledged, while preserving the normal centered login window and avoiding blocking/native-thread network work.

## Scope and likely files

### Dart

- `pte-app/lib/core/security/lockdown_service.dart`
- `pte-app/lib/core/security/lockdown_mode.dart`
- New small `pte-app/lib/core/security/exam_exit_guard.dart` if the existing service would otherwise own unrelated state.
- `pte-app/lib/app.dart` and exam shell lifecycle wiring.
- Existing violation reporter/audit adapter and related tests.

### Windows runner

- `pte-app/windows/runner/lockdown_plugin.cpp`
- `pte-app/windows/runner/lockdown_plugin.h`
- `pte-app/windows/runner/flutter_window.cpp`
- Any existing runner window/message dispatch helper.

## Steps

1. Add an explicit guarded-attempt lifecycle to the app service:
   - `activateForAttempt`/equivalent when the exam task shell begins;
   - `keepExitBlocked` for active, submitting, and failed states;
   - `allowExitAfterSubmission` only after the Phase 1 acknowledgement;
   - `deactivate` after the completion/exit transition.
2. Define a native bridge command/state for exit permission. The default must be blocked while an attempt is active; the permission must not be inferred from window visibility or route name.
3. Intercept supported native events:
   - `WM_CLOSE` / Alt+F4;
   - minimize and relevant `WM_SYSCOMMAND` values;
   - focus loss (`WM_KILLFOCUS`) and fullscreen loss;
   - existing shortcut/focus signals already implemented by the plugin.
4. On a blocked event, return quickly from the Windows message handler, emit a lightweight event, and let Dart show the warning/audit. Never await an API call on the Windows message thread.
5. Debounce warning presentation and audit bursts so holding Alt+Tab or repeated focus changes does not create dozens of modal dialogs. Preserve an event count if the audit contract supports it.
6. Re-arm fullscreen/focus where possible. Treat Alt+Tab prevention as best effort; Windows may switch focus before the app can react.
7. Preserve `main.cpp` normal window sizing. The guard must activate only for the device-check/exam lifecycle and must not make the login screen fullscreen.
8. Ensure the guard is safe on non-Windows platforms and in widget tests: no-op native command, deterministic audit behavior, no platform channel crash.
9. Add a small internal diagnostic/log message for state transitions without logging credentials, tokens, or answer content.

## Design Constraints

- This is app-level containment, not an operating-system kiosk.
- No Assigned Access, Shell Launcher, registry, policy, or shell replacement work.
- Close/minimize/focus handling must be non-blocking on the native message thread.
- The server acknowledgement remains the only unlock authority.
- Existing warning/audit semantics from the parent anti-cheat plan remain warning-only.
- Do not apply exam lock behavior to login.

## Quality and Testing State

- **Quality:** APPROVED. Receipt: `quality/phase-03-app-exit-guard-and-native-bridge-receipt.json`.
- **Testing:** PASSED. `59` focused Flutter tests passed; focused analyzer passed; the Windows debug build passed. Native manual behavior remains part of Phase 5's release matrix.

## Acceptance criteria

- While an attempt is active or submission is retryable, app-level close is refused or re-armed where the Windows hook supports it.
- A focus-loss/Alt+Tab attempt produces warning/audit behavior without crashing or exiting the exam.
- Native handlers do not call the network or block the message loop.
- A submitted state can explicitly set exit permission and release fullscreen.
- Login remains centered and bounded in a release build.
