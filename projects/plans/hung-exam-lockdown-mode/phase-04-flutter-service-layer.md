# Phase 4: Flutter Service Layer (LockdownService & Violation Reporting)

**Status:** Ready  
**Depends on:** Phase 1 (backend policy), Phase 2 (platform channels), Phase 3 (Windows native impl)

---

## Overview

Implement the Flutter service layer that orchestrates lockdown enforcement by coordinating all platform channels, monitoring violations, and reporting them to the backend. This phase bridges the native capabilities (Phase 2) with the exam attempt lifecycle (Phase 4).

## Goals

1. **LockdownService** — single orchestrator for all lockdown operations
2. **ViolationReporter** — offline-first violation logging and backend reporting
3. **LocalViolationDao** — Drift-based local storage for violations
4. **Configuration** — forbidden apps list loaded from asset config

## Success Criteria

- [ ] LockdownService can activate/deactivate lockdown based on mode
- [ ] All violation streams are monitored and reported
- [ ] Violations are stored locally before backend submission
- [ ] Forbidden apps list is loaded from `assets/config/forbidden_apps.json`
- [ ] Unit tests pass with >90% coverage
- [ ] Mock platform channels for testing

## Steps

### Step 1: Create Violation Domain Model

**File:** `lib/core/security/models/violation_event.dart`

```dart
import 'package:equatable/equatable.dart';

enum ViolationType {
  fullscreenExit('LOCKDOWN_FULLSCREEN_EXIT'),
  clipboardPaste('LOCKDOWN_CLIPBOARD_PASTE'),
  screenshotAttempt('LOCKDOWN_SCREENSHOT_ATTEMPT'),
  shortcutBlocked('LOCKDOWN_SHORTCUT_BLOCKED'),
  forbiddenAppDetected('LOCKDOWN_FORBIDDEN_APP_DETECTED');

  const ViolationType(this.serverValue);
  final String serverValue;
}

enum ViolationSeverity {
  warning,
  critical;
}

class ViolationEvent extends Equatable {
  const ViolationEvent({
    this.id,
    required this.attemptPublicId,
    required this.type,
    required this.severity,
    required this.timestamp,
    this.metadata,
    this.sent = false,
  });

  final int? id;
  final String attemptPublicId;
  final ViolationType type;
  final ViolationSeverity severity;
  final DateTime timestamp;
  final String? metadata; // JSON string for additional context
  final bool sent;

  @override
  List<Object?> get props => [id, attemptPublicId, type, severity, timestamp, metadata, sent];

  ViolationEvent copyWith({
    int? id,
    String? attemptPublicId,
    ViolationType? type,
    ViolationSeverity? severity,
    DateTime? timestamp,
    String? metadata,
    bool? sent,
  }) {
    return ViolationEvent(
      id: id ?? this.id,
      attemptPublicId: attemptPublicId ?? this.attemptPublicId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      sent: sent ?? this.sent,
    );
  }

  Map<String, dynamic> toJson() => {
        'violationType': type.serverValue,
        'severity': severity.name.toUpperCase(),
        'timestamp': timestamp.toIso8601String(),
        'attemptPublicId': attemptPublicId,
        if (metadata != null) 'metadata': metadata,
      };
}
```

### Step 2: Create Drift DAO for Local Violations

**File:** `lib/core/storage/dao/local_violation_dao.dart`

