# Phase 5: BLoC Integration & UI Components

**Status:** Ready  
**Depends on:** Phase 1, Phase 2, Phase 3, Phase 4  
**Estimated effort:** 1 week

---

## Objective

Integrate `LockdownService` and `ViolationReporter` into `ExamAttemptBloc` lifecycle; create user-facing dialogs for lockdown activation failures and violation warnings; complete end-to-end lockdown flow from exam start to completion.

## Steps

### Step 1: Extend ExamAttemptBloc with Lockdown Lifecycle

**File:** `lib/features/exam_attempt/presentation/bloc/exam_attempt_bloc.dart`

**Changes:**
1. Add `LockdownService` as constructor dependency (via GetIt)
2. Modify `_onStartOrResumeAttempt`:
   ```dart
   // After successful startOrResume API call
   final lockdownMode = response.lockdownMode;
   if (lockdownMode != null && lockdownMode != LockdownMode.none) {
     try {
       await _lockdownService.activateLockdown(lockdownMode);
     } catch (e) {
       // Lockdown activation failed - prevent exam start
       emit(ExamAttemptFailure(
         error: 'Lockdown activation failed',
         details: e.toString(),
       ));
       return;
     }
   }
   ```

3. Modify `_onCompleteAttempt`:
   ```dart
   // Before emitting completion state
   await _lockdownService.deactivateLockdown();
   ```

4. Add cleanup in `close()`:
   ```dart
   @override
   Future<void> close() async {
     await _lockdownService.deactivateLockdown();
     return super.close();
   }
   ```

**Tests:** `test/unit/features/exam_attempt/exam_attempt_bloc_lockdown_test.dart`
- Lockdown activates when starting STRICT-mode attempt
- Lockdown does NOT activate for NONE-mode attempt
- Lockdown deactivates on completion
- Bloc emits failure state if lockdown activation throws

---

### Step 2: Lockdown Activation Failure Dialog

**File:** `lib/features/exam_attempt/presentation/widgets/lockdown_activation_failure_dialog.dart`

```dart
class LockdownActivationFailureDialog extends StatelessWidget {
  final List<String> failedChecks;
  final VoidCallback onRetry;
  
  const LockdownActivationFailureDialog({
    required this.failedChecks,
    required this.onRetry,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(ExamAttemptStrings.lockdownFailureTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ExamAttemptStrings.lockdownFailureMessage),
          SizedBox(height: 16),
          ...failedChecks.map((check) => Padding(
            padding: EdgeInsets.only(left: 16, bottom: 4),
            child: Row(
              children: [
                Icon(Icons.error, color: AppColors.errorRed, size: 16),
                SizedBox(width: 8),
                Expanded(child: Text(check)),
              ],
            ),
          )),
        ],
      ),
      actions: [
        TextButton(
          child: Text(ExamAttemptStrings.cancel),
          onPressed: () => Navigator.pop(context, false),
        ),
        ElevatedButton(
          child: Text(ExamAttemptStrings.retry),
          onPressed: () {
            Navigator.pop(context, true);
            onRetry();
          },
        ),
      ],
    );
  }
}
```

**Constants:** Add to `lib/features/exam_attempt/constants/exam_attempt_strings.dart`:
```dart
static const lockdownFailureTitle = 'Cannot Start Exam';
static const lockdownFailureMessage = 'Security checks failed:';
static const retry = 'Retry';
static const cancel = 'Cancel';
```

---

### Step 3: Violation Warning Banner

**File:** `lib/features/exam_attempt/presentation/widgets/violation_warning_banner.dart`

```dart
class ViolationWarningBanner extends StatelessWidget {
  final String violationType;
  
  const ViolationWarningBanner({
    required this.violationType,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.warningYellow,
      child: Row(
        children: [
          Icon(Icons.warning, color: AppColors.warningDark),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _getMessage(violationType),
              style: TextStyle(
                color: AppColors.warningDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getMessage(String type) {
    switch (type) {
      case 'LOCKDOWN_FULLSCREEN_EXIT':
        return ExamAttemptStrings.violationFullscreenExit;
      case 'LOCKDOWN_CLIPBOARD_PASTE':
        return ExamAttemptStrings.violationClipboardPaste;
      case 'LOCKDOWN_SHORTCUT_BLOCKED':
        return ExamAttemptStrings.violationShortcutBlocked;
      case 'LOCKDOWN_SCREENSHOT_ATTEMPT':
        return ExamAttemptStrings.violationScreenshot;
      case 'LOCKDOWN_FORBIDDEN_APP_DETECTED':
        return ExamAttemptStrings.violationForbiddenApp;
      default:
        return ExamAttemptStrings.violationGeneric;
    }
  }
}
```

**Constants:** Add to `exam_attempt_strings.dart`:
```dart
static const violationFullscreenExit = 'Attempting to exit fullscreen is not allowed';
static const violationClipboardPaste = 'Pasting from external sources is not allowed';
static const violationShortcutBlocked = 'System shortcuts are disabled during exam';
static const violationScreenshot = 'Screenshots are not allowed during exam';
static const violationForbiddenApp = 'Forbidden application detected';
static const violationGeneric = 'Security policy violation detected';
```

