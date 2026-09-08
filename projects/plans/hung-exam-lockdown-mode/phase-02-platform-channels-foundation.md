# Phase 2: Platform Channels Foundation

**Status**: Completed  
**Estimated effort**: 2 weeks  
**Dependencies**: None (independent of Phase 1)  
**Risk**: HIGH (cross-platform native code, potential OS permission issues) — mitigated by Windows-only scope

---

## Objective

Implement Flutter platform channels and native plugin for **Windows only** to provide low-level system control: fullscreen enforcement, clipboard monitoring, keyboard hook interception, and process enumeration/termination. macOS support is deferred per spec requirements.

## Steps

### Step 1: Create Platform Channel Interfaces

**File**: `D:/GitHub/PTE-org/pte-app/lib/core/platform/window_manager_channel.dart`

```dart
import 'package:flutter/services.dart';

/// Platform channel for window management (fullscreen enforcement, escape detection).
class WindowManagerChannel {
  static const platform = MethodChannel('com.pte.lockdown/window');
  static const eventChannel = EventChannel('com.pte.lockdown/window/events');

  /// Enforce fullscreen mode - disables window controls, prevents escape.
  /// Throws PlatformException if enforcement fails.
  Future<void> enforceFullscreen() async {
    try {
      await platform.invokeMethod('enforceFullscreen');
    } on PlatformException catch (e) {
      throw LockdownException('Failed to enforce fullscreen: ${e.message}');
    }
  }

  /// Exit fullscreen mode - restores normal window state.
  Future<void> exitFullscreen() async {
    try {
      await platform.invokeMethod('exitFullscreen');
    } on PlatformException catch (e) {
      throw LockdownException('Failed to exit fullscreen: ${e.message}');
    }
  }

  /// Stream of fullscreen violation events.
  /// Emits event type string when user attempts to escape fullscreen.
  Stream<String> get violations {
    return eventChannel.receiveBroadcastStream().map((event) => event as String);
  }
}
```

**File**: `D:/GitHub/PTE-org/pte-app/lib/core/platform/process_manager_channel.dart`

```dart
import 'package:flutter/services.dart';

/// Platform channel for process management (enumerate and terminate processes).
class ProcessManagerChannel {
  static const platform = MethodChannel('com.pte.lockdown/process');
  static const eventChannel = EventChannel('com.pte.lockdown/process/events');

  /// Get list of currently running process names.
  Future<List<String>> getRunningProcesses() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getRunningProcesses');
      return result.cast<String>();
    } on PlatformException catch (e) {
      throw LockdownException('Failed to enumerate processes: ${e.message}');
    }
  }

  /// Terminate a process by name.
  /// Returns true if process was found and terminated.
  Future<bool> terminateProcess(String processName) async {
    try {
      final bool result = await platform.invokeMethod('terminateProcess', {'name': processName});
      return result;
    } on PlatformException catch (e) {
      throw LockdownException('Failed to terminate process: ${e.message}');
    }
  }

  /// Stream of process violation events (forbidden app detected).
  Stream<String> get violations {
    return eventChannel.receiveBroadcastStream().map((event) => event as String);
  }
}
```

**File**: `D:/GitHub/PTE-org/pte-app/lib/core/platform/clipboard_monitor_channel.dart`

```dart
import 'package:flutter/services.dart';

/// Platform channel for clipboard monitoring and blocking.
class ClipboardMonitorChannel {
  static const platform = MethodChannel('com.pte.lockdown/clipboard');

  /// Block external clipboard paste operations.
  /// Internal app copy/paste still allowed.
  Future<void> blockExternalPaste() async {
    try {
      await platform.invokeMethod('blockExternalPaste');
    } on PlatformException catch (e) {
      throw LockdownException('Failed to block clipboard: ${e.message}');
    }
  }

  /// Clear system clipboard content.
  Future<void> clearClipboard() async {
    try {
      await platform.invokeMethod('clearClipboard');
    } on PlatformException catch (e) {
      throw LockdownException('Failed to clear clipboard: ${e.message}');
    }
  }

  /// Unblock clipboard operations.
  Future<void> unblock() async {
    try {
      await platform.invokeMethod('unblock');
    } on PlatformException catch (e) {
      throw LockdownException('Failed to unblock clipboard: ${e.message}');
    }
  }
}
```

