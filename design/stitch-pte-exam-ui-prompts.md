# Stitch Prompt Pack — PTE Exam UI (Full Screen Coverage)

Mục tiêu: tạo toàn bộ giao diện thi PTE giống bản thật (Pearson test delivery UI), không sót màn hình.

**Cách dùng:**
1. Dán **PROMPT 0 (Design System Anchor)** vào Stitch trước tiên → generate.
2. Với mỗi màn hình tiếp theo, dán **PROMPT N** và luôn mở đầu bằng dòng:
   `Keep the EXACT same design system, header, footer, spacing and colors as the previous screen. Now generate:`
3. Stitch giữ context tốt nhất khi 1 lần = 1 screen. Đừng gộp nhiều screen trong 1 prompt.
4. Dùng **Desktop / Web** mode, khung 1366×768 (PTE thi trên desktop, không phải mobile).

---

## PROMPT 0 — Design System Anchor (dán đầu tiên)

```
You are designing a high-fidelity, pixel-accurate clone of the Pearson PTE Academic /
PTE Core computer-based test delivery interface (the real exam software candidates see
in a test centre). This is NOT a marketing site and NOT a modern SaaS dashboard.
It must look like institutional, utilitarian assessment software.

TARGET
- Platform: desktop web app, fixed 1366x768 viewport, no responsive breakpoints.
- No scrolling on task screens. Content must fit one screen.
- Locale: English (UK) content.

DESIGN SYSTEM (use these tokens on every screen, never deviate)
- Background: #FFFFFF page, #F4F5F7 for panels/cards.
- Top app bar: solid #FFFFFF with a 1px #D8DCE3 bottom border, height 56px.
- Primary brand blue: #0B5FAE. Hover #094C8C. Focus ring: 2px #0B5FAE outline.
- Text: #1F2933 primary, #5A6473 secondary, #8A94A6 disabled.
- Borders: 1px solid #C9CFD9. Border radius: 3px ONLY. Absolutely no large radii.
- Shadows: none, or at most 0 1px 2px rgba(0,0,0,0.08). No glassmorphism, no gradients.
- Typography: Arial / Helvetica / system sans-serif only.
  - Task instruction: 16px, bold, #1F2933.
  - Body / passage text: 16px, line-height 1.6.
  - Labels & meta: 13px, #5A6473.
  - Timer / counter: 14px, tabular numerals.
- Buttons: rectangular, 3px radius, 36px height, 16px horizontal padding.
  - Primary: filled #0B5FAE, white text.
  - Secondary: white fill, 1px #0B5FAE border, #0B5FAE text.
  - Disabled: #E4E7EB fill, #8A94A6 text.
- Inputs / textareas: white fill, 1px #C9CFD9 border, 3px radius, no rounded pills.

PERSISTENT EXAM CHROME (must appear identically on every task screen)
- TOP BAR, left: "Pearson" wordmark placeholder + exam title "PTE Academic".
- TOP BAR, center-left: candidate name "Nguyen Van A" and "Candidate ID: 12345678".
- TOP BAR, right, in this order:
  1. small round volume/audio icon,
  2. question counter, plain text: "9 of 20",
  3. timer block, plain text: "Time remaining  00:24:17" with a small clock icon.
  The timer is TEXT, not a circular progress ring.
- BOTTOM BAR: height 56px, 1px #D8DCE3 top border, white fill.
  - Left: secondary button "Save & Exit".
  - Right: secondary button "Previous" (disabled where not allowed) and
    primary button "Next".
- CONTENT AREA: centered column, max-width 960px, 24px padding.
  - Line 1: section label, 13px uppercase letter-spaced, #5A6473,
    e.g. "PART 1 — SPEAKING & WRITING".
  - Line 2: the task instruction paragraph in 16px bold.
  - Then the task-specific body.

THE AUDIO / RECORDING STATUS BOX (critical PTE signature component — reuse verbatim)
A bordered box, 1px #C9CFD9, #F4F5F7 fill, 3px radius, width 420px, centered.
Inside, stacked and centered:
- Title line, bold 14px: either "Recorded Answer" or "Audio".
- Status line, 13px #5A6473: "Current status:" followed by the state, e.g.
  "Beginning in 3 seconds" / "Playing" / "Recording" / "Completed".
- A thin 6px horizontal progress bar, #0B5FAE fill on #D8DCE3 track, square ends.
- For playback boxes only: a small volume slider on the right.
There is NO play button on exam audio — it auto-plays. Do not add one.

RULES
- Do not invent a sidebar, avatars, illustrations, emojis, icon sets, or dark mode.
- Do not modernise the look. Density and plainness are the point.
- Every task screen must show the persistent chrome above.

FIRST SCREEN TO GENERATE NOW
The "Read Aloud" speaking task screen: section label "PART 1 — SPEAKING & WRITING",
instruction "Look at the text below. In 35 seconds, you must read this text aloud as
naturally and as clearly as possible. You have 40 seconds to read aloud.", a 3-sentence
academic passage, and the Recorded Answer status box showing
"Current status: Beginning in 3 seconds".
```

