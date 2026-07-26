# Phase 0: Repo Reset & Bootstrap

## Requirements

Delete the pre-pivot "Aptis" scaffold (`pte-app/lib/features/*` and `pte-app/lib/core/*`) in full — it targets a different backend and domain and none of its code is reused, only three of its files are kept as read-only design references before deletion. Stand up a clean feature-first skeleton (`lib/core/`, `lib/features/`, `lib/main.dart`) with GetIt DI wiring conventions in place, add the missing pubspec dependencies, and establish a CI-equivalent `flutter analyze` + `flutter test` baseline that passes on an empty skeleton, so every subsequent phase starts from a known-green state rather than inheriting a broken or half-migrated tree.

Maps to: **Foundational — supports FR-13 and all subsequent FRs; no single user story** (this phase produces no student-visible behavior)

## Design Constraints

- Before deletion, copy (not move) `pte-app/lib/core/storage/tables/answer_outbox_table.dart`, `pte-app/lib/core/sync/sync_engine.dart`, and `pte-app/lib/core/network/interceptors/token_refresh_interceptor.dart` into a non-compiled reference location (e.g. this plan directory or a `docs/reference/` note) so Phase 1/2 can consult their shape (composite-key table, canary-driven `SyncEngine.startSync`/`stopSync`, single-flight `_refreshInFlight` interceptor) without the old field names (`attemptId`/`questionId`) leaking into the new codebase's compiled `lib/` tree.
- Everything under `lib/features/*` and `lib/core/*` is deleted, not refactored in place — a partial migration risks silently keeping old-domain assumptions (e.g. old `content`/`status` outbox shape, old `question_id` naming) that don't match the real `pte-api` contract's `pinnedItemPublicId`/`attemptPublicId` naming.
- `pubspec.yaml`'s existing dependencies (`flutter_bloc`, `dio`, `drift`, `sqlite3`, `get_it`, `record`, `just_audio`, `equatable`, `connectivity_plus`, `logger`) are kept as-is, version-pinned as they already are — do not bump major versions as part of this reset unless a version conflict with a new dependency forces it.
- New dependencies added here, not deferred to a later phase: `flutter_secure_storage` (runtime), `sqlite3_flutter_libs` (runtime — bundles the native SQLite binary Drift needs on Android/iOS; the pure-Dart `sqlite3` package alone has no working native library on-device), `bloc_test` and `mocktail` (dev-only).
- Skeleton must follow the feature-first layout mandated by `pte-app/docs/CODING_STANDARDS_APP.md`: `lib/core/{constants,widgets,exceptions,extensions,utils}/` and `lib/features/{feature_name}/{data,domain,presentation}/`, with an empty `{feature}_module.dart` GetIt-registration convention demonstrated on at least one throwaway/example feature so later phases have a copy-paste-correct template.
- `lib/core/constants/app_strings.dart`, `app_colors.dart`, `app_dimensions.dart` must exist (even if minimally populated) before any phase writes UI, since the no-hardcoded-strings/colors rule is enforced from the first widget onward, not retrofitted at Phase 9.
- The `flutter analyze` + `flutter test` baseline must pass with zero issues on the empty skeleton itself — an already-broken baseline defeats the point of Phase 9's exit gate later.

## Steps

1. Inventory the current `pte-app/lib/features/*` and `pte-app/lib/core/*` trees (`ls`/`Glob`) and confirm the three reference files' exact current paths before any deletion.
2. Copy the three reference files' content out to a non-compiled location (outside `lib/`) for later citation by Phase 1/2 Design Constraints — do not leave copies inside `lib/` where `flutter analyze` would lint them as live code.
3. Delete `pte-app/lib/features/` and `pte-app/lib/core/` entirely; delete any now-orphaned test files under `pte-app/test/` that referenced the deleted code.
4. Recreate the skeleton directories: `lib/core/constants/`, `lib/core/widgets/`, `lib/core/exceptions/`, `lib/core/extensions/`, `lib/core/utils/`, `lib/features/` (empty, populated starting Phase 1), and a minimal `lib/main.dart` that runs an empty `MaterialApp` (no feature wiring yet — that starts in Phase 1).
5. Add stub `app_strings.dart`, `app_colors.dart`, `app_dimensions.dart` under `lib/core/constants/` with at least a placeholder entry each, matching the structure shown in `CODING_STANDARDS_APP.md`.
6. Edit `pte-app/pubspec.yaml`: add `flutter_secure_storage` and `sqlite3_flutter_libs` under `dependencies`; add `bloc_test` and `mocktail` under `dev_dependencies`; run `flutter pub get` and confirm no version resolution conflicts against the existing dependency set.
7. Write one throwaway example feature module (e.g. `lib/features/_example/_example_module.dart`) demonstrating the GetIt registration pattern from `CODING_STANDARDS_APP.md`, confirm it registers/resolves correctly via a smoke test, then delete it once the pattern is understood and documented in a comment/reference for later phases (or keep it if the team prefers a living template — decide once, note the decision here).
8. Run `flutter analyze` and `flutter test` against the reset skeleton; fix any residual reference to deleted code (stale imports, leftover generated `.g.dart` files from the old Drift schema) until both exit zero-issue.
9. Test: confirm `flutter pub get` succeeds with all new dependencies resolved, `flutter analyze` reports zero issues, and `flutter test` runs (even if zero test files exist yet, the command must exit 0, not error).

## Success Criteria

- [ ] `pte-app/lib/features/*` and `pte-app/lib/core/*` contain no code carried over from the pre-pivot "Aptis" scaffold.
- [ ] The three reference files' shapes are preserved somewhere citable (not deleted without a trace) for Phase 1/2 to consult.
- [ ] `pubspec.yaml` contains `flutter_secure_storage`, `sqlite3_flutter_libs`, `bloc_test`, `mocktail` alongside the previously-existing dependencies, and `flutter pub get` resolves cleanly.
- [ ] Feature-first skeleton (`core/`, `features/`, constants stubs, one demonstrated GetIt module pattern) exists and matches `CODING_STANDARDS_APP.md`'s documented structure.
- [ ] `flutter analyze` exits with zero issues on the reset skeleton.
- [ ] `flutter test` exits 0 on the reset skeleton.

## Quality and Testing State

- Quality gate: not evaluated.
- Testing: not started.