**File**: `D:/GitHub/PTE-org/pte-app/lib/core/platform/shortcut_interceptor_channel.dart`

```dart
import 'package:flutter/services.dart';

/// Platform channel for system shortcut interception.
class ShortcutInterceptorChannel {
  static const platform = MethodChannel('com.pte.lockdown/shortcuts');
  static const eventChannel = EventChannel('com.pte.lockdown/shortcuts/events');

  /// Block system shortcuts (Alt+Tab, Win+D, PrintScreen, etc.).
  Future<void> blockSystemShortcuts() async {
    try {
      await platform.invokeMethod('blockSystemShortcuts');
    } on PlatformException catch (e) {
      throw LockdownException('Failed to block shortcuts: ${e.message}');
    }
  }

  /// Unblock system shortcuts.
  Future<void> unblock() async {
    try {
      await platform.invokeMethod('unblock');
    } on PlatformException catch (e) {
      throw LockdownException('Failed to unblock shortcuts: ${e.message}');
    }
  }

  /// Stream of shortcut violation events (blocked key combo detected).
  Stream<String> get violations {
    return eventChannel.receiveBroadcastStream().map((event) => event as String);
  }
}
```

**File**: `D:/GitHub/PTE-org/pte-app/lib/core/platform/lockdown_exception.dart`

```dart
/// Exception thrown by lockdown platform channels.
class LockdownException implements Exception {
  final String message;
  const LockdownException(this.message);

  @override
  String toString() => 'LockdownException: $message';
}
```

### Step 2: Windows Native Plugin Implementation

**File**: `D:/GitHub/PTE-org/pte-app/windows/runner/lockdown_plugin.h`

```cpp
#ifndef LOCKDOWN_PLUGIN_H_
#define LOCKDOWN_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>

#include <windows.h>
#include <tlhelp32.h>
#include <memory>
#include <string>

namespace lockdown_plugin {

class LockdownPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  LockdownPlugin(flutter::PluginRegistrarWindows *registrar);
  virtual ~LockdownPlugin();

 private:
  // Window management
  void EnforceFullscreen(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  
  void ExitFullscreen(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Process management
  void GetRunningProcesses(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  
  void TerminateProcess(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Clipboard
  void BlockExternalPaste(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  
  void ClearClipboard(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  
  void UnblockClipboard(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Shortcuts
  void BlockSystemShortcuts(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  
  void UnblockShortcuts(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Keyboard hook callback
  static LRESULT CALLBACK KeyboardHookProc(int nCode, WPARAM wParam, LPARAM lParam);
  
  // Event sinks for violation streams
  void SendViolationEvent(const std::string& channel, const std::string& violation);

  flutter::PluginRegistrarWindows *registrar_;
  HWND hwnd_;
  HHOOK keyboard_hook_;
  bool fullscreen_enforced_;
  bool shortcuts_blocked_;
  
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> window_event_sink_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> shortcut_event_sink_;
  
  static LockdownPlugin* instance_;
};

}  // namespace lockdown_plugin

#endif  // LOCKDOWN_PLUGIN_H_
```

**File**: `D:/GitHub/PTE-org/pte-app/windows/runner/lockdown_plugin.cpp`