```dart
import 'package:drift/drift.dart';
import '../app_database.dart';

part 'local_violation_dao.g.dart';

@DriftAccessor(tables: [LocalViolations])
class LocalViolationDao extends DatabaseAccessor<AppDatabase> with _$LocalViolationDaoMixin {
  LocalViolationDao(AppDatabase db) : super(db);

  Future<int> insert(ViolationEvent event) {
    return into(localViolations).insert(LocalViolationsCompanion(
      attemptPublicId: Value(event.attemptPublicId),
      violationType: Value(event.type.serverValue),
      severity: Value(event.severity.name),
      timestamp: Value(event.timestamp),
      metadata: Value(event.metadata),
      sent: const Value(false),
    ));
  }

  Future<List<LocalViolation>> getUnsent() {
    return (select(localViolations)..where((v) => v.sent.equals(false))).get();
  }

  Future<void> markSent(int id) {
    return (update(localViolations)..where((v) => v.id.equals(id)))
        .write(const LocalViolationsCompanion(sent: Value(true)));
  }

  Future<void> deleteOldSent({required Duration olderThan}) {
    final cutoff = DateTime.now().subtract(olderThan);
    return (delete(localViolations)
          ..where((v) => v.sent.equals(true) & v.timestamp.isSmallerThanValue(cutoff)))
        .go();
  }

  Future<List<LocalViolation>> getAllForAttempt(String attemptPublicId) {
    return (select(localViolations)..where((v) => v.attemptPublicId.equals(attemptPublicId))).get();
  }
}
```

**Update:** `lib/core/storage/app_database.dart`

```dart
@DriftDatabase(
  tables: [PendingMediaUploads, LocalViolations], // Add LocalViolations
  daos: [PendingMediaUploadDao, LocalViolationDao], // Add LocalViolationDao
)
class AppDatabase extends _$AppDatabase {
  // ... existing code
}

@DataClassName('LocalViolation')
class LocalViolations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get attemptPublicId => text()();
  TextColumn get violationType => text()();
  TextColumn get severity => text()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get metadata => text().nullable()();
  BoolColumn get sent => boolean().withDefault(const Constant(false))();
}
```

### Step 3: Create Forbidden Apps Configuration

**File:** `assets/config/forbidden_apps.json`

```json
{
  "windows": [
    {
      "name": "Google Chrome",
      "processName": "chrome.exe",
      "category": "browser"
    },
    {
      "name": "Mozilla Firefox",
      "processName": "firefox.exe",
      "category": "browser"
    },
    {
      "name": "Microsoft Edge",
      "processName": "msedge.exe",
      "category": "browser"
    },
    {
      "name": "Discord",
      "processName": "Discord.exe",
      "category": "communication"
    },
    {
      "name": "Microsoft Teams",
      "processName": "Teams.exe",
      "category": "communication"
    },
    {
      "name": "Skype",
      "processName": "Skype.exe",
      "category": "communication"
    },
    {
      "name": "Slack",
      "processName": "slack.exe",
      "category": "communication"
    },
    {
      "name": "AnyDesk",
      "processName": "AnyDesk.exe",
      "category": "remote_desktop"
    },
    {
      "name": "TeamViewer",
      "processName": "TeamViewer.exe",
      "category": "remote_desktop"
    },
    {
      "name": "WhatsApp",
      "processName": "WhatsApp.exe",
      "category": "communication"
    }
  ],
  "macos": [
    {
      "name": "Google Chrome",
      "processName": "Google Chrome",
      "category": "browser"
    },
    {
      "name": "Firefox",
      "processName": "Firefox",
      "category": "browser"
    },
    {
      "name": "Safari",
      "processName": "Safari",
      "category": "browser"
    },
    {
      "name": "Discord",
      "processName": "Discord",
      "category": "communication"
    },
    {
      "name": "Microsoft Teams",
      "processName": "Microsoft Teams",
      "category": "communication"
    },
    {
      "name": "Skype",
      "processName": "Skype",
      "category": "communication"
    },
    {
      "name": "Slack",
      "processName": "Slack",
      "category": "communication"
    },
    {
      "name": "AnyDesk",
      "processName": "AnyDesk",
      "category": "remote_desktop"
    },
    {
      "name": "TeamViewer",
      "processName": "TeamViewer",
      "category": "remote_desktop"
    }
  ]
}
```

**Update:** `pubspec.yaml`

```yaml
flutter:
  assets:
    - assets/audio/
    - assets/config/  # Add this
```

### Step 4: Create ForbiddenAppsConfig Loader