---

## Screen Inventory — 52 màn hình (checklist, không sót)

| # | Nhóm | Màn hình |
|---|---|---|
| 1 | Pre-test | Candidate sign-in |
| 2 | Pre-test | Identity confirmation (ảnh, tên, ID, ngày thi) |
| 3 | Pre-test | Terms & Conditions / NDA |
| 4 | Pre-test | Test introduction & structure overview |
| 5 | Pre-test | Headset check |
| 6 | Pre-test | Microphone check |
| 7 | Pre-test | Keyboard layout check (QWERTY/AZERTY/QWERTZ) |
| 8 | Pre-test | System & network readiness check |
| 9 | Pre-test | Waiting for proctor / ready to begin |
| 10 | Speaking | Personal Introduction (unscored) |
| 11 | Speaking | Read Aloud |
| 12 | Speaking | Repeat Sentence |
| 13 | Speaking | Describe Image |
| 14 | Speaking | Re-tell Lecture |
| 15 | Speaking | Answer Short Question |
| 16 | Speaking | Respond to a Situation (Core) |
| 17 | Speaking | Summarize Group Discussion (Core) |
| 18 | Writing | Summarize Written Text |
| 19 | Writing | Write Essay |
| 20 | Writing | Write Email (Core) |
| 21 | Reading | Reading & Writing: Fill in the Blanks (dropdown) |
| 22 | Reading | Multiple Choice, Multiple Answers |
| 23 | Reading | Re-order Paragraphs (drag & drop) |
| 24 | Reading | Reading: Fill in the Blanks (drag words) |
| 25 | Reading | Multiple Choice, Single Answer |
| 26 | Listening | Summarize Spoken Text |
| 27 | Listening | Multiple Choice, Multiple Answers |
| 28 | Listening | Fill in the Blanks (typed gaps) |
| 29 | Listening | Highlight Correct Summary |
| 30 | Listening | Multiple Choice, Single Answer |
| 31 | Listening | Select Missing Word |
| 32 | Listening | Highlight Incorrect Words |
| 33 | Listening | Write from Dictation |
| 34 | Chrome | Section instruction / part transition screen |
| 35 | Chrome | Optional break (10-minute countdown) |
| 36 | Chrome | Timer low warning (5 minutes remaining) |
| 37 | Chrome | Save & Exit confirmation dialog |
| 38 | Chrome | Microphone/recording failure dialog |
| 39 | Chrome | Connection lost / reconnecting overlay |
| 40 | Chrome | Answer auto-save & sync indicator state |
| 41 | Chrome | End of section confirmation |
| 42 | Chrome | Submit test confirmation |
| 43 | Post-test | Test complete / results in 48 hours |
| 44 | Post-test | Candidate dashboard (attempt history) |
| 45 | Post-test | Score report — overall + communicative skills |
| 46 | Post-test | Score report — enabling skills breakdown |
| 47 | Post-test | Answer review list (per question, scored) |
| 48 | Post-test | Answer review detail + AI feedback |
| 49 | Admin | Host console — sessions overview |
| 50 | Admin | Live proctor monitoring grid |
| 51 | Admin | Scoring review queue (human moderation) |
| 52 | Admin | Question authoring editor |

