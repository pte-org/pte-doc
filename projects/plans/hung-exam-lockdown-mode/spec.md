# Spec: Exam Lockdown Mode

**Date:** 2026-09-07
**Author:** Hung
**Status:** Draft

---

## Problem Statement

Hiện tại pte-app (Flutter desktop) không có cơ chế bảo mật nào để ngăn chặn gian lận trong quá trình thi. Students có thể:
- Thoát khỏi fullscreen và mở ứng dụng khác
- Copy/paste nội dung từ external sources
- Chụp màn hình hoặc record screen
- Sử dụng phím tắt hệ thống (Alt+Tab, Win+D, etc.)
- Chạy các ứng dụng messaging/collaboration trong background

Điều này làm giảm tính toàn vẹn của kỳ thi, đặc biệt với REAL_EXAM mode.

**Note:** This implementation focuses on Windows desktop only. macOS support is deferred to future phases.

## Goals

Implement một lockdown mode cho Flutter desktop app (Windows) để:

1. **Enforce fullscreen**: Bắt buộc fullscreen không thể thoát ra trong suốt exam attempt
2. **Block clipboard**: Vô hiệu hóa paste từ external sources (cho phép copy/paste nội bộ trong app)
3. **Disable system shortcuts**: Block Alt+Tab, Win+D, Cmd+Tab, screenshot keys
4. **Terminate forbidden apps**: Tự động kill các ứng dụng third-party đã định nghĩa trước
5. **Real-time violation reporting**: Gửi violations đến proctor qua WebSocket ngay lập tức

## Non-Goals

- **Mobile platforms** (iOS/Android): Out of scope, chỉ focus vào desktop
- **macOS support**: Deferred to future phases, hiện tại chỉ Windows
- **Linux support**: Có thể thêm sau
- **Network monitoring**: Không theo dõi network traffic trong version này
- **Screen recording detection**: Chỉ block screenshot keys, không detect screen recording software
- **VM detection**: Không detect virtual machines trong phase này
- **At-rest encryption**: Violations chỉ lưu local, không encrypt database

## Architecture

### Backend Changes

#### 1. ExamPolicy Extension

**Entity**: `services/scheduling/src/main/java/com/pte/scheduling/domain/ExamPolicy.java`

```java
public enum LockdownMode {
    NONE,      // No lockdown (practice mode)
    STANDARD,  // Warning only, violations logged
    STRICT     // Full enforcement + real-time reporting
}
```

Add field:
```java
@Enumerated(EnumType.STRING)
@Column(name = "lockdown_mode")
private LockdownMode lockdownMode;
```

Default mappings:
- `PRACTICE` → `LockdownMode.NONE`
- `MOCK_TEST` → `LockdownMode.STANDARD`
- `REAL_EXAM` → `LockdownMode.STRICT`

#### 2. DTO Flow

Flow: `ExamPolicy` → `ExamPolicyResponse` → `SchedulingEntitlementResponse` → `AttemptTaskResponse` → Flutter app

All DTOs extend với `lockdownMode` field.

#### 3. Violation Infrastructure

Extend existing `ViolationType` enum in `services/proctor/src/main/java/com/pte/proctor/domain/enums/ViolationType.java`:

```java
LOCKDOWN_FULLSCREEN_EXIT,
LOCKDOWN_CLIPBOARD_PASTE,
LOCKDOWN_SCREENSHOT_ATTEMPT,
LOCKDOWN_SHORTCUT_BLOCKED,
LOCKDOWN_FORBIDDEN_APP_DETECTED
```

Reuse existing endpoint: `POST /api/proctor/violations`

### Flutter App Changes

#### 1. Platform Channels

Four platform channels for native integration (Windows only):