**File:** `lib/core/security/config/forbidden_apps_config.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

class ForbiddenApp {
  const ForbiddenApp({
    required this.name,
    required this.processName,
    required this.category,
  });

  final String name;
  final String processName;
  final String category;

  factory ForbiddenApp.fromJson(Map<String, dynamic> json) {
    return ForbiddenApp(
      name: json['name'] as String,
      processName: json['processName'] as String,
      category: json['category'] as String,
    );
  }
}

class ForbiddenAppsConfig {
  const ForbiddenAppsConfig({
    required this.windows,
    required this.macos,
  });

  final List<ForbiddenApp> windows;
  final List<ForbiddenApp> macos;

  List<ForbiddenApp> getForCurrentPlatform() {
    if (Platform.isWindows) return windows;
    if (Platform.isMacOS) return macos;
    return [];
  }

  static Future<ForbiddenAppsConfig> load() async {
    final jsonString = await rootBundle.loadString('assets/config/forbidden_apps.json');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;

    return ForbiddenAppsConfig(
      windows: (json['windows'] as List<dynamic>)
          .map((item) => ForbiddenApp.fromJson(item as Map<String, dynamic>))
          .toList(),
      macos: (json['macos'] as List<dynamic>)
          .map((item) => ForbiddenApp.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
```

### Step 5: Implement ViolationReporter

**File:** `lib/core/security/violation_reporter.dart`

```dart
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../storage/dao/local_violation_dao.dart';
import 'models/violation_event.dart';

class ViolationReporter {
  ViolationReporter({
    required Dio httpClient,
    required LocalViolationDao localDao,
    required Logger logger,
  })  : _httpClient = httpClient,
        _localDao = localDao,
        _logger = logger;

  final Dio _httpClient;
  final LocalViolationDao _localDao;
  final Logger _logger;

  Future<void> reportViolation(ViolationEvent event) async {
    // 1. Save locally first (offline-first)
    try {
      final id = await _localDao.insert(event);
      _logger.i('Violation saved locally: ${event.type.name} (id: $id)');
    } catch (e) {
      _logger.e('Failed to save violation locally', error: e);
      return; // Don't attempt HTTP if local save fails
    }

    // 2. Attempt immediate HTTP submission
    await _trySendToBackend(event);
  }

  Future<void> _trySendToBackend(ViolationEvent event) async {
    try {
      await _httpClient.post(
        '/api/proctor/violations',
        data: event.toJson(),
      );

      if (event.id != null) {
        await _localDao.markSent(event.id!);
      }
      _logger.i('Violation sent to backend: ${event.type.name}');
    } on DioException catch (e) {
      _logger.w('Failed to send violation to backend (will retry later)', error: e);
      // Don't rethrow - violation is safely stored locally
    }
  }

  /// Retry sending unsent violations (called periodically or on connectivity restore)
  Future<void> retryUnsent() async {
    try {
      final unsent = await _localDao.getUnsent();
      if (unsent.isEmpty) return;

      _logger.i('Retrying ${unsent.length} unsent violations');

      for (final violation in unsent) {
        final event = ViolationEvent(
          id: violation.id,
          attemptPublicId: violation.attemptPublicId,
          type: ViolationType.values.firstWhere(
            (t) => t.serverValue == violation.violationType,
          ),
          severity: ViolationSeverity.values.byName(violation.severity.toLowerCase()),
          timestamp: violation.timestamp,
          metadata: violation.metadata,
        );

        await _trySendToBackend(event);
      }
    } catch (e) {
      _logger.e('Error retrying unsent violations', error: e);
    }
  }

  /// Cleanup old sent violations (call periodically, e.g., on app start)
  Future<void> cleanupOld({Duration olderThan = const Duration(days: 7)}) async {
    try {
      await _localDao.deleteOldSent(olderThan: olderThan);
      _logger.d('Cleaned up old sent violations');
    } catch (e) {
      _logger.e('Error cleaning up old violations', error: e);
    }
  }
}
```

### Step 6: Implement LockdownService

**File:** `lib/core/security/lockdown_service.dart`