> 1–48 là scope "giao diện kỳ thi thật". 49–52 là các surface đã có trong `pte-app/lib/features`
> (`host_console`, `live_proctor`, `scoring_review`, `authoring`) — generate sau, chúng dùng
> design system khác (được phép có sidebar, table, filter).

---

## PROMPT 1–9 — Pre-test

```
1. Candidate sign-in screen. Centered 420px card on #F4F5F7 page, Pearson wordmark above.
   Fields: "Login username", "Login password" (both plain rectangular inputs with 13px
   labels above). Primary button "Log in" full width. Small helper text below:
   "Your username and password are on the sheet provided by the Test Administrator."
   No social login, no "remember me" styling flourishes.

2. Identity confirmation screen. Two-column layout inside the content area: left column a
   180x220 grey placeholder box labelled "Candidate photo"; right column a definition list
   with rows Name / Candidate ID / Date of birth / Test / Test centre / Test date & time.
   Instruction bold: "Check that the details below are correct." Bottom bar has
   secondary "Details are incorrect" and primary "Confirm".

3. Terms & Conditions screen. Instruction bold: "Read the following terms and conditions.
   You must accept them to begin the test." A scrollable bordered panel 900x420 with dense
   11-paragraph legal placeholder text and a visible thin scrollbar. Below it a square
   checkbox: "I accept the terms and conditions." Bottom bar: secondary "Decline",
   primary "Accept" (disabled state shown).

4. Test introduction screen. Instruction bold: "Test Introduction". Body explains the test
   has three parts. Then a plain bordered table, 3 columns (Part / Content / Time allowed),
   4 rows: Part 1 Speaking & Writing 54-67 minutes; Part 2 Reading 29-30 minutes;
   Part 3 Listening 30-43 minutes; plus an "Optional break" row of 10 minutes.
   Note line: "You cannot return to a previous question once you move on."
   Bottom bar primary "Next".

5. Headset check screen. Instruction bold: "Put on your headset. This is an opportunity to
   check that your headset is working correctly." Numbered 1-2-3 instruction list.
   Center the Audio status box showing "Current status: Playing" with the progress bar
   partly filled and a volume slider. Below: secondary "Playback" and primary "Next".

6. Microphone check screen. Instruction bold: "This is an opportunity to check that your
   microphone is working correctly." Numbered steps. A quoted sentence in a bordered box:
   "Testing, testing. One, two, three." Then the Recorded Answer status box showing
   "Current status: Recording" with a live 12-bar vertical input-level meter in #0B5FAE
   to the right of the bar. Buttons: secondary "Record", secondary "Playback",
   primary "Next".

7. Keyboard layout check screen. Instruction bold: "Select your keyboard layout."
   Three selectable bordered tiles side by side labelled QWERTY, AZERTY, QWERTZ, each
   showing a simplified grey key-row diagram; the QWERTY tile is selected with a 2px
   #0B5FAE border. Below, a single-line input labelled
   "Type the following sentence to test your keyboard:" with sample sentence above it.

8. System readiness check screen. Instruction bold: "Checking your system." A vertical
   list of 5 check rows, each with a label on the left and a status on the right:
   Camera (Passed, green tick), Microphone (Passed), Speakers (Passed),
   Network connection (Checking..., small spinner), Secure browser (Passed).
   Status text 13px; ticks are simple, not badges. Primary "Continue" disabled.

9. Ready to begin screen. Large centered bold line: "You are ready to begin your test."
   Secondary line: "Raise your hand to notify the Test Administrator. Do not start until
   you are instructed to do so." A dim grey inline notice: "Waiting for administrator
   approval..." with a small spinner. Primary button "Begin test" shown disabled.
```

## PROMPT 10–17 — Speaking (Part 1)

