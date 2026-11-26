# Rubric version editor (vendor-web /admin/scoring-rubric/versions/{id}/edit)

Note: the screen in the review is the editor (/edit). The read-only page (/versions/{id}) is the task-type list and was not touched.

Data model: one rubric version holds the parameters of every task type that has traits (RubricParametersDocument.taskTypes); the dropdown only switches which task type is edited. Save/submit/activate act on the whole version.

- Layout: no outer card; PageHeader with the status badge (and "Unsaved") beside the title, "last updated … by …" under it, actions on the right. Two columns (3:2): weights card (+ Form band editor when the task has one) | version details + activation history.
- Status badge uses the shared words/colours (Draft = yellow "Bản nháp"), not the raw enum.
- Task picker moved into the weights card title bar; options read "Skill · Task name" (display name from the question-type catalogue, not REPEAT_SENTENCE).
- Weights card: each trait shows "Pearson: n · share%"; footer shows the total and either "Matches Pearson" or a "Reset to Pearson" button (traits without a reference weight are left alone; gates untouched).
- Menu "•••": separator above the destructive "Discard draft".
- Activation history is always-open card with an empty state (no disclosure); times use the shared short format.
- Kept: Activate stays the main button for users who may activate (backend: PLATFORM_ADMIN / ACADEMIC_MANAGER can activate a draft directly); "Submit for review" stays in the menu for them, as the backend allows it and authors without that right get it as the main button.
- Not done: activation history still shows the actor id (no name in the API); the picker is a native select, so no coloured dot inside it.