```dart
import 'dart:async';
import 'dart:io';
import 'package:logger/logger.dart';
import '../platform/window_manager_channel.dart';
import '../platform/process_manager_channel.dart';
import '../platform/clipboard_monitor_channel.dart';
import '../platform/shortcut_interceptor_channel.dart';
import 'config/forbidden_apps_config.dart';
import 'models/violation_event.dart';
import 'violation_reporter.dart';

enum LockdownMode {
  none,
  standard, // Warning only
  strict; // Full enforcement

  static LockdownMode fromString(String value) {
    return LockdownMode.values.firstWhere(
      (mode) => mode.name.toUpperCase() == value.toUpperCase(),
      orElse: () => LockdownMode.none,
    );
  }
}

class LockdownActivationException implements Exception {
  LockdownActivationException(this.message, {this.failedChecks = const []});

  final String message;
  final List<String> failedChecks;

  @override
  String toString() => 'LockdownActivationException: $message';
}

class LockdownService {
  LockdownService({
    required WindowManagerChannel windowManager,
    required ProcessManagerChannel processManager,
    required ClipboardMonitorChannel clipboard,
    required ShortcutInterceptorChannel shortcuts,
    required ViolationReporter violationReporter,
    required Logger logger,
  })  : _windowManager = windowManager,
        _processManager = processManager,
        _clipboard = clipboard,
        _shortcuts = shortcuts,
        _violationReporter = violationReporter,
        _logger = logger;

  final WindowManagerChannel _windowManager;
  final ProcessManagerChannel _processManager;
  final ClipboardMonitorChannel _clipboard;
  final ShortcutInterceptorChannel _shortcuts;
  final ViolationReporter _violationReporter;
  final Logger _logger;

  LockdownMode _currentMode = LockdownMode.none;
  String? _currentAttemptId;
  ForbiddenAppsConfig? _forbiddenAppsConfig;

  final List<StreamSubscription<String>> _violationSubscriptions = [];

  LockdownMode get currentMode => _currentMode;
  bool get isActive => _currentMode != LockdownMode.none;

  Future<void> initialize() async {
    _forbiddenAppsConfig = await ForbiddenAppsConfig.load();
    _logger.i('LockdownService initialized with ${_forbiddenAppsConfig?.getForCurrentPlatform().length ?? 0} forbidden apps');
  }

  Future<void> activateLockdown({
    required LockdownMode mode,
    required String attemptPublicId,
  }) async {
    if (mode == LockdownMode.none) {
      _logger.w('Attempted to activate lockdown with mode NONE');
      return;
    }

    _logger.i('Activating lockdown mode: ${mode.name} for attempt: $attemptPublicId');
    _currentMode = mode;
    _currentAttemptId = attemptPublicId;

    final failedChecks = <String>[];

    try {
      // 1. Enforce fullscreen
      try {
        await _windowManager.enforceFullscreen();
        _logger.d('Fullscreen enforced');
      } catch (e) {
        _logger.e('Failed to enforce fullscreen', error: e);
        failedChecks.add('Fullscreen enforcement failed');
      }

      // 2. Block clipboard
      try {
        await _clipboard.blockExternalPaste();
        await _clipboard.clearClipboard();
        _logger.d('Clipboard blocked and cleared');
      } catch (e) {
        _logger.e('Failed to block clipboard', error: e);
        failedChecks.add('Clipboard blocking failed');
      }

      // 3. Block shortcuts
      try {
        await _shortcuts.blockSystemShortcuts();
        _logger.d('System shortcuts blocked');
      } catch (e) {
        _logger.e('Failed to block shortcuts', error: e);
        failedChecks.add('Shortcut blocking failed');
      }

      // 4. Kill forbidden apps (STRICT mode only)
      if (mode == LockdownMode.strict) {
        try {
          await _terminateForbiddenApps();
        } catch (e) {
          _logger.e('Failed to terminate forbidden apps', error: e);
          failedChecks.add('Forbidden app termination failed');
        }
      }

      // 5. Start violation monitoring
      _startViolationMonitoring();

      if (failedChecks.isNotEmpty) {
        throw LockdownActivationException(
          'Some lockdown checks failed',
          failedChecks: failedChecks,
        );
      }

      _logger.i('Lockdown activated successfully');
    } catch (e) {
      // Rollback on failure
      await deactivateLockdown();
      rethrow;
    }
  }

  Future<void> deactivateLockdown() async {
    _logger.i('Deactivating lockdown');

    _stopViolationMonitoring();

    try {
      await _windowManager.exitFullscreen();
    } catch (e) {
      _logger.w('Failed to exit fullscreen', error: e);
    }

    try {
      await _clipboard.unblock();
    } catch (e) {
      _logger.w('Failed to unblock clipboard', error: e);
    }

    try {
      await _shortcuts.unblock();
    } catch (e) {
      _logger.w('Failed to unblock shortcuts', error: e);
    }

    _currentMode = LockdownMode.none;
    _currentAttemptId = null;

    _logger.i('Lockdown deactivated');
  }

  Future<void> _terminateForbiddenApps() async {
    if (_forbiddenAppsConfig == null) {
      _logger.w('Forbidden apps config not loaded');
      return;
    }

    final forbiddenApps = _forbiddenAppsConfig!.getForCurrentPlatform();
    final runningForbidden = await _processManager.getForbiddenProcesses(
      forbiddenApps.map((app) => app.processName).toList(),
    );

    if (runningForbidden.isEmpty) {
      _logger.d('No forbidden apps detected');
      return;
    }

    _logger.w('Found ${runningForbidden.length} forbidden apps: ${runningForbidden.join(", ")}');

    for (final processName in runningForbidden) {
      try {
        await _processManager.terminateProcess(processName);
        _logger.i('Terminated forbidden app: $processName');

        // Report violation
        if (_currentAttemptId != null) {
          await _violationReporter.reportViolation(
            ViolationEvent(
              attemptPublicId: _currentAttemptId!,
              type: ViolationType.forbiddenAppDetected,
              severity: _currentMode == LockdownMode.strict
                  ? ViolationSeverity.critical
                  : ViolationSeverity.warning,
              timestamp: DateTime.now(),
              metadata: '{"processName":"$processName"}',
            ),
          );
        }
      } catch (e) {
        _logger.e('Failed to terminate $processName', error: e);
      }
    }
  }

  void _startViolationMonitoring() {
    _logger.d('Starting violation monitoring');

    // Monitor fullscreen violations
    _violationSubscriptions.add(
      _windowManager.fullscreenViolations.listen((event) {
        _handleViolation(ViolationType.fullscreenExit, event);
      }),
    );

    // Monitor process violations
    _violationSubscriptions.add(
      _processManager.processViolations.listen((event) {
        _handleViolation(ViolationType.forbiddenAppDetected, event);
      }),
    );

    // Monitor shortcut violations
    _violationSubscriptions.add(
      _shortcuts.shortcutViolations.listen((event) {
        _handleViolation(ViolationType.shortcutBlocked, event);
      }),
    );
  }

  void _stopViolationMonitoring() {
    _logger.d('Stopping violation monitoring');
    for (final subscription in _violationSubscriptions) {
      subscription.cancel();
    }
    _violationSubscriptions.clear();
  }

  Future<void> _handleViolation(ViolationType type, String? metadata) async {
    if (_currentAttemptId == null) {
      _logger.w('Violation detected but no active attempt');
      return;
    }

    _logger.w('Violation detected: ${type.name}');

    await _violationReporter.reportViolation(
      ViolationEvent(
        attemptPublicId: _currentAttemptId!,
        type: type,
        severity: _currentMode == LockdownMode.strict
            ? ViolationSeverity.critical
            : ViolationSeverity.warning,
        timestamp: DateTime.now(),
        metadata: metadata,
      ),
    );
  }
}
```