```dart
// lib/core/platform/window_manager_channel.dart
class WindowManagerChannel {
  Future<void> enforceFullscreen();
  Future<void> exitFullscreen();
  Stream<String> get fullscreenViolations;
}

// lib/core/platform/process_manager_channel.dart
class ProcessManagerChannel {
  Future<List<String>> getForbiddenProcesses();
  Future<void> terminateProcess(String processName);
  Stream<String> get processViolations;
}

// lib/core/platform/clipboard_monitor_channel.dart
class ClipboardMonitorChannel {
  Future<void> blockExternalPaste();
  Future<void> clearClipboard();
  Future<void> unblock();
}

// lib/core/platform/shortcut_interceptor_channel.dart
class ShortcutInterceptorChannel {
  Future<void> blockSystemShortcuts();
  Future<void> unblock();
  Stream<String> get shortcutViolations;
}
```

#### 2. LockdownService

```dart
class LockdownService {
  Future<void> activateLockdown(LockdownMode mode);
  Future<void> deactivateLockdown();
  void _startViolationMonitoring();
  Future<void> _handleViolation(String type);
  Future<void> _terminateForbiddenApps();
}
```

Integration points:
- Activate on `ExamAttemptBloc._onStartOrResumeAttempt`
- Deactivate on `ExamAttemptBloc._onCompleteAttempt`

#### 3. Native Implementations

**Windows** (`windows/runner/lockdown_plugin.cpp`):
- SetWindowLong for fullscreen
- SetWindowsHookEx(WH_KEYBOARD_LL) for keyboard hooks
- CreateToolhelp32Snapshot + TerminateProcess for app termination

### Configuration

**Forbidden apps list**: `assets/config/forbidden_apps.json`

```json
{
  "windows": ["chrome.exe", "firefox.exe", "discord.exe", "teams.exe", ...]
}
```

Configurable per deployment, không hardcode trong source.

## User Experience

### STRICT Mode Flow

1. **Pre-exam check**: Khi user click Start Exam, app:
   - Check forbidden apps đang chạy
   - Hiển thị dialog yêu cầu đóng apps
   - Retry button để check lại

2. **Lockdown activation**: Khi tất cả checks pass:
   - Enter fullscreen
   - Clear clipboard
   - Block shortcuts
   - Terminate remaining forbidden apps (with admin rights)
   - Hiển thị brief notification "Exam Security Mode Active"

3. **During exam**:
   - Không có UI indication (clean exam experience)
   - Violations gửi silent đến proctor
   - Không interrupt student với warnings (STRICT mode)

4. **Lockdown deactivation**: Khi submit hoặc timeout:
   - Exit fullscreen
   - Restore clipboard
   - Unblock shortcuts
   - Brief notification "You may now exit"

### STANDARD Mode Flow

Similar to STRICT, nhưng:
- Không auto-terminate apps (chỉ warning)
- Hiển thị yellow banner khi detect violation
- Không block hoàn toàn, chỉ log

### Error Handling

**Activation failure**:
```
Cannot Start Exam
The following security checks failed:
• Chrome is still running
• Unable to enter fullscreen mode

Please close all forbidden applications and try again.
[Retry] [Cancel]
```

**Violation banner** (STANDARD mode only):
```
⚠️ Security Notice: External paste detected. This action has been logged.
```

## Security Considerations

1. **Admin privileges**: Windows process termination requires UAC elevation
   - Request elevation on app launch for STRICT sessions
   - Fallback to warning-only if denied

2. **Bypass prevention**:
   - Hash-check native plugin binaries on startup
   - Monitor for process injection attempts
   - Log all lockdown state transitions

3. **Privacy**:
   - Only monitor during active exam attempt
   - Clear all hooks on completion
   - No persistent background monitoring