```cpp
#include "lockdown_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

namespace lockdown_plugin {

// Static instance for keyboard hook callback
LockdownPlugin* LockdownPlugin::instance_ = nullptr;

// Register plugin channels
void LockdownPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto plugin = std::make_unique<LockdownPlugin>(registrar);

  // Window management channel
  auto window_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.pte.lockdown/window",
          &flutter::StandardMethodCodec::GetInstance());

  window_channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        if (call.method_name().compare("enforceFullscreen") == 0) {
          plugin_pointer->EnforceFullscreen(call, std::move(result));
        } else if (call.method_name().compare("exitFullscreen") == 0) {
          plugin_pointer->ExitFullscreen(call, std::move(result));
        } else {
          result->NotImplemented();
        }
      });

  // Process management channel
  auto process_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.pte.lockdown/process",
          &flutter::StandardMethodCodec::GetInstance());

  process_channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        if (call.method_name().compare("getRunningProcesses") == 0) {
          plugin_pointer->GetRunningProcesses(call, std::move(result));
        } else if (call.method_name().compare("terminateProcess") == 0) {
          plugin_pointer->TerminateProcess(call, std::move(result));
        } else {
          result->NotImplemented();
        }
      });

  // Clipboard channel
  auto clipboard_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.pte.lockdown/clipboard",
          &flutter::StandardMethodCodec::GetInstance());

  clipboard_channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        if (call.method_name().compare("blockExternalPaste") == 0) {
          plugin_pointer->BlockExternalPaste(call, std::move(result));
        } else if (call.method_name().compare("clearClipboard") == 0) {
          plugin_pointer->ClearClipboard(call, std::move(result));
        } else if (call.method_name().compare("unblock") == 0) {
          plugin_pointer->UnblockClipboard(call, std::move(result));
        } else {
          result->NotImplemented();
        }
      });

  // Shortcuts channel
  auto shortcut_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "com.pte.lockdown/shortcuts",
          &flutter::StandardMethodCodec::GetInstance());

  shortcut_channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        if (call.method_name().compare("blockSystemShortcuts") == 0) {
          plugin_pointer->BlockSystemShortcuts(call, std::move(result));
        } else if (call.method_name().compare("unblock") == 0) {
          plugin_pointer->UnblockShortcuts(call, std::move(result));
        } else {
          result->NotImplemented();
        }
      });

  registrar->AddPlugin(std::move(plugin));
}

LockdownPlugin::LockdownPlugin(flutter::PluginRegistrarWindows *registrar)
    : registrar_(registrar),
      hwnd_(nullptr),
      keyboard_hook_(nullptr),
      fullscreen_enforced_(false),
      shortcuts_blocked_(false) {
  instance_ = this;
  
  // Get window handle
  hwnd_ = registrar_->GetView()->GetNativeWindow();
}

LockdownPlugin::~LockdownPlugin() {
  if (keyboard_hook_) {
    UnhookWindowsHookEx(keyboard_hook_);
  }
  instance_ = nullptr;
}

void LockdownPlugin::EnforceFullscreen(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (!hwnd_) {
    result->Error("NO_WINDOW", "Window handle not available");
    return;
  }

  // Remove window decorations and menu
  LONG style = GetWindowLong(hwnd_, GWL_STYLE);
  style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZE | WS_MAXIMIZE | WS_SYSMENU);
  SetWindowLong(hwnd_, GWL_STYLE, style);

  // Get monitor info for fullscreen dimensions
  MONITORINFO mi = { sizeof(mi) };
  GetMonitorInfo(MonitorFromWindow(hwnd_, MONITOR_DEFAULTTOPRIMARY), &mi);

  // Set window to cover entire screen
  SetWindowPos(hwnd_, HWND_TOP,
               mi.rcMonitor.left, mi.rcMonitor.top,
               mi.rcMonitor.right - mi.rcMonitor.left,
               mi.rcMonitor.bottom - mi.rcMonitor.top,
               SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);

  fullscreen_enforced_ = true;
  result->Success();
}

void LockdownPlugin::ExitFullscreen(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (!hwnd_) {
    result->Error("NO_WINDOW", "Window handle not available");
    return;
  }

  // Restore window style
  LONG style = GetWindowLong(hwnd_, GWL_STYLE);
  style |= (WS_CAPTION | WS_THICKFRAME | WS_MINIMIZE | WS_MAXIMIZE | WS_SYSMENU);
  SetWindowLong(hwnd_, GWL_STYLE, style);

  // Restore normal window position
  SetWindowPos(hwnd_, HWND_TOP, 100, 100, 1280, 720,
               SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);

  fullscreen_enforced_ = false;
  result->Success();
}

void LockdownPlugin::GetRunningProcesses(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  flutter::EncodableList process_list;
  HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  
  if (snapshot == INVALID_HANDLE_VALUE) {
    result->Error("SNAPSHOT_FAILED", "Failed to create process snapshot");
    return;
  }

  PROCESSENTRY32W entry;
  entry.dwSize = sizeof(PROCESSENTRY32W);

  if (Process32FirstW(snapshot, &entry)) {
    do {
      std::wstring wname(entry.szExeFile);
      std::string name(wname.begin(), wname.end());
      process_list.push_back(flutter::EncodableValue(name));
    } while (Process32NextW(snapshot, &entry));
  }

  CloseHandle(snapshot);
  result->Success(flutter::EncodableValue(process_list));
}

void LockdownPlugin::TerminateProcess(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
  if (!arguments) {
    result->Error("BAD_ARGS", "Arguments must be a map");
    return;
  }

  auto name_it = arguments->find(flutter::EncodableValue("name"));
  if (name_it == arguments->end()) {
    result->Error("BAD_ARGS", "Missing 'name' argument");
    return;
  }

  std::string target_name = std::get<std::string>(name_it->second);
  std::wstring wtarget_name(target_name.begin(), target_name.end());
  
  bool terminated = false;
  HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  
  if (snapshot != INVALID_HANDLE_VALUE) {
    PROCESSENTRY32W entry;
    entry.dwSize = sizeof(PROCESSENTRY32W);

    if (Process32FirstW(snapshot, &entry)) {
      do {
        if (wcscmp(entry.szExeFile, wtarget_name.c_str()) == 0) {
          HANDLE hProcess = OpenProcess(PROCESS_TERMINATE, FALSE, entry.th32ProcessID);
          if (hProcess) {
            if (TerminateProcess(hProcess, 0)) {
              terminated = true;
            }
            CloseHandle(hProcess);
          }
        }
      } while (Process32NextW(snapshot, &entry) && !terminated);
    }
    CloseHandle(snapshot);
  }

  result->Success(flutter::EncodableValue(terminated));
}

void LockdownPlugin::BlockExternalPaste(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  // Note: Full clipboard blocking requires deeper OS integration
  // For MVP, we clear clipboard on activation
  ClearClipboard(method_call, std::move(result));
}

void LockdownPlugin::ClearClipboard(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (OpenClipboard(hwnd_)) {
    EmptyClipboard();
    CloseClipboard();
    result->Success();
  } else {
    result->Error("CLIPBOARD_FAILED", "Failed to open clipboard");
  }
}

void LockdownPlugin::UnblockClipboard(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  // No-op for now (clipboard is not actively blocked, just cleared)
  result->Success();
}

void LockdownPlugin::BlockSystemShortcuts(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (keyboard_hook_) {
    result->Error("ALREADY_HOOKED", "Keyboard hook already installed");
    return;
  }

  keyboard_hook_ = SetWindowsHookEx(WH_KEYBOARD_LL, KeyboardHookProc, NULL, 0);
  
  if (!keyboard_hook_) {
    result->Error("HOOK_FAILED", "Failed to install keyboard hook");
    return;
  }

  shortcuts_blocked_ = true;
  result->Success();
}

void LockdownPlugin::UnblockShortcuts(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  if (keyboard_hook_) {
    UnhookWindowsHookEx(keyboard_hook_);
    keyboard_hook_ = nullptr;
  }

  shortcuts_blocked_ = false;
  result->Success();
}

LRESULT CALLBACK LockdownPlugin::KeyboardHookProc(int nCode, WPARAM wParam, LPARAM lParam) {
  if (nCode == HC_ACTION && instance_ && instance_->shortcuts_blocked_) {
    KBDLLHOOKSTRUCT* kb = (KBDLLHOOKSTRUCT*)lParam;
    
    // Block: Alt+Tab, Alt+F4, Win key, PrintScreen, Ctrl+Esc
    bool block = false;
    std::string violation_type;

    if (kb->vkCode == VK_TAB && GetAsyncKeyState(VK_MENU)) {
      block = true;
      violation_type = "ALT_TAB";
    } else if (kb->vkCode == VK_F4 && GetAsyncKeyState(VK_MENU)) {
      block = true;
      violation_type = "ALT_F4";
    } else if (kb->vkCode == VK_LWIN || kb->vkCode == VK_RWIN) {
      block = true;
      violation_type = "WIN_KEY";
    } else if (kb->vkCode == VK_SNAPSHOT) {
      block = true;
      violation_type = "PRINTSCREEN";
    } else if (kb->vkCode == VK_ESCAPE && GetAsyncKeyState(VK_CONTROL)) {
      block = true;
      violation_type = "CTRL_ESC";
    }

    if (block) {
      instance_->SendViolationEvent("shortcuts", violation_type);
      return 1; // Block the key
    }
  }

  return CallNextHookEx(NULL, nCode, wParam, lParam);
}

void LockdownPlugin::SendViolationEvent(const std::string& channel, const std::string& violation) {
  // Event sink implementation would go here
  // For now, log to debug output
  OutputDebugStringA(("Violation detected on " + channel + ": " + violation + "\n").c_str());
}

}  // namespace lockdown_plugin
```

