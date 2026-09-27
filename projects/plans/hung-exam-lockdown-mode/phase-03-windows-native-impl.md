# Phase 3: Native Windows Implementation

**Status:** Blocked (verification toolchain unavailable)  
**Depends on:** Phase 2 (Platform Channels Foundation)  
**Estimated effort:** 2 weeks  
**Risk:** CRITICAL (native C++ code, Windows hooks, UAC permissions)

---

## Objective

Implement Windows C++ native plugin for lockdown enforcement: fullscreen enforcement, keyboard hook interception (Alt+Tab, Win+D, PrintScreen), clipboard monitoring (block external paste), and process enumeration/termination (forbidden apps). All violations emit events back to Dart via EventChannel.

## Success Criteria

- [ ] Fullscreen mode enforced (SetWindowLong, WS_POPUP style)
- [ ] Keyboard hooks installed (WH_KEYBOARD_LL) blocking system shortcuts
- [ ] Clipboard monitoring active (AddClipboardFormatListener) detecting external paste
- [ ] Process enumeration working (CreateToolhelp32Snapshot)
- [ ] Process termination working (OpenProcess + TerminateProcess with UAC elevation)
- [ ] All violation events sent to Dart (EventChannel callbacks)
- [ ] Graceful error handling (try-catch, return error codes instead of crashing)
- [ ] Unit tests (C++ mock tests for hook installation)
- [ ] Manual QA on Windows 10/11

## Implementation State

The Windows plugin implementation now includes persistent EventChannel sinks, keyboard hook interception, clipboard format-listener handling, process enumeration and termination, reversible fullscreen state, and runner message forwarding. Dart platform-channel documentation is Windows-only, and no macOS lockdown implementation is present.

## Quality and Testing State

- **Quality**: Blocked. The quality gate could not run because Flutter, Dart, CMake, the Microsoft C++ compiler, and Python are unavailable in PATH.
- **Testing**: Blocked. Unit tests could not run because Flutter and Dart are unavailable in PATH. User selected tests=yes and quality=yes.
- **Build Gate**: Blocked. Windows native compilation could not run because CMake and the Microsoft C++ compiler are unavailable in PATH.
- **Static checks**: Passed. Editor diagnostics and `git diff --check` reported no errors.
- **Commit**: Not created because required verification gates did not pass.

## Notes

- **Windows-only scope**: macOS implementation is deferred per the project specification.
- **Windows UAC**: Process termination may require elevation for protected processes; this remains a runtime permission concern for Phase 4.
- **Manual QA**: Windows 10/11 manual QA remains pending until the native build can be executed.