### Step 7: Register Services in DI Container

**File:** `lib/core/di/security_module.dart` (new)

```dart
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import '../network/api_client.dart';
import '../platform/window_manager_channel.dart';
import '../platform/process_manager_channel.dart';
import '../platform/clipboard_monitor_channel.dart';
import '../platform/shortcut_interceptor_channel.dart';
import '../security/lockdown_service.dart';
import '../security/violation_reporter.dart';
import '../storage/app_database.dart';

void registerSecurityServices(GetIt getIt) {
  // Platform channels
  getIt.registerLazySingleton(() => WindowManagerChannel());
  getIt.registerLazySingleton(() => ProcessManagerChannel());
  getIt.registerLazySingleton(() => ClipboardMonitorChannel());
  getIt.registerLazySingleton(() => ShortcutInterceptorChannel());

  // ViolationReporter
  getIt.registerLazySingleton(
    () => ViolationReporter(
      httpClient: getIt<ApiClient>().dio,
      localDao: getIt<AppDatabase>().localViolationDao,
      logger: getIt<Logger>(),
    ),
  );

  // LockdownService
  getIt.registerLazySingleton(
    () => LockdownService(
      windowManager: getIt<WindowManagerChannel>(),
      processManager: getIt<ProcessManagerChannel>(),
      clipboard: getIt<ClipboardMonitorChannel>(),
      shortcuts: getIt<ShortcutInterceptorChannel>(),
      violationReporter: getIt<ViolationReporter>(),
      logger: getIt<Logger>(),
    ),
  );
}
```

