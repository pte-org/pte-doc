# AI overview (vendor-web /admin/ai) - style only, layout kept vertical

- PageHeader "AI overview" + one-line description + underline tabs (no card around the tabs).
- "Question generation" card: "Enabled" badge in the card header; row of 4 facts (22 task types, Version 3 ↗ -> /admin/ai/prompts, generator model, reviewer model "Model đánh giá"); two boxes side by side for the AI and speech providers (name, key badge, host in monospace, still a link to the provider page); lock note in a grey box.
- "Limits" card: full-width strip of 5 cells separated by thin vertical rules, small label over a big number with its unit ("10 câu", "100 câu / ngày", "3 tác vụ", "40 lượt"; a daily 0 reads "Không giới hạn"); on narrow screens the strip wraps into 2-3 columns without rules. "Edit" is a secondary button with a pencil (Button.leftIcon).
- Editing: in place (not a modal): the numbers become fields in the same cells, Exit / Save in the card header; the AI-calls explanation sits as one line under the strip.
