# Platform settings (vendor-web /admin/settings)

- PageHeader "Platform settings" + one-line description above the card.
- Each setting is one row: name (sentence case, bold) + description + "Default: 50 students" on the left; a compact w-52 number field with its unit inside on the right. "≈ 4 days" under the hours field once it is 24 or more (updates as you type).
- The two repeated "applies after save" lines became one grey note with an info icon above the footer. Wording kept to what the two lines said (applications approved / notifications sent after saving); no claim about already-approved organizations.
- Footer: status on the left ("✓ All changes are saved", or an orange dot + "Unsaved changes"); "Reset to defaults" (secondary, disabled when every field is already at its default) and "Save changes" on the right.
- Reset only fills the fields (it never wrote to the database); since it is harmless, the confirmation dialog and its texts were removed.
- Removed the per-setting "impact" text from the presentation table.

## Colour accents (second pass)
- Card header: tinted icon tile + a rule under the header (DashboardPanel got optional `icon` and `divided`, both off by default).
- Each setting row has a tinted tile: people = blue (UsersIcon), time = amber (ClockIcon).
- The note box is the blue info callout (sky tokens, like the checkout page); "All changes are saved" is green, unsaved stays the amber dot; the "≈ 4 days" is a blue pill.
- The unit is a grey block with a left rule at the end of the number field.
- Not done on purpose: keeping "Save changes" blue (at lower opacity) while disabled - that is the shared Button's disabled style, which is grey everywhere.