4. **Fail-safe**:
   - If lockdown activation fails completely → block exam start
   - Partial failures (e.g., one shortcut not blocked) → log but allow (don't fail entire exam)

**Database migration** (Postgres):
```sql
ALTER TABLE exam_sessions 
ADD COLUMN lockdown_mode VARCHAR(20) DEFAULT 'NONE';
```

**Proctor violations**: Reuse existing `violation_events` table, just add new `ViolationType` enums.

### Flutter

**Drift table**:
```dart
class LocalViolations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get attemptPublicId => text()();
  TextColumn get violationType => text()();
  TextColumn get severity => text()();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get sent => boolean().withDefault(const Constant(false))();
}
```

Offline-first: violations lưu local trước, sync lên backend khi có network.

## Testing Strategy

### Unit Tests
- LockdownService activation/deactivation
- ViolationReporter offline queueing
- Platform channel mocks

### Integration Tests
- End-to-end lockdown flow
- Violation reporting with retry
- Platform channel actual behavior (requires real desktop environment)

### Manual QA
- Windows: Try Alt+Tab, Win+D, PrintScreen, external paste
- Verify proctor receives real-time notifications
- Test with/without admin rights
- Test activation failure scenarios

## Rollout Plan

### Phase 1: Backend Policy (Week 1)
- Extend ExamPolicy with LockdownMode
- DTOs & mappers
- Database migration
- Unit tests

### Phase 2: Native Plugin (Week 2-3)
- Windows C++ implementation
- Platform channel Dart wrappers
- Cross-platform interop tests

### Phase 3: Flutter Service Layer (Week 4)
- LockdownService
- ViolationReporter
- ExamAttemptBloc integration
- Unit tests

### Phase 4: UI & QA (Week 5)
- Activation failure dialogs
- Violation banners (STANDARD mode)
- Manual QA on Windows
- Proctor dashboard verification

### Phase 5: Production (Week 6)
- Deploy backend
- Release Flutter app update (with gradual rollout flag)
- Monitor violation reports
- Gather feedback

## Success Metrics

- **Activation success rate** > 95%
- **Violation detection accuracy** (via controlled QA scenarios)
- **Zero false positives** for legitimate actions
- **Proctor response time** < 30s for critical violations
- **Student experience** (no negative feedback about lockdown UX)

## Teacher Override Extension (FR-07)

**FR-07**: Teacher có thể override `LockdownMode` khi tạo session thông qua field
`lockdownMode` (optional, 6th field) trong `CreateSessionRequest`. Override thắng ExamMode default.

**Validation rule**: Combination `examMode = PRACTICE` + `lockdownMode = STRICT`
bị reject với HTTP 400 (`IllegalArgumentException`).

**Default mapping (khi teacher không override)**:
- `PRACTICE` → `NONE`
- `MOCK_TEST` → `STANDARD`
- `REAL_EXAM` → `STRICT`

**Override matrix**:

| Teacher override | PRACTICE | MOCK_TEST | REAL_EXAM |
|---|---|---|---|
| NONE | ✅ | ✅ | ✅ |
| STANDARD | ✅ | ✅ | ✅ |
| STRICT | ❌ reject | ✅ | ✅ |
| null (default) | NONE | STANDARD | STRICT |

**Files affected**:
- `services/scheduling/src/main/java/com/pte/scheduling/dto/request/CreateSessionRequest.java`
- `services/scheduling/src/main/java/com/pte/scheduling/service/SessionService.java`
- `services/scheduling/src/test/java/com/pte/scheduling/service/SessionServiceLockdownTest.java`

## Open Questions

1. **Multiple monitors**: Block secondary displays or just ensure fullscreen on primary?
2. **Grace period**: For STANDARD mode, allow N violations before escalating to proctor?
3. **VM detection**: Should we detect & block virtual machines?
4. **Network calls**: Should lockdown mode also restrict network access to non-PTE domains?

## Out of Scope

- macOS desktop support (deferred to future phases)
- Linux desktop support (future consideration)
- Mobile platforms (different threat model)
- Browser-based lockdown (pte-web would need completely different approach)
- Hardware-level security (TPM, secure boot verification)
- Biometric authentication during exam
- Eye-tracking or facial recognition

## References

- Existing proctoring infrastructure: `services/proctor/`
- Similar products: Safe Exam Browser, ProctorU Desktop
- Flutter platform channels: https://docs.flutter.dev/platform-integration/platform-channels