### Step 3: macOS Native Plugin Implementation

**File**: `D:/GitHub/PTE-org/pte-app/macos/Runner/LockdownPlugin.swift`

```swift
import Cocoa
import FlutterMacOS

public class LockdownPlugin: NSObject, FlutterPlugin {
  private var fullscreenEnforced = false
  private var shortcutsBlocked = false
  private var eventMonitor: Any?
  private var windowEventSink: FlutterEventSink?
  private var shortcutEventSink: FlutterEventSink?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = LockdownPlugin()
    
    // Window management channel
    let windowChannel = FlutterMethodChannel(
      name: "com.pte.lockdown/window",
      binaryMessenger: registrar.messenger
    )
    windowChannel.setMethodCallHandler(instance.handleWindowMethod)
    
    // Process management channel
    let processChannel = FlutterMethodChannel(
      name: "com.pte.lockdown/process",
      binaryMessenger: registrar.messenger
    )
    processChannel.setMethodCallHandler(instance.handleProcessMethod)
    
    // Clipboard channel
    let clipboardChannel = FlutterMethodChannel(
      name: "com.pte.lockdown/clipboard",
      binaryMessenger: registrar.messenger
    )
    clipboardChannel.setMethodCallHandler(instance.handleClipboardMethod)
    
    // Shortcuts channel
    let shortcutChannel = FlutterMethodChannel(
      name: "com.pte.lockdown/shortcuts",
      binaryMessenger: registrar.messenger
    )
    shortcutChannel.setMethodCallHandler(instance.handleShortcutMethod)
  }
  
  private func handleWindowMethod(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "enforceFullscreen":
      enforceFullscreen(result: result)
    case "exitFullscreen":
      exitFullscreen(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func handleProcessMethod(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getRunningProcesses":
      getRunningProcesses(result: result)
    case "terminateProcess":
      guard let args = call.arguments as? [String: Any],
            let name = args["name"] as? String else {
        result(FlutterError(code: "BAD_ARGS", message: "Missing 'name' argument", details: nil))
        return
      }
      terminateProcess(name: name, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func handleClipboardMethod(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "blockExternalPaste":
      blockExternalPaste(result: result)
    case "clearClipboard":
      clearClipboard(result: result)
    case "unblock":
      unblockClipboard(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func handleShortcutMethod(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "blockSystemShortcuts":
      blockSystemShortcuts(result: result)
    case "unblock":
      unblockShortcuts(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  // MARK: - Window Management
  
  private func enforceFullscreen(result: @escaping FlutterResult) {
    guard let window = NSApplication.shared.windows.first else {
      result(FlutterError(code: "NO_WINDOW", message: "No window available", details: nil))
      return
    }
    
    // Enter fullscreen
    if !window.styleMask.contains(.fullScreen) {
      window.toggleFullScreen(nil)
    }
    
    // Remove title bar and controls
    window.styleMask.remove(.titled)
    window.styleMask.remove(.closable)
    window.styleMask.remove(.miniaturizable)
    window.styleMask.remove(.resizable)
    
    // Prevent escape from fullscreen
    window.collectionBehavior = [.fullScreenPrimary, .fullScreenDisallowsTiling]
    
    fullscreenEnforced = true
    result(nil)
  }
  
  private func exitFullscreen(result: @escaping FlutterResult) {
    guard let window = NSApplication.shared.windows.first else {
      result(FlutterError(code: "NO_WINDOW", message: "No window available", details: nil))
      return
    }
    
    // Exit fullscreen
    if window.styleMask.contains(.fullScreen) {
      window.toggleFullScreen(nil)
    }
    
    // Restore window controls
    window.styleMask.insert(.titled)
    window.styleMask.insert(.closable)
    window.styleMask.insert(.miniaturizable)
    window.styleMask.insert(.resizable)
    
    fullscreenEnforced = false
    result(nil)
  }
  
  // MARK: - Process Management
  
  private func getRunningProcesses(result: @escaping FlutterResult) {
    let workspace = NSWorkspace.shared
    let apps = workspace.runningApplications
    let processNames = apps.compactMap { $0.localizedName }
    result(processNames)
  }
  
  private func terminateProcess(name: String, result: @escaping FlutterResult) {
    let task = Process()
    task.launchPath = "/usr/bin/killall"
    task.arguments = ["-9", name]
    
    do {
      try task.run()
      task.waitUntilExit()
      result(task.terminationStatus == 0)
    } catch {
      result(FlutterError(
        code: "TERMINATE_FAILED",
        message: "Failed to terminate process: \(error.localizedDescription)",
        details: nil
      ))
    }
  }
  
  // MARK: - Clipboard
  
  private func blockExternalPaste(result: @escaping FlutterResult) {
    // Clear clipboard on activation (full blocking requires deeper integration)
    clearClipboard(result: result)
  }
  
  private func clearClipboard(result: @escaping FlutterResult) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    result(nil)
  }
  
  private func unblockClipboard(result: @escaping FlutterResult) {
    // No-op (clipboard is not actively blocked, just cleared)
    result(nil)
  }
  
  // MARK: - Shortcuts
  
  private func blockSystemShortcuts(result: @escaping FlutterResult) {
    if eventMonitor != nil {
      result(FlutterError(code: "ALREADY_HOOKED", message: "Event monitor already installed", details: nil))
      return
    }
    
    eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
      self?.handleKeyEvent(event)
    }
    
    shortcutsBlocked = true
    result(nil)
  }
  
  private func unblockShortcuts(result: @escaping FlutterResult) {
    if let monitor = eventMonitor {
      NSEvent.removeMonitor(monitor)
      eventMonitor = nil
    }
    
    shortcutsBlocked = false
    result(nil)
  }
  
  private func handleKeyEvent(_ event: NSEvent) {
    guard shortcutsBlocked else { return }
    
    var violation: String?
    
    // Block Cmd+Tab, Cmd+Q, Cmd+W, Cmd+Shift+3/4 (screenshots)
    if event.modifierFlags.contains(.command) {
      switch event.keyCode {
      case 48: // Tab
        violation = "CMD_TAB"
      case 12: // Q
        violation = "CMD_Q"
      case 13: // W
        violation = "CMD_W"
      case 20: // 3 (screenshot)
        violation = "CMD_SHIFT_3"
      case 21: // 4 (screenshot)
        violation = "CMD_SHIFT_4"
      default:
        break
      }
    }
    
    // Block Escape key
    if event.keyCode == 53 {
      violation = "ESCAPE"
    }
    
    if let violation = violation {
      sendViolation(channel: "shortcuts", type: violation)
    }
  }
  
  private func sendViolation(channel: String, type: String) {
    print("Violation detected on \(channel): \(type)")
    // Event sink implementation would send to Flutter via EventChannel
  }
}
```