```
10. Personal Introduction task. Section label "PART 1 — SPEAKING & WRITING".
    Instruction bold: "Read the prompt below. In 25 seconds, you must reply in your own
    words, as naturally and clearly as possible. You have 30 seconds to record your
    response. Your response will be sent together with your score report to the
    institutions selected by you." A bordered #F4F5F7 panel with the prompt text
    ("Please introduce yourself. For example, you could talk about..."), then the
    Recorded Answer status box with "Current status: Beginning in 25 seconds".
    Note under it: "This item is not scored."

11. Read Aloud task. Instruction bold: "Look at the text below. In 35 seconds, you must
    read this text aloud as naturally and as clearly as possible. You have 40 seconds to
    read aloud." A 3-sentence academic passage at 16px/1.6 in a plain area (no card).
    Below, the Recorded Answer status box with "Current status: Beginning in 3 seconds"
    and progress bar at 10%.

12. Repeat Sentence task. Instruction bold: "You will hear a sentence. Please repeat the
    sentence exactly as you hear it. You will hear the sentence only once."
    Stack TWO status boxes vertically, 16px gap: first the Audio box
    ("Current status: Playing", bar 60%, volume slider), second the Recorded Answer box
    greyed out ("Current status: Beginning in 3 seconds", bar 0%).

13. Describe Image task. Instruction bold: "Look at the image below. In 25 seconds, please
    speak into the microphone and describe in detail what the image is showing. You will
    have 40 seconds to give your response." A 620x360 bordered placeholder showing a simple
    grey bar-chart graphic with axis labels and a caption "Global energy consumption by
    source, 2010-2020". Recorded Answer status box below, right-aligned to the image column.

14. Re-tell Lecture task. Instruction bold: "You will hear a lecture. After listening to
    the lecture, in 10 seconds, please speak into the microphone and retell what you have
    just heard from the lecture in your own words. You will have 40 seconds to give your
    response." Layout: Audio status box on the left ("Current status: Playing"), a 260x180
    grey lecture-slide placeholder image on the right, Recorded Answer status box centered
    below both.

15. Answer Short Question task. Instruction bold: "You will hear a question. Please give a
    simple and short answer. Often just one or a few words is enough."
    Audio status box ("Current status: Playing") then Recorded Answer status box
    ("Current status: Beginning in 3 seconds"). Keep the content area visually sparse —
    lots of white space, this item has no text content.

16. Respond to a Situation task (PTE Core). Instruction bold: "You will hear a description
    of a situation. After listening to the description, in 20 seconds, please speak into the
    microphone and respond as naturally and as clearly as possible. You will have 40 seconds
    to give your response." Show the situation description as visible text in a bordered
    #F4F5F7 panel, the Audio status box above it ("Current status: Completed", bar 100%),
    and the Recorded Answer status box below.

17. Summarize Group Discussion task (PTE Core). Instruction bold: "You will hear three
    speakers discussing a topic. In 10 seconds, you must summarise the opinions of the
    three speakers. You will have 120 seconds to give your response."
    Above the Audio box, a horizontal row of three small speaker chips
    "Speaker 1 / Speaker 2 / Speaker 3", where the currently speaking chip has a
    #0B5FAE left border and bold label. Audio box shows "Current status: Playing", bar 40%.
    Recorded Answer box below with a longer 200-second prep note.
```

## PROMPT 18–20 — Writing

