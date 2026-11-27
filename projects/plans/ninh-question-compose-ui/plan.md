# Question compose page (vendor-web /admin/questions/new, Exam Studio "Compose" tab)

- Layout: skill tabs as a horizontal bar with colour dots (All / Speaking / Writing / Reading / Listening + counts) instead of the left TabRailCard; below it the form card and the student preview, ~55/45, preview sticky. "Create with AI" sits on the right of the tab bar.
- Shared: `Tabs` got an optional `tone` on a tab (coloured dot). The host template editor (tenant-web) now uses it too, replacing its own dot table. TabRailCard / SectionedTableCard are untouched (other screens still use them).
- Page header: PageHeader "Create PTE Question" / "Edit question"; the in-form h2 is gone.
- Form: Question pool + CEFR level share a row; "Prompt text" uses the common Textarea so every label has the same style (kept the common FormField look; did not override it).
- Preview: label "Preview · Student view" + the skill with its dot above the screen. Hint text: "học sinh" -> "học viên".
- Not done: moving Cancel / Create draft up into the page header (they stay at the bottom of the form); segmented control for the pool.

## In Exam Studio (Compose tab)
- Page tabs are underline tabs now (was the grey tray in a card); the Compose tab sits on the page without a card (Coverage already did; Kanban/Timeline keep theirs). Tab renamed "Compose question" / "Soạn câu hỏi".
- Skill filter is the compact segmented switch here (QuestionEditorWithPreview.skillTabsVariant), underline on /admin/questions/new where it is the only tab row.
- "Create with AI" is one shared component (GenerateWithAiAction: button + popup) used in the new-question page header and beside the hint in the Compose tab.
- "Reset" (ghost) next to "Create draft" for a new question only; it remounts the form for the next question.
- Kept on purpose: the "Correct answer" field stays visible for every task type (the team's choice).