---

### Step 4: Integrate Warning Banner into ExamScaffold

**File:** `lib/features/exam_attempt/presentation/widgets/exam_scaffold.dart`

**Changes:**
1. Add `latestViolation` stream listener to `LockdownService`
2. Show banner above `ExamAppBar` when violation occurs
3. Auto-dismiss after 5 seconds

```dart
// In _ExamScaffoldState
StreamSubscription<String>? _violationSubscription;
String? _currentViolation;
Timer? _violationDismissTimer;

@override
void initState() {
  super.initState();
  _violationSubscription = getIt<LockdownService>()
      .violationStream
      .listen((violationType) {
    setState(() => _currentViolation = violationType);
    _violationDismissTimer?.cancel();
    _violationDismissTimer = Timer(Duration(seconds: 5), () {
      if (mounted) setState(() => _currentViolation = null);
    });
  });
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        if (_currentViolation != null)
          ViolationWarningBanner(violationType: _currentViolation!),
        ExamAppBar(/* ... */),
        Expanded(child: widget.body),
        ExamBottomBar(/* ... */),
      ],
    ),
  );
}

@override
void dispose() {
  _violationSubscription?.cancel();
  _violationDismissTimer?.cancel();
  super.dispose();
}
```

---

### Step 5: End-to-End Integration Test

**File:** `test/integration/lockdown_e2e_test.dart`

```dart
void main() {
  group('Lockdown E2E Flow', () {
    testWidgets('STRICT mode: activates lockdown on exam start', (tester) async {
      // Mock StartAttempt response with STRICT lockdownMode
      final mockResponse = AttemptTaskResponse(
        lockdownMode: LockdownMode.strict,
        // ... other fields
      );
      
      // Pump app and start exam
      await tester.pumpWidget(/* app */);
      await tester.tap(find.byKey(Key('start_exam_button')));
      await tester.pumpAndSettle();
      
      // Verify lockdown was activated
      verify(mockLockdownService.activateLockdown(LockdownMode.strict)).called(1);
      
      // Verify fullscreen enforced
      verify(mockWindowManager.enforceFullscreen()).called(1);
    });
    
    testWidgets('NONE mode: does not activate lockdown', (tester) async {
      final mockResponse = AttemptTaskResponse(
        lockdownMode: LockdownMode.none,
        // ...
      );
      
      await tester.pumpWidget(/* app */);
      await tester.tap(find.byKey(Key('start_exam_button')));
      await tester.pumpAndSettle();
      
      verifyNever(mockLockdownService.activateLockdown(any));
    });
    
    testWidgets('Shows failure dialog when lockdown activation fails', (tester) async {
      when(mockLockdownService.activateLockdown(any))
          .thenThrow(LockdownException('Fullscreen failed'));
      
      await tester.pumpWidget(/* app */);
      await tester.tap(find.byKey(Key('start_exam_button')));
      await tester.pumpAndSettle();
      
      // Verify dialog shown
      expect(find.text(ExamAttemptStrings.lockdownFailureTitle), findsOneWidget);
      expect(find.text(ExamAttemptStrings.retry), findsOneWidget);
    });
    
    testWidgets('Deactivates lockdown on exam completion', (tester) async {
      // Start exam with lockdown
      await tester.pumpWidget(/* app with STRICT attempt */);
      await tester.tap(find.byKey(Key('start_exam_button')));
      await tester.pumpAndSettle();
      
      // Complete exam
      await tester.tap(find.byKey(Key('submit_exam_button')));
      await tester.pumpAndSettle();
      
      // Verify deactivation
      verify(mockLockdownService.deactivateLockdown()).called(1);
    });
  });
}
```

---

## Acceptance Criteria

- [ ] ExamAttemptBloc activates lockdown when starting STRICT-mode attempt
- [ ] ExamAttemptBloc does NOT activate lockdown for NONE-mode attempt
- [ ] Lockdown activation failure shows dialog with retry option
- [ ] Lockdown deactivates on exam completion
- [ ] Violation warnings appear as banner above ExamAppBar
- [ ] Warning banner auto-dismisses after 5 seconds
- [ ] All unit tests pass (bloc + widgets)
- [ ] Integration test covers full start → violation → complete flow

## Testing

Run:
```bash
flutter test test/unit/features/exam_attempt/exam_attempt_bloc_lockdown_test.dart
flutter test test/widget/features/exam_attempt/violation_warning_banner_test.dart
flutter test test/integration/lockdown_e2e_test.dart
```

Expected: All tests pass.

## Quality and Testing State

**Quality:** Not yet reviewed  
**Testing:** Not yet run

---

## Notes

- Warning banner only shown for STANDARD mode (visual warning). STRICT mode violations already blocked at native layer.
- Lockdown cleanup in `ExamAttemptBloc.close()` ensures deactivation even if user force-quits.
- Integration test requires platform channel mocks from Phase 2.