```
18. Summarize Written Text task. Instruction bold: "Read the passage below and summarise it
    using one sentence. Type your response in the box at the bottom of the screen. You have
    10 minutes to finish this task. Your response will be judged on the quality of your
    writing and on how well your response presents the key points in the passage."
    Top half: a 900px-wide passage of 2 dense paragraphs. Bottom half: a 900x160 textarea.
    Under the textarea a left-aligned bar with "Total Word Count: 34" (13px #5A6473) and a
    small row of three plain text buttons "Cut  Copy  Paste" (PTE has no rich formatting).

19. Write Essay task. Instruction bold: "You will have 20 minutes to plan, write and revise
    an essay about the topic below. Your response will be judged on how well you develop a
    position, organise your ideas, present supporting details, and control the elements of
    standard written English. You should write 200-300 words."
    The essay prompt in a bordered #F4F5F7 panel, 2 sentences. Below, a 900x300 textarea.
    Footer row: "Total Word Count: 212" and "Cut Copy Paste" text buttons.
    Timer in the top bar reads "Time remaining  00:14:03".

20. Write Email task (PTE Core). Instruction bold: "Read the description of a situation.
    Then write an email about the situation. You will have 9 minutes. You should aim to
    write at least 100 words." Situation description in a bordered panel. Below, a
    900x260 textarea pre-labelled with a small 13px hint line above it:
    "Write your email below." Footer: "Total Word Count: 118" and Cut/Copy/Paste.
```

## PROMPT 21–25 — Reading (Part 2)

```
21. Reading & Writing: Fill in the Blanks task. Section label "PART 2 — READING".
    Instruction bold: "Below is a text with blanks. Click on each blank, a list of choices
    will appear. Select the appropriate answer choice for each blank."
    A 900px paragraph of academic text at 16px/1.8 with FOUR inline blanks rendered as
    140px-wide bordered dropdown controls with a small caret, sitting inline in the text
    baseline. Show the second dropdown OPEN, with a 4-option list below it
    (one option hover-highlighted #EAF2FB). One earlier blank already shows a selected word.

22. Reading Multiple Choice, Multiple Answers task. Instruction bold: "Read the text and
    answer the question by selecting all the correct responses. More than one response is
    correct." A 2-paragraph passage on top. Then the question in bold 16px, then five
    options as rows, each a SQUARE checkbox + 16px option text, 12px vertical spacing,
    options A and C checked. Below the options a 13px note: "Select all that apply."

23. Re-order Paragraphs task. Instruction bold: "The text boxes in the left panel have been
    placed in a random order. Restore the original order by dragging the text boxes from the
    left panel to the right panel." Two side-by-side panels, each 440px wide, with 13px
    headers "Source" and "Target", 1px #C9CFD9 border, #F4F5F7 fill. Left panel holds 2
    draggable text boxes (white fill, 1px border, a 6-dot drag handle on the left edge);
    right panel holds 3 already-ordered boxes, numbered 1-2-3, plus one dashed 2px #0B5FAE
    drop-target placeholder showing an active drag state, and a semi-transparent box being
    dragged with a slight tilt.

24. Reading: Fill in the Blanks task. Instruction bold: "In the text below some words are
    missing. Drag words from the box below to the appropriate place in the text. To undo an
    answer choice, drag the word back to the box below the text." A passage with FOUR blanks
    drawn as 120x28 dashed-border empty drop slots inline; one slot already filled with a
    word chip. Below the passage, a bordered word bank containing 7 draggable word chips
    (white fill, 1px border, 3px radius, 8px padding) laid out in a row.

25. Reading Multiple Choice, Single Answer task. Instruction bold: "Read the text and answer
    the multiple-choice question by selecting the correct response. Only one response is
    correct." Passage, question in bold, then four options as rows with ROUND radio buttons,
    the third one selected. Keep it dense and plain.
```

## PROMPT 26–33 — Listening (Part 3)