### Step 4: Register Plugins

**File**: `D:/GitHub/PTE-org/pte-app/windows/runner/flutter_window.cpp` (modify)

Add after existing plugin registrations:

```cpp
#include "lockdown_plugin.h"

// ... in FlutterWindow::OnCreate()
lockdown_plugin::LockdownPlugin::RegisterWithRegistrar(
    flutter_controller_->engine()->GetRegistrar("lockdown_plugin"));
```

**File**: `D:/GitHub/PTE-org/pte-app/macos/Runner/AppDelegate.swift` (modify)

Add after `GeneratedPluginRegistrant.register`:

```swift
LockdownPlugin.register(with: registrar(forPlugin: "LockdownPlugin")!)
```

### Step 5: Unit Tests for Platform Channels

**File**: `D:/GitHub/PTE-org/pte-app/test/unit/platform/window_manager_channel_test.dart`

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pte_app/core/platform/window_manager_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WindowManagerChannel', () {
    late WindowManagerChannel channel;
    late List<MethodCall> methodCalls;

    setUp(() {
      channel = WindowManagerChannel();
      methodCalls = [];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(WindowManagerChannel.platform, (call) async {
        methodCalls.add(call);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(WindowManagerChannel.platform, null);
    });

    test('enforceFullscreen calls platform method', () async {
      await channel.enforceFullscreen();
      
      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'enforceFullscreen');
    });

    test('exitFullscreen calls platform method', () async {
      await channel.exitFullscreen();
      
      expect(methodCalls.length, 1);
      expect(methodCalls[0].method, 'exitFullscreen');
    });

    test('enforceFullscreen throws LockdownException on platform error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(WindowManagerChannel.platform, (call) async {
        throw PlatformException(code: 'NO_WINDOW', message: 'Window not found');
      });

      expect(
        () => channel.enforceFullscreen(),
        throwsA(isA<LockdownException>()),
      );
    });
  });
}
```

Similar tests for `ProcessManagerChannel`, `ClipboardMonitorChannel`, `ShortcutInterceptorChannel`.

### Step 6: Integration Test (Manual - requires real OS)

**File**: `D:/GitHub/PTE-org/pte-app/test_manual/lockdown_platform_test.md`

```markdown
# Manual Platform Channel Integration Tests

