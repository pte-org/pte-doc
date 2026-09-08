# Phase 3: Native Windows Implementation

**Status:** Ready  
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

## Steps

### Step 1: Create Windows Plugin Shell

**File:** `windows/runner/lockdown_plugin.h`

```cpp
#ifndef LOCKDOWN_PLUGIN_H
#define LOCKDOWN_PLUGIN_H

#include <flutter/method_channel.h>
#include <flutter/event_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <windows.h>
#include <tlhelp32.h>
#include <memory>
#include <string>
#include <vector>

namespace lockdown {

class LockdownPlugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  LockdownPlugin();
  virtual ~LockdownPlugin();

 private:
  // Window management
  void EnforceFullscreen(const flutter::EncodableValue* args, 
                         std::unique_ptr<flutter::MethodResult<>> result);
  void ExitFullscreen(const flutter::EncodableValue* args,
                      std::unique_ptr<flutter::MethodResult<>> result);

  // Process management
  void GetRunningProcesses(const flutter::EncodableValue* args,
                           std::unique_ptr<flutter::MethodResult<>> result);
  void TerminateProcess(const flutter::EncodableValue* args,
                        std::unique_ptr<flutter::MethodResult<>> result);

  // Clipboard
  void BlockExternalPaste(const flutter::EncodableValue* args,
                          std::unique_ptr<flutter::MethodResult<>> result);
  void ClearClipboard(const flutter::EncodableValue* args,
                      std::unique_ptr<flutter::MethodResult<>> result);
  void UnblockClipboard(const flutter::EncodableValue* args,
                        std::unique_ptr<flutter::MethodResult<>> result);

  // Shortcuts
  void BlockSystemShortcuts(const flutter::EncodableValue* args,
                            std::unique_ptr<flutter::MethodResult<>> result);
  void UnblockSystemShortcuts(const flutter::EncodableValue* args,
                              std::unique_ptr<flutter::MethodResult<>> result);

  // Event streaming (violations)
  void SendViolationEvent(const std::string& event_type);

  // Hooks
  static LRESULT CALLBACK KeyboardProc(int nCode, WPARAM wParam, LPARAM lParam);
  static LRESULT CALLBACK ClipboardProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);

  HWND window_handle_;
  HHOOK keyboard_hook_;
  HWND clipboard_listener_;
  bool fullscreen_active_;
  bool shortcuts_blocked_;
  bool clipboard_blocked_;

  std::unique_ptr<flutter::EventSink<>> window_event_sink_;
  std::unique_ptr<flutter::EventSink<>> process_event_sink_;
  std::unique_ptr<flutter::EventSink<>> shortcut_event_sink_;

  static LockdownPlugin* instance_;  // For static hook callbacks
};

}  // namespace lockdown

#endif  // LOCKDOWN_PLUGIN_H
```

---