```
26. Summarize Spoken Text task. Section label "PART 3 — LISTENING".
    Instruction bold: "You will hear a short lecture. Write a summary for a fellow student
    who was not present. You should write 50-70 words. You have 10 minutes to finish this
    task. Your response will be judged on the quality of your writing and on how well your
    response presents the key points presented in the lecture."
    Audio status box at top ("Current status: Playing", bar 35%, volume slider).
    Below it a 900x220 textarea. Footer: "Total Word Count: 58" and Cut/Copy/Paste.

27. Listening Multiple Choice, Multiple Answers task. Instruction bold: "Listen to the
    recording and answer the question by selecting all the correct responses. You will need
    to select more than one response." Audio status box at top ("Current status: Completed",
    bar 100%). Then question bold, then five square-checkbox option rows, two checked.

28. Listening: Fill in the Blanks task. Instruction bold: "You will hear a recording. Type
    the missing words in each blank." Audio status box at top. Below, a transcript paragraph
    at 16px/2.0 with FOUR inline text inputs (each 110x28, white, 1px border) sitting in the
    text flow; the second input contains a typed word and shows a focus ring.

29. Highlight Correct Summary task. Instruction bold: "You will hear a recording. Click on
    the paragraph that best relates to the recording." Audio status box at top.
    Then FOUR selectable paragraph blocks stacked vertically, each a bordered box with a
    round radio button on the left and a 3-line paragraph; the second block is SELECTED with
    a #EAF2FB fill and 2px #0B5FAE border.

30. Listening Multiple Choice, Single Answer task. Instruction bold: "Listen to the recording
    and answer the multiple-choice question by selecting the correct response. Only one
    response is correct." Audio status box, question bold, four round-radio option rows,
    none selected yet. Timer reads "Time remaining  00:00:18" to imply the 20s response cap.

31. Select Missing Word task. Instruction bold: "You will hear a recording about [topic].
    At the end of the recording the last word or group of words has been replaced by a beep.
    Select the correct option to complete the recording." Audio status box showing
    "Current status: Completed". Then four round-radio option rows of short phrases.
    Add a small 13px italic hint line above the options: "The beep replaces the final words."

32. Highlight Incorrect Words task. Instruction bold: "You will hear a recording. Below is a
    transcription of the recording. Some words in the transcription differ from what the
    speaker said. Please click on the words that are different."
    Audio status box at top. Below, a 900px transcript of 4 lines at 16px/2.0 where EVERY
    word is an individually clickable token; THREE tokens are shown selected with a
    #FDECEC fill, 1px #D93A3A border and 2px radius. Non-selected tokens show no chrome but
    one token displays a subtle #F4F5F7 hover fill.

33. Write from Dictation task. Instruction bold: "You will hear a sentence. Type the sentence
    in the box below exactly as you hear it. You will hear the sentence only once. You must
    type what you hear." Audio status box at top ("Current status: Playing", bar 80%).
    Below, a single 900x110 textarea, empty, with a visible caret. Footer:
    "Total Word Count: 0". Keep the screen deliberately minimal.
```

## PROMPT 34–42 — Exam chrome, dialogs & edge states