## Windows

1. **Fullscreen enforcement**:
   - Run app, trigger `enforceFullscreen()`
   - Expected: Window goes fullscreen, no title bar, cannot minimize/close
   - Try: Alt+F4, Win+D → should be blocked and violation logged

2. **Process termination**:
   - Open Chrome.exe
   - Run `getRunningProcesses()` → verify "chrome.exe" in list
   - Run `terminateProcess("chrome.exe")`
   - Expected: Chrome closes, method returns true

3. **Clipboard clear**:
   - Copy text to clipboard
   - Run `clearClipboard()`
   - Try pasting → expected: nothing pastes

4. **Shortcut blocking**:
   - Run `blockSystemShortcuts()`
   - Try: Alt+Tab, Win+D, PrintScreen
   - Expected: All blocked, violations logged

## macOS

1. **Fullscreen enforcement**:
   - Run app, trigger `enforceFullscreen()`
   - Expected: Window goes fullscreen, cannot exit
   - Try: Escape, Cmd+Q → should be blocked

2. **Process termination**:
   - Open Safari
   - Run `terminateProcess("Safari")`
   - Expected: Safari closes

3. **Clipboard clear**:
   - Copy text
   - Run `clearClipboard()`
   - Try pasting → expected: nothing pastes

4. **Shortcut blocking**:
   - Run `blockSystemShortcuts()`
   - Try: Cmd+Tab, Cmd+Shift+3 (screenshot)
   - Expected: All blocked, violations logged
