# Phase 4: Frontend — Read imageUrl Instead of imagePromptRef

## Requirements
The Describe Image screen renders a real, loadable image for a real backend response, instead of feeding a raw UUID (`imagePromptRef`) to `Image.network`.

## Steps
1. Add a nullable `imageUrl` field to `pte-app`'s Dart `TaskView` (constructor param + `fromJson` mapping), alongside the existing `imagePromptRef` field (kept, unchanged, still present in the JSON for parity with the backend DTO even though the screen stops reading it).
2. Re-read `describe_image_screen.dart`'s `_ImageRegion` widget fresh (its current read site already treats `imagePromptRef` as if it were a URL — a pre-existing placeholder behavior, never valid against a real backend) and switch its read from `task.imagePromptRef` to `task.imageUrl`.
3. Confirm `task_image_display.dart` itself needs no change — it already takes an already-resolved `imageUrl` string as a prop with no knowledge of where it came from.
4. Update `task_type_dispatcher_test.dart`'s `_describeImageTask` fixture to supply `imageUrl` instead of misusing `imagePromptRef` for a URL value.
5. Update `describe_image_screen_test.dart`'s `_describeImageTask` fixture and every test that currently passes a URL via the `imagePromptRef` param (including the null-fallback test) to use the new `imageUrl` param instead, keeping the same test intent (real URL renders `TaskImageDisplay`, null renders the fallback message, no crash).
6. Run `flutter analyze` and the full `flutter test` suite to confirm zero issues and zero regressions.

## Success Criteria
- `flutter analyze` reports 0 issues.
- Full `flutter test` suite passes, including the updated Describe Image and task-type-dispatcher tests.
- `describe_image_screen_test.dart`'s existing 2 image-specific tests (renders via `TaskImageDisplay` with a real URL; null renders fallback with no exception) still pass, now driven by `imageUrl` instead of `imagePromptRef`.

## Risks
- LOW: leaving `imagePromptRef` on the Dart `TaskView` unused after this phase could look like dead code to a future reader — mitigated by a short doc comment noting it mirrors the backend DTO's own field and is deliberately kept for parity/potential future use, not an oversight.