```
34. Section instruction / part transition screen. No task content. Centered content:
    section label "PART 2 — READING", a bold 20px line "Reading", a 3-line description of
    what the section contains, a plain bordered table with rows Number of questions (up to
    20) and Time allowed (29-30 minutes), and a 13px note:
    "You cannot return to Part 1 once you begin Part 2." Bottom bar primary "Begin Part 2".

35. Optional break screen. Centered: bold 20px "Optional break". Body: "You may take a break
    of up to 10 minutes. Your test will resume automatically when the break time ends."
    A large tabular countdown "09:42" at 40px, then a thin 6px progress bar. Bottom bar:
    primary "Resume test now". Grey the top bar's question counter out during the break.

36. Timer low warning state. Show the Write Essay screen, but the top bar timer block now has
    a #FDECEC fill, 1px #D93A3A border, and reads "Time remaining  00:04:59" in #B02525.
    Additionally a dismissible inline banner directly under the top bar, full content width,
    #FFF6E5 fill with 1px #E0A912 border, 13px text: "5 minutes remaining in this section."
    with a small x close control on the right. Do not use a modal.

37. Save & Exit confirmation dialog. Render the Read Aloud task screen dimmed behind a
    rgba(31,41,51,0.45) overlay. A 480px centered modal: white, 3px radius, 1px border,
    header row with bold 16px "Save and exit test?" and a small x. Body 14px:
    "Your progress will be saved. You will need the Test Administrator to reactivate your
    test before you can continue." Footer right-aligned: secondary "Cancel",
    primary "Save and exit".

38. Recording failure dialog. Same dimmed-task-behind treatment. 480px modal with a small
    #D93A3A warning triangle beside the bold title "Microphone not detected". Body:
    "We could not record your response. Raise your hand to notify the Test Administrator.
    This item will be re-presented." Footer: secondary "Retry recording",
    primary "Notify administrator".

39. Connection lost overlay. A full-screen rgba(31,41,51,0.55) overlay over a blurred task
    screen. Centered 520px white panel: spinner, bold "Reconnecting...", body
    "Your connection was interrupted. Your answers are saved locally and will be submitted
    automatically. Your timer has been paused." A 13px meta row: "Last saved 12 seconds ago
    - Attempt 2 of 5". No dismiss button.

40. Auto-save / sync indicator state. Show the Summarize Written Text screen with a small
    inline status chip placed in the bottom bar next to "Save & Exit": 13px text
    "All answers saved" with a tiny #2E7D4F tick. Then render, to its right, the two
    alternate states as small labelled variants: "Saving..." with spinner, and
    "3 answers pending upload" with a #E0A912 dot.

41. End of section confirmation dialog. 480px modal: bold "End of Part 2 — Reading".
    Body: "You have answered 18 of 20 questions. Unanswered questions will be scored as
    incorrect. You cannot return to this part." A compact bordered list of the 2 unanswered
    question numbers. Footer: secondary "Review unanswered", primary "Continue to Part 3".

42. Submit test confirmation dialog. 520px modal: bold "Submit your test?".
    Body: "Once submitted you cannot make any changes. Your responses will be sent for
    scoring." A 3-row summary table: Part 1 complete / Part 2 complete / Part 3 complete,
    each with a tick. Footer: secondary "Go back", primary "Submit test".
```

## PROMPT 43–48 — Post-test & score report

```
43. Test complete screen. Full-screen, no exam chrome except the top bar wordmark.
    Centered: a simple #2E7D4F tick in a 56px circle outline, bold 22px
    "Your test is complete.", body "Your score report will be available in your account
    within 48 hours. You may now remove your headset and raise your hand."
    A bordered summary panel: Candidate ID, Test taken, Submitted at, Confirmation code
    (monospace). Primary button "Log out".

44. Candidate dashboard — attempt history. This screen MAY leave the exam chrome behind and
    use a normal app shell: left sidebar (Dashboard, My tests, Score reports, Practice,
    Settings), top bar with candidate name. Main area: bold 20px "My tests", then a plain
    bordered table with columns Test, Type, Date, Status, Overall score, Action; five rows
    mixing statuses (Scored / Scoring in progress / Expired) with a 13px status chip per row,
    and a text-link "View report" action. Keep the same colour tokens and 3px radius.

45. Score report — overall & communicative skills. Header block: candidate name, Candidate ID,
    test date, Report code. Then a large "Overall score" block: the number 78 at 56px bold
    #0B5FAE, with the 10-90 scale rendered as a horizontal track with a marker at 78 and
    tick labels at 10, 30, 50, 70, 90. Then a "Communicative skills" section with four
    horizontal bar rows — Listening 80, Reading 76, Speaking 82, Writing 74 — each row
    showing the label, a #0B5FAE bar on a #E4E7EB track, and the numeric value right-aligned
    in tabular figures. No pie charts, no gradients, no 3D.

46. Score report — enabling skills breakdown. Same report shell. A "Enabling skills" section
    with six horizontal bar rows: Grammar 79, Oral fluency 75, Pronunciation 71, Spelling 84,
    Vocabulary 80, Written discourse 73. Beneath, a bordered "What this means" panel with a
    two-column label/description list for each enabling skill, 13px. Footer row with
    secondary "Download PDF" and secondary "Send to institutions".

47. Answer review list. Bold 20px "Review your answers" and a filter row of plain segmented
    text buttons: All / Speaking / Writing / Reading / Listening, with "All" active
    (#0B5FAE underline, not a pill). Then a table-like list of 12 rows, each row showing:
    question number, task type name, a truncated prompt, a score like "3 / 5" right-aligned,
    a 13px status ("Auto-scored" / "AI-scored" / "Awaiting human review"), and a
    "View" text link. Rows separated by 1px #E4E7EB dividers.

48. Answer review detail. Two-column layout inside a 1180px container.
    Left column (620px): the original task exactly as presented during the exam — instruction,
    passage/image, and the candidate's submitted answer in a bordered #F4F5F7 panel; for a
    speaking item show a playback bar of the candidate recording.
    Right column (520px): a bordered "Scoring" panel with a score header "3 / 5", a
    per-criterion table (Content, Form, Grammar, Vocabulary) each with a score and a
    one-line comment; then an "AI feedback" panel of 2 short paragraphs; then a
    "Human review" panel showing reviewer name, timestamp, and an "Approved" status chip.
```