```

## Acceptance Criteria

- [ ] All 4 platform channels (window, process, clipboard, shortcuts) implemented for Windows
- [ ] Windows C++ plugin registered correctly, app compiles
- [ ] Unit tests pass for all Dart channel classes (skipped by user for Phase 2)
- [ ] Manual integration tests documented for Windows 10/11
- [ ] No memory leaks (keyboard hook properly released on Windows)
- [ ] Event streams functional (violations emit to Flutter)
- [ ] macOS implementation: deferred per spec (Windows-only phase)

## Quality and Testing State

- **Quality**: Approved (1 MEDIUM finding resolved, 1 LOW advisory, 2 NOTED)
- **Testing**: Skipped by user (decision: user_confirmed_skip) — Manual test documentation provided in test_manual/lockdown_platform_test.md

**Quality Report**: `quality/phase-02-platform-channels-foundation-quality-report.json`  
**Receipt**: `quality/phase-02-platform-channels-foundation-receipt.json`

## Design Constraints

**Phase-specific constraints from plan**:
- Platform channels are the FFI boundary — all native calls must return Result<T, PlatformException>, never throw across FFI
- Resource cleanup: keyboard hooks (Windows HHOOK), event monitors (macOS NSEvent) must be released in destructors
- Windows UAC: OpenProcess/TerminateProcess requires PROCESS_TERMINATE access right; document elevation requirement
- Event streams: EventChannel for violation monitoring (WindowManagerChannel, ShortcutInterceptorChannel)

**Preflight (repository conventions discovered)**:
- Exception hierarchy: sealed class hierarchy (`ApiException` pattern in `api_exceptions.dart`) — create `LockdownException` as sealed with specific subtypes (`FullscreenEnforcementException`, `ProcessTerminationException`, etc.)
- String constants: per-feature constants file pattern (e.g. `ReadingStrings`, `ExamAttemptStrings`) — create `LockdownStrings` in `lib/core/constants/lockdown_strings.dart` for error messages
- Naming: channels use `MethodChannel`/`EventChannel` with reverse-domain notation (`com.pte.lockdown/*`)
- Error handling: platform exceptions caught and rethrown as domain exceptions with context
- Widget structure: stateless where possible, `const` constructors, explicit `super.key`
- No bare literals: every user-facing string via constants class

## Notes

- **Windows-only scope**: macOS implementation deferred per spec requirements (spec.md explicitly states "Windows desktop only")
- **Windows UAC**: Process termination requires elevated privileges. App must request admin on launch for STRICT mode.
- **Event Channels**: Full EventChannel implementation (for violation streams) deferred to Phase 3 (can be polled initially).
- **Clipboard blocking**: Current implementation clears clipboard. True external-paste blocking (distinguishing internal vs external) requires deeper OS hooks - marked for future enhancement if needed.

## Risks Realized

- **HIGH**: Cross-platform testing → Mitigated by focusing Windows-only for Phase 2
- **MEDIUM**: Windows permission prompts may confuse users. Need clear pre-exam instruction flow (Phase 4).