**Update:** `lib/main.dart`

```dart
import 'core/di/security_module.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ... existing setup
  
  registerSecurityServices(getIt); // Add this
  
  // Initialize LockdownService
  await getIt<LockdownService>().initialize();

  runApp(const MyApp());
}
```

### Step 8: Unit Tests

**File:** `test/unit/security/lockdown_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:logger/logger.dart';
import 'package:pte_app/core/security/lockdown_service.dart';
import 'package:pte_app/core/security/violation_reporter.dart';
import 'package:pte_app/core/platform/window_manager_channel.dart';
import 'package:pte_app/core/platform/process_manager_channel.dart';
import 'package:pte_app/core/platform/clipboard_monitor_channel.dart';
import 'package:pte_app/core/platform/shortcut_interceptor_channel.dart';

class MockWindowManagerChannel extends Mock implements WindowManagerChannel {}
class MockProcessManagerChannel extends Mock implements ProcessManagerChannel {}
class MockClipboardMonitorChannel extends Mock implements ClipboardMonitorChannel {}
class MockShortcutInterceptorChannel extends Mock implements ShortcutInterceptorChannel {}
class MockViolationReporter extends Mock implements ViolationReporter {}
class MockLogger extends Mock implements Logger {}

void main() {
  late LockdownService service;
  late MockWindowManagerChannel mockWindowManager;
  late MockProcessManagerChannel mockProcessManager;
  late MockClipboardMonitorChannel mockClipboard;
  late MockShortcutInterceptorChannel mockShortcuts;
  late MockViolationReporter mockViolationReporter;
  late MockLogger mockLogger;

  setUp(() {
    mockWindowManager = MockWindowManagerChannel();
    mockProcessManager = MockProcessManagerChannel();
    mockClipboard = MockClipboardMonitorChannel();
    mockShortcuts = MockShortcutInterceptorChannel();
    mockViolationReporter = MockViolationReporter();
    mockLogger = MockLogger();

    service = LockdownService(
      windowManager: mockWindowManager,
      processManager: mockProcessManager,
      clipboard: mockClipboard,
      shortcuts: mockShortcuts,
      violationReporter: mockViolationReporter,
      logger: mockLogger,
    );

    // Setup common stubs
    when(() => mockWindowManager.enforceFullscreen()).thenAnswer((_) async {});
    when(() => mockWindowManager.exitFullscreen()).thenAnswer((_) async {});
    when(() => mockClipboard.blockExternalPaste()).thenAnswer((_) async {});
    when(() => mockClipboard.clearClipboard()).thenAnswer((_) async {});
    when(() => mockClipboard.unblock()).thenAnswer((_) async {});
    when(() => mockShortcuts.blockSystemShortcuts()).thenAnswer((_) async {});
    when(() => mockShortcuts.unblock()).thenAnswer((_) async {});
    when(() => mockProcessManager.getForbiddenProcesses(any()))
        .thenAnswer((_) async => []);
    when(() => mockLogger.i(any())).thenReturn(null);
    when(() => mockLogger.d(any())).thenReturn(null);
    when(() => mockLogger.w(any(), error: any(named: 'error'))).thenReturn(null);
  });

  group('activateLockdown', () {
    test('NONE mode does nothing', () async {
      await service.activateLockdown(
        mode: LockdownMode.none,
        attemptPublicId: 'test-attempt',
      );

      expect(service.currentMode, LockdownMode.none);
      expect(service.isActive, false);
      verifyNever(() => mockWindowManager.enforceFullscreen());
    });

    test('STANDARD mode activates all controls except app termination', () async {
      await service.activateLockdown(
        mode: LockdownMode.standard,
        attemptPublicId: 'test-attempt',
      );

      expect(service.currentMode, LockdownMode.standard);
      expect(service.isActive, true);
      verify(() => mockWindowManager.enforceFullscreen()).called(1);
      verify(() => mockClipboard.blockExternalPaste()).called(1);
      verify(() => mockShortcuts.blockSystemShortcuts()).called(1);
      verifyNever(() => mockProcessManager.getForbiddenProcesses(any()));
    });

    test('STRICT mode activates all controls including app termination', () async {
      when(() => mockProcessManager.getForbiddenProcesses(any()))
          .thenAnswer((_) async => ['chrome.exe']);
      when(() => mockProcessManager.terminateProcess(any())).thenAnswer((_) async {});
      when(() => mockViolationReporter.reportViolation(any())).thenAnswer((_) async {});

      await service.activateLockdown(
        mode: LockdownMode.strict,
        attemptPublicId: 'test-attempt',
      );

      expect(service.currentMode, LockdownMode.strict);
      verify(() => mockProcessManager.getForbiddenProcesses(any())).called(1);
      verify(() => mockProcessManager.terminateProcess('chrome.exe')).called(1);
    });

    test('throws LockdownActivationException when fullscreen fails', () async {
      when(() => mockWindowManager.enforceFullscreen())
          .thenThrow(Exception('Fullscreen failed'));

      expect(
        () => service.activateLockdown(
          mode: LockdownMode.strict,
          attemptPublicId: 'test-attempt',
        ),
        throwsA(isA<LockdownActivationException>()),
      );
    });
  });

  group('deactivateLockdown', () {
    test('deactivates all controls', () async {
      await service.activateLockdown(
        mode: LockdownMode.strict,
        attemptPublicId: 'test-attempt',
      );

      await service.deactivateLockdown();

      expect(service.currentMode, LockdownMode.none);
      expect(service.isActive, false);
      verify(() => mockWindowManager.exitFullscreen()).called(1);
      verify(() => mockClipboard.unblock()).called(1);
      verify(() => mockShortcuts.unblock()).called(1);
    });
  });
}
```

---

## Quality and Testing State

**Quality:** Not yet reviewed  
**Testing:** Not yet run

## Notes

- This phase creates the orchestration layer but doesn't connect to exam attempt lifecycle yet (that's Phase 4)
- Platform channel implementations are mocked for testing — real implementations from Phase 2 will be integrated
- Violation retry logic can be triggered periodically by MediaUploadCoordinator's existing connectivity checks
- Consider adding a background cleanup job for old sent violations (run on app start)

---

## Dependencies

- Phase 1: LockdownMode enum values from backend
- Phase 2: All platform channel implementations
- Drift database (existing)
- GetIt DI container (existing)

## Risks

- **HIGH**: Platform channel failures must not prevent app from functioning — all platform calls must be wrapped in try-catch
- **MEDIUM**: Violation storage could grow unbounded if backend is unreachable for extended periods — implement aggressive cleanup policy
- **LOW**: ForbiddenAppsConfig asset loading could fail — provide sensible defaults if JSON parse fails