## PROMPT 49–52 — Admin surfaces (design system khác, generate sau cùng)

```
49. Host console — sessions overview. App shell with left sidebar (Sessions, Candidates,
    Questions, Scoring, Users, Audit log). Main: page title "Sessions", a filter row
    (date range, status dropdown, search input), a primary button "Create session", and a
    dense data table with columns Session code, Exam, Scheduled at, Candidates, Status,
    Proctor, Actions; eight rows with status chips (Scheduled / In progress / Completed /
    Aborted). Include pagination "1-8 of 124" and a row-level kebab menu.

50. Live proctor monitoring grid. Main area shows a 4x2 grid of candidate monitor cards.
    Each card: a 16:9 grey webcam placeholder, candidate name + ID overlay bottom-left,
    a status dot (green Active / amber Idle / red Flagged), current item label
    ("Part 1 - Item 7 of 20"), a thin progress bar, and two icon controls (mute, flag).
    Right rail 320px: an "Events" feed listing timestamped entries
    (Face not detected, Tab switch, Audio anomaly) each with a severity dot and a
    "Review" link. Top bar shows "12 active - 2 flagged".

51. Scoring review queue. Main: title "Scoring review", tabs (Pending 42 / In review 6 /
    Approved 310). A two-pane layout: left a 380px list of queue items (candidate, task type,
    AI score, confidence percentage, time waiting) with the second item selected; right the
    review workspace showing the candidate's answer, the AI score per criterion in editable
    number inputs, a comment textarea, and an action row with secondary "Request second
    review" and primary "Approve score". Show a low-confidence warning banner above the
    workspace for a 54% confidence item.

52. Question authoring editor. Main: breadcrumb "Questions / Reading / New item".
    Left 640px form column: Task type dropdown (set to "Re-order Paragraphs"), Difficulty
    select, Skill tags multi-select chips, a passage rich-text area, a repeatable
    "Paragraphs" list with drag handles and add/remove controls, and timing fields
    (Prep seconds, Response seconds) prefilled 0 and 75.
    Right 420px column: a live "Candidate preview" panel rendering the actual exam task
    screen in miniature inside a bordered frame, plus a "Validation" panel listing three
    check rows with pass/fail states. Sticky footer: secondary "Save draft",
    secondary "Preview", primary "Submit for review".
```

---

## Lưu ý khi generate

- **Timing trong prompt khớp `task-timing.json`** của project (`READ_ALOUD` 35/40, `WRITE_ESSAY` 1200s, `SUMMARIZE_GROUP_DISCUSSION` 200/120...). Nếu bạn cập nhật config thì sửa lại số trong prompt tương ứng.
- Các giá trị timing trong config hiện là **placeholder** (xem `_comment` ở đầu file) — cần đối chiếu Pearson candidate handbook trước khi chốt UI text.
- Stitch hay "tự làm đẹp": nếu nó thêm shadow/gradient/bo góc lớn, gửi tiếp
  `Remove all shadows, gradients and rounded corners. Border radius must be 3px. Make it look like plain institutional assessment software.`
- Sau khi xong, export sang Figma rồi mới chia component — đừng để Stitch tự sinh code production.
