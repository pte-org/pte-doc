# Stitch Prompt — tenant-web (Tenant Admin)

App: `pte-web/apps/tenant-web`. Role: HOST_ADMIN / PROGRAM_COORDINATOR / LECTURER / PROCTOR.

Style: visual language của [Modernize](https://github.com/adminmart/Modernize-Nextjs-Free) — card trắng
bo 7px không viền, shadow mềm, nền xanh xám, tile pastel, Plus Jakarta Sans. Toàn bộ màu có chữ đè
lên đã được sửa để đạt WCAG AA (palette gốc fail hết, xem mục cuối file).

**Cách dùng:** dán **PROMPT D0** trước → generate app shell. Sau đó mỗi lần dán **một screen**,
mở đầu bằng:
`Keep the EXACT same design system, shell, type scale and component styling as the previous screen. Now generate:`

> **Tạm hoãn:** các màn hình Reports / Analytics (cohort analytics, skill heatmap, readiness funnel)
> đã được bỏ khỏi pack này — tính năng thống kê chưa làm. Dashboard T1 vẫn giữ 2 biểu đồ đơn giản.
> Khi nào làm Reports thì thêm lại, và lúc đó mới cần bộ quy tắc dataviz đầy đủ.

---

## Screen Inventory (16)

### A — Đã có route trong `tenant-web`

| # | Screen | Route | Component hiện có |
|---|---|---|---|
| T1 | Dashboard | `/host/dashboard` | — |
| T2 | Learners | `/host/students` | `studentSearch/StudentSearchView` |
| T3 | Programmes | `/host/programs` | `programs/*` |
| T4 | Programme detail | `/host/programs/[publicId]` | `ClassesSection`, `CreateClassModal`, `MergeClassesModal` |
| T5 | Class detail | `.../classes/[classPublicId]` | `ClassDetailView`, `ClassRosterTable`, `LecturerAssignmentSection`, `AssignLecturerModal` |
| T6 | Exam sessions | `/host/exams` | `ExamsListView`, `SessionTable`, `CreateSessionModal` |
| T7 | Session detail | `/host/exams/[publicId]` | `SessionDetailView`, `AnswersSection`, `AnswerDetailModal`, `ProctorAssignmentSection`, `AssignProctorModal` |
| T8 | Roster import | trong T7 | `RosterImport`, `_RosterDropzone`, `PendingImportBanner`, `SkippedRowsReport`, `AddStudentForm`, `ResetStudentPasswordModal` |
| T9 | Audit log | `/host/audit-log` | `auditLog/AuditLogView` |
| T10 | Login | `/login` | `auth/LoginView`, `_AuthBrandPanel` |

> `/host/roster` là **redirect legacy** sang `/host/exams` — không phải màn hình, đừng thiết kế.

### B — API có, UI chưa có

| # | Screen | Backend |
|---|---|---|
| T11 | Learner detail | `UserController`, `ClassMembershipController` |
| T12 | Scoring review | `ScoringReviewController` |
| T13 | Staff & roles | `LecturerAssignmentController`, `ProgramCoordinatorAssignmentController` |
| T14 | Settings & Branding | `TenantController` (`logoUrl`, `primaryColor`, `studentLimit`) |

### C — Hệ thống

| # | Screen |
|---|---|
| T15 | State pack (empty / error / loading / confirm) |
| T16 | Responsive tablet + mobile |

---

## PROMPT D0 — Design System Anchor (dán đầu tiên)

```
You are designing the tenant admin console for a PTE (Pearson Test of English) assessment
platform used by language institutes. Users are registrars, programme coordinators,
lecturers and proctors. They manage learners, classes, programmes, mock exam sessions,
proctoring and scoring.

STYLE DIRECTION — match this reference precisely
Follow the visual language of the "Modernize" admin dashboard (AdminMart): a soft,
friendly, airy admin UI. Defining traits you must reproduce:
- Cool blue-grey page background with pure white cards floating on it. Cards are
  BORDERLESS — separated from the page by a soft diffuse shadow, never a 1px stroke.
- Small consistent rounding (7px) everywhere: cards, buttons, inputs, images.
- Pastel tinted blocks as accents — lavender-blue, mint, sky, cream — used as
  backgrounds for stat tiles, icon chips and status pills, always with dark slate ink
  on top. The colour is a wash, never a saturated fill behind text.
- Icon "avatars": a 40-48px rounded-square pastel tile with one line icon inside, used
  at the head of stat tiles and list rows.
- Generous padding (24px inside cards), roomy line-height, nothing cramped.
- Sidebar navigation as full-width rounded rectangles with a filled active item.
- Buttons with sentence-case labels at normal weight — not uppercase, not bold.

EXPLICITLY BANNED
- Gradient hero blocks, glassmorphism, neon accents, 3D charts, emoji icons.
- Hard 1px borders around cards. Separation comes from shadow plus background contrast.
  (Borders remain on inputs, tables and dividers only.)
- Dark mode as the default. Light is primary.
- Vanity metrics (MRR, growth, streaks, confetti). Metrics here are academic: learners,
  attempts, score bands, licence seats, scoring backlog.
- Saturated pastel used as a fill behind small text.

LAYOUT SHELL (identical on every screen)
- Desktop 1440x900. Left sidebar 270px, collapsible to an 80px icon rail.
  Sidebar #FFFFFF, NO right border — it separates because the content plane is tinted.
  Institute logo block 60px tall at the top (this product is white-labelled per
  institute, so the logo is a tenant asset, not a platform mark).
  Nav items: 14px label, 45px row height, 12px horizontal padding, 7px radius,
  full-width rounded rectangles. ACTIVE item is a filled --brand rectangle with white
  label and white icon; hover is a --brand-tint wash with --brand-ink label.
  Section captions 12px weight 600 #7C8FAC, 24px top margin.
- Top bar 70px #FFFFFF, no border, soft shadow only when scrolled.
  Left: sidebar-collapse icon button, then the breadcrumb (14px, "/" separators).
  Right: search icon button, notification bell with a small red dot badge, 35px circular
  avatar with name and role caption. Header icon buttons are 40px circles taking a
  --brand-tint background on hover.
- Content plane #F2F6FA, 24px page padding, max-width 1200px centred, 12-column grid,
  24px gutters, 24px row gap.
- Cards: #FFFFFF, 7px radius, NO border, 24px padding, signature soft shadow
  `rgba(145,158,171,0.30) 0px 0px 2px 0px, rgba(145,158,171,0.12) 0px 12px 24px -4px`.
  Card header = 18px/600 title, optional 14px #5A6A85 subtitle, action right-aligned.
- Page header: H1 21px/600, 14px #5A6A85 description beneath, actions right-aligned on
  the H1 baseline.

SIDEBAR NAVIGATION
HOME       Dashboard
LEARNERS   Learners · Programmes
DELIVERY   Exam sessions
ASSESSMENT Scoring review
DATA       Audit log
SETTINGS   Staff & roles · Settings

Do not flatten the hierarchy: classes are NOT a top-level destination. A class is reached
as Programmes > a programme > a class; the breadcrumb carries that depth.

Sidebar bottom: user mini profile plus a compact "Licence" card showing
"486 / 500 learner seats" with a thin usage bar and a "Request more seats" text link.

TYPOGRAPHY
- "Plus Jakarta Sans", Helvetica, Arial, sans-serif — weights 300/400/500/600/700.
  Used for all text including chart labels. No serif anywhere in the app shell.
- Scale: H1 36/600, H2 30/600, H3 24/600, H4 21/600, H5 18/600, H6 16/600,
  body 14/400 (line-height 1.334), small 12/400.
  Page titles use H4 (21px); card titles use H5 (18px).
- Buttons are sentence case at weight 400.
- Tabular numerals on every table column, axis tick and score figure.

COLOR — surfaces & ink
- Content plane #F2F6FA. Cards, sidebar, top bar #FFFFFF. Subtle fill #EAEFF4.
  Row hover #F6F9FC.
- Ink: primary #2A3547, secondary #5A6A85, muted (captions, placeholders) #7C8FAC.
- Divider #E5EAEF — decorative rules and table row separators ONLY.
- Input, select and textarea borders use #7C8FAC (3.29:1 on white). #E5EAEF is too faint
  to carry a control boundary — never use it for an input.
- Radius 7px on everything. Status pills and avatars are fully round.
- Shadow appears on cards, dropdowns, modals and popovers only — always the soft diffuse
  one. Never a hard dark shadow, never inset.

COLOR — pastel accent washes (the signature of this style)
Five tints, each paired with a darkened action step of the same hue. The tint is ONLY a
background under #2A3547 ink or a coloured icon; the action step is the only version
allowed under white text.
  blue   tint #ECF2FF  action #4169E8
  sky    tint #E8F7FF  action #0E729F
  mint   tint #E6FFFA  action #088068
  cream  tint #FEF5E5  action #9C6400
  blush  tint #FDEDE8  action #BE452B
Dark ink on any tint measures about 11:1. Assign tints by meaning: blue for neutral
counts, mint for healthy, cream for caution, blush for problems, sky for informational.

COLOR — brand accent
- --brand-soft  #5D87FF  the reference's signature blue. ONLY where it carries no text:
                         icon tiles, decorative marks, indicator dots. 3.29:1 on white —
                         fine as a non-text indicator, not as a fill under a label.
- --brand       #4169E8  filled primary buttons, filled active nav item, tab underline.
                         White label clears AA (4.76:1).
- --brand-hover #3359D2  hover — the fill DEEPENS, never lightens (6.00:1).
- --brand-deep  #2F52C4  pressed (6.72:1).
- --brand-tint  #ECF2FF  secondary-button fill, selected-row wash, sidebar hover wash.
- --brand-ink   #3359D2  ALL brand-coloured TEXT: links, secondary-button labels, text
                         buttons.

WHITE-LABEL — hard requirement
Every institute supplies its own `primaryColor` and `logoUrl`, so --brand is a variable.
Blue above is only the default.
- --brand may be used ONLY for: active nav indicator, primary/secondary button fills,
  focus ring, selected tab underline, selected-row wash, link text. Complete list.
- --brand MUST NOT colour chart series, status, or score bands. Swapping an institute's
  brand colour must never change the meaning of a chart. --brand never appears inside a
  plot area.

BUTTONS & CONTROLS
- 40px tall (compact/table-row 32px), 20px horizontal padding, 14px label weight 400
  sentence case, 7px radius, 8px icon gap. Icon-only buttons are 40px circles.
- Primary: fill --brand, white label, no border, `box-shadow: 0 2px 6px
  rgba(65,105,232,0.28)`. No gradient.
- Secondary: fill --brand-tint, no border, label --brand-ink. This tinted soft button —
  not an outlined one — is the reference's secondary; use it for every secondary action.
- Tertiary/text: transparent, label --brand-ink, --brand-tint wash on hover.
- Destructive: soft fill #FDEDE8, no border, #BE452B label (4.53:1). Only the final
  confirm button in a modal uses a solid #BE452B fill with white text (5.15:1).
- Disabled: fill #EAEFF4, label #7C8FAC, no shadow. Never just lowered opacity.
- Hover DEEPENS to --brand-hover; pressed drops to --brand-deep with the shadow
  collapsed and the label 1px down; focus-visible shows a 2px --brand ring at 2px
  offset, drawn outside the control and never removed on mouse focus.
- Transitions 150ms ease-out on background-color, box-shadow, transform only.
- Inputs/selects/textareas: 7px radius, 1px #7C8FAC border, 12px/14px padding, 14px
  text, placeholder #7C8FAC. Focus border becomes --brand at 2px. Error border #BE452B
  with a 12px message beneath plus an icon.
- Toggles 38x21, fully round track, on state --brand.
- Dropdowns, modals, popovers, slide-overs: #FFFFFF, 7px radius, no border, the soft
  card shadow. Tooltips are the exception — dark #2A3547 fill, white 12px text.

STATUS (never colour alone — always icon + text label + colour)
  good #088068 on #E6FFFA · warning #9C6400 on #FEF5E5 · serious #B3571F on #FEF5E5
  critical #B5342B on #FDEDE8 · info #0E729F on #E8F7FF
Do not revert to the reference's #13DEB9 / #FFAE1F / #FA896B for anything carrying text.

CHARTS (only a few screens have them — keep them simple)
- Series colours, fixed, never themed, never brand-swapped:
  1 #2a78d6 blue, 2 #eb6834 orange, 3 #1baf7a aqua, 4 #eda100 yellow.
  Never more than 4 series; a 5th folds into "Other".
- NEVER a dual-axis chart. Two measures of different scale become two charts.
- Bars have 4px rounded ends on the data end only. Lines 2px. Dots >= 8px.
- Gridlines 1px #E5EAEF, horizontal only, behind the marks. Axis #DFE5EF.
  Tick labels 11px #7C8FAC.
- 2+ series get a legend; a single-series chart gets NO legend — the card title names it.
- Never print a value on every data point — label endpoints and the maximum only.
- Every chart has a hover tooltip showing category, value and unit.

ACCESSIBILITY (WCAG 2.2 AA — required for institutional procurement)
- Body text >= 4.5:1. Visible 2px focus ring on every interactive element.
- Full keyboard operation; tables have real headers and a visible sort affordance.
- Never encode meaning with colour alone — pair with icon or label.
- Support 200% zoom without horizontal scroll on the content column.

Use realistic Vietnamese sample data: learner names (Nguyễn Văn An, Trần Thị Mai, Lê Minh
Quân), class codes (PTE-79-A, PTE-65-B), session codes (PTE-A-114), branches (Cầu Giấy,
Quận 1), and PTE scores on the 10-90 scale.

FIRST SCREEN TO GENERATE NOW: T1 below.
```

---

## PROMPT T1–T16

```
T1. Dashboard. Breadcrumb "Dashboard". H1 "Overview" with subtitle
    "Hanoi Language Institute · 3 chi nhánh · Khoá mùa thu 2026" and a date-range
    dropdown right-aligned.
    Row 1 — four stat tiles, each with a pastel icon tile on the left, the label in 14px
    #5A6A85 above and the figure in 24px/600 below:
    blue "Learners active 486" · sky "Attempts this month 1,204" ·
    cream "Awaiting scoring review 28" · mint "Sessions this week 9".
    Row 2 — 8/4 split. Left, chart card "Attempts delivered": subtitle "Bài thi thử theo
    tháng", a period dropdown in the header, and a soft blue bar chart with 12 monthly
    bars, rounded tops, clean axis labels, 2 series (PTE Academic, PTE Core) with a small
    legend. Right, card "Licence": the figure "486 / 500" at 28px, a thin usage bar, a
    warning icon+label "97% đã dùng — còn 14 chỗ", and a secondary "Request more seats".
    Row 3 — full-width card "Upcoming sessions": table with Date & time, Session code,
    Exam, Branch, Enrolled / capacity, Proctor, Status pill, and a "View" text link.
    Row 4 — 6/6. Left, card "Recent activity": a vertical timeline with a thin rule, small
    coloured dots, 12px tabular times and Vietnamese entries
    ("09:30 Nguyễn Văn An hoàn thành bài thi thử", "10:00 Phiên PTE-A-114 bắt đầu tại Cầu
    Giấy", "11:15 28 bài chờ chấm lại"). Right, card "Cần xử lý": 5 rows, each an
    icon+label plus a name and a chevron — critical "3 bài chấm lỗi", warning "Licence
    97%", warning "PTE-A-114 chưa có giám thị", info "Import roster đang chạy",
    good "Đã dựng lại báo cáo".

T2. Learners. H1 "Learners" with primary "+ Add learner" and secondary "Import".
    Filter row above the table: search, Programme select, Class select, Status select,
    a right-aligned "12 of 486 shown" count and a "Clear filters" text button.
    Table columns: checkbox, Learner (avatar + name + email in 12px beneath),
    Student ID (monospace), Programme, Class, Status pill, Attempts, Last activity, kebab.
    Status options: Active / Inactive / Suspended.
    Sortable headers, sticky header, 1px #E5EAEF row dividers, no zebra stripes.
    Pagination footer "1–10 of 486" with a rows-per-page select.
    Bulk bar appears above the table when rows are selected: "8 selected" with
    "Assign to class", "Enrol in session", "Export".
    Kebab menu contains "Reset password", "Assign to class", "View attempts".

T3. Programmes. H1 "Programmes" with primary "+ New programme".
    Toolbar: search, Branch select, a status segmented control (All / Active / Inactive /
    Suspended).
    Table columns: Programme, Branch, Coordinator (avatar + name), Period, Classes,
    Learners, Status pill, kebab.
    The Period cell shows start and end dates with a thin 2px progress bar of elapsed
    time beneath and the caption "Tuần 6 / 12".

T4. Programme detail. Breadcrumb "Programmes / PTE Intensive Autumn 2026".
    Page header: programme name as H1, branch and date range as subtitle, a status pill,
    actions "Edit programme" and primary "+ Add class".
    Row 1 — four compact stat tiles with pastel icon tiles: Learners 128 · Classes 6 ·
    Sessions delivered 24 · Avg overall 62.
    Row 2 — card "Classes" with header actions "+ Add class" and "Merge classes".
    Table: Class, Lecturer, Learners, Sessions, Avg score, Status pill, kebab.
    Row 3 — card "Coordinators & lecturers": rows with avatar, name, role chip, assigned
    date, and an "Unassign" text action.
    Also render two modal states as separate frames:
    (a) "Create class" — name, capacity, schedule fields, and a lecturer picker.
    (b) "Merge classes" — two class multi-selects, a preview line "18 + 14 = 32 learners",
        and a cream warning callout with icon "Học viên giữ nguyên lịch sử bài thi. Thao
        tác này không hoàn tác được."

T5. Class detail. Breadcrumb "Programmes / PTE Intensive Autumn 2026 / PTE-79-A".
    Page header: class name as H1, a row of lecturer avatars, schedule caption
    "Thứ 2 / Thứ 4 · 18:00–20:00", status pill.
    Tabs: Roster | Performance | Sessions. "Roster" active, underlined 2px --brand.
    8/4 split. Left, card "Roster": table with checkbox, Learner (avatar + name +
    student ID beneath), Enrolled, Attempts, Latest overall (tabular), Trend (a 40px
    inline sparkline, no axis), Risk (icon + label: Tốt / Theo dõi / Cần hỗ trợ), kebab.
    A bulk bar appears when rows are selected: "8 selected" with "Move to class",
    "Remove from class", "Export".
    Right rail: card "Class at a glance" — four horizontal bars for Listening 74,
    Reading 68, Speaking 71, Writing 63, single series so no legend, each value labelled
    at the bar end, the weakest bar carrying a small warning icon beside its label.
    Beneath it, card "Lecturers" with assigned lecturers (avatar, name, role chip) and a
    secondary "Assign lecturer" button that opens a searchable picker modal.

T6. Exam sessions. H1 "Exam sessions" with primary "+ Create session".
    Toolbar: search by session code, Branch select, Status select, date range.
    Table columns: Session code (monospace), Exam, Scheduled at, Branch,
    Enrolled / capacity, Proctor (avatar + name, or a cream "Chưa phân công" chip),
    Status pill, kebab.
    Status options: Draft / Scheduled / In progress / Completed / Aborted.
    Also render the "Create session" modal as a separate frame: blueprint select, date and
    time, branch, capacity, and a toggle "Create for a programme" that swaps the capacity
    field for a programme picker with the caption "Toàn bộ học viên trong chương trình sẽ
    được ghi danh."

T7. Session detail. Breadcrumb "Exam sessions / PTE-A-114".
    Page header: session code as H1, exam name as subtitle, chips for date, branch and
    status. Actions: "Edit session", "Assign proctor", primary "Start session" shown
    DISABLED with a 12px caption "Bắt đầu sau 2 ngày".
    Row 1 — four compact stat tiles: Enrolled 42 / 48 · Checked in 0 · Proctors 1 / 2 ·
    Blueprint "PTE Academic Standard".
    Tabs: Roster | Answers | Proctors.
    "Roster" tab active: a toolbar with secondary "Import roster", secondary
    "+ Add learner" and a search field; table with Learner, Student ID, Class,
    Seat (inline editable select), Check-in status pill, kebab. A kebab action
    "Reset password" opens a modal that, after confirming, shows a generated credential in
    a monospace block on a #EAEFF4 panel with a copy button and the caption
    "Chỉ hiển thị một lần. Hãy đưa thông tin này cho học viên."
    Also design the "Answers" tab: table with Learner, Task type, Skill, Submitted at,
    Score, Scoring status pill, action. Task types are real PTE types — Read Aloud,
    Describe Image, Re-tell Lecture, Summarize Written Text, Write Essay, Write from
    Dictation. Clicking a row opens an "Answer detail" modal showing the original prompt
    in a #EAEFF4 panel, the learner's response (for a speaking item a playback bar with a
    waveform placeholder and a transcript beneath), and the per-criterion scores.
    And the "Proctors" tab: assigned proctors as rows with avatar, name, assigned date and
    "Unassign"; plus an "Assign proctor" modal whose searchable staff list shows each
    proctor's other sessions that day so a clash is visible before assigning.

T8. Roster import flow. This lives inside T7, not as a page. Design four frames:
    (a) Upload modal — a large dashed dropzone with 7px radius that takes a --brand-tint
        wash on drag-over, a blue icon tile centred, "Kéo file roster vào đây hoặc chọn
        file", a 12px spec line "XLSX hoặc CSV, tối đa 500 dòng", and a "Tải file mẫu"
        text link.
    (b) Pending banner — the session detail page with a full-width #ECF2FF banner directly
        under the page header: "Đang import — 128 / 340 dòng", a thin progress bar, and a
        "Xem chi tiết" link.
    (c) Result summary — a card with a mint tile "312 học viên đã import" and a cream tile
        "28 dòng bị bỏ qua".
    (d) Skipped rows report — a table with Row number, Raw value, Reason ("Email đã tồn
        tại", "Thiếu số điện thoại", "Lớp không tồn tại"), and a secondary "Tải danh sách
        dòng lỗi" button plus a primary "Sửa và tải lại".

T9. Audit log. H1 "Audit log". Filter row: date range, Actor select, Action type select,
    Branch select, free-text search.
    Below, a vertical timeline rather than a plain table: each entry has a 12px tabular
    timestamp in a fixed 140px left gutter, a thin vertical rule through the gutter, a
    small circular node on the rule, then the body — bold actor name, a plain-language
    Vietnamese action sentence, and a 12px meta line with the branch and source IP.
    Destructive entries (xoá, thu hồi, huỷ phiên) get a #B5342B node and a blush
    "Destructive" chip. Group entries under sticky day headings "Hôm nay", "Hôm qua",
    "11 tháng 9, 2026". Each entry expands to reveal a monospace before/after panel.

T10. Login. Desktop split layout, no app shell.
     Left half: a soft blue panel (#ECF2FF) with the institute logo and a simple abstract
     illustration — geometric, no mascot, no photography.
     Right half: white panel, centred 400px column. "Welcome back" as H3, "Đăng nhập để
     tiếp tục" in 14px #5A6A85. Email and Password fields, a "Remember me" checkbox and a
     "Quên mật khẩu?" text link on the same row, a full-width primary "Sign in" button,
     and a 12px footer "Chưa có tài khoản? Liên hệ quản trị viên của đơn vị."
     Also render two error states: an inline blush alert above the fields reading
     "Email hoặc mật khẩu không đúng" with an error icon, and the locked variant
     "Tài khoản tạm khoá. Thử lại sau 15 phút."

T11. Learner detail. Breadcrumb "Learners / Nguyễn Văn An".
     Top profile card: 56px avatar, name as H1, 12px monospace student ID, chips for
     programme and class, a status pill. Actions: "Enrol in session", "Add note", "Edit",
     and a kebab "More".
     Tabs: Overview | Attempts | Notes | Files. "Overview" active.
     5/7 split. Left, card "Learner information" as a definition list: Họ tên · Điện thoại
     · Email · Chương trình · Lớp · Giảng viên phụ trách · Ngày ghi danh.
     Right, card "Current standing": the overall score 68 as a 40px/600 figure, beneath it
     the PTE 10-90 scale as a horizontal track with a marker at 68, tick labels at
     10/30/50/70/90 and a dashed target marker at 79, then a 12px caption "Còn thiếu 11
     điểm so với mục tiêu".
     Below, card "Skills": four horizontal bars (Listening 74, Reading 68, Speaking 71,
     Writing 63), single series so no legend, values labelled at the bar ends, the weakest
     bar carrying a warning icon beside its label.
     Below, card "Attempt history": table with Date, Session, Exam, Overall, L / R / S / W
     columns (tabular), Status pill, "View report" link.

T12. Scoring review. H1 "Scoring review". Tabs: Pending 28 | In review 4 | Approved 812.
     Two-pane layout inside one card.
     Left 380px: the queue list. Each row shows learner name, task type in 12px #5A6A85,
     the AI score, a confidence percentage with a thin 2px bar, and time waiting. Rows
     under 60% confidence carry a cream warning chip "Low confidence". The second row is
     selected with a --brand-tint wash and a 2px --brand left edge.
     Right: the review workspace — a header with learner, task type and item ID; the
     original prompt in a #EAEFF4 panel; the learner's response (for a speaking item a
     playback bar with a waveform placeholder and the transcript beneath); a "Scoring"
     block with one row per criterion (Content, Form, Grammar, Vocabulary, Spelling), each
     with a small number input, the read-only "AI suggested" value beside it and a 12px
     rationale line; a Comments textarea; and an action bar with secondary "Request second
     review" and primary "Approve score".
     A cream warning banner sits above the workspace for low-confidence items.

T13. Staff & roles. H1 "Staff" with primary "+ Invite staff".
     Table columns: Person (avatar + name + email beneath), Roles, Scope, Last active,
     Status pill, kebab.
     Roles render as 11px uppercase ringed chips — HOST_ADMIN, HOST_AUTHOR,
     PROGRAM_COORDINATOR, LECTURER, PROCTOR — and are NOT colour-coded by role.
     Scope shows branch or programme names with a "+2" overflow chip.
     Also render an open right slide-over "Assign roles", 420px wide, with the soft card
     shadow: a role checkbox group with a 12px description under each role, then a
     conditional scope picker that appears only for scoped roles (a searchable
     multi-select tree of Chi nhánh > Chương trình > Lớp), then a footer with secondary
     "Revoke access" in #BE452B text and primary "Save changes".

T14. Settings. H1 "Settings" with a left in-page tab rail:
     General · Branding · Notifications · Security.
     "Branding" active — this is the white-label screen.
     Left 560px form: a logo upload block (120x120 dashed dropzone showing the current
     logo, "Replace" and "Remove" text actions, spec line "SVG hoặc PNG, tối thiểu
     256x256, nền trong suốt"); a "Primary colour" field combining a swatch button, a hex
     input reading #4169E8 and a row of 6 suggested institution-safe swatches; a "Display
     name" input; a "Login page message" textarea.
     Beneath the colour field, a CONTRAST CHECK panel with rows:
     "Nút chính, chữ trắng" 4.76:1 pass · "Chữ liên kết" 6.00:1 pass · "Icon tile"
     3.29:1 pass (non-text) · and one FAILING row so the failure styling is visible —
     #5D87FF reading "3.29:1 — chữ trắng không đạt AA, hệ thống sẽ tự làm đậm màu nền nút
     và giữ màu của bạn cho icon tile". Each row has a pass/fail icon plus label.
     A 12px note: "Màu thương hiệu chỉ áp dụng cho điều hướng và nút bấm. Màu biểu đồ và
     trạng thái được cố định để báo cáo điểm so sánh được giữa các đơn vị."
     Right 520px: a live preview frame showing a miniature of the dashboard rendered with
     the chosen brand colour — and its chart visibly UNCHANGED.
     Footer: secondary "Reset to default", primary "Save branding".

T15. State pack — render as one screen split into six labelled quadrants, each at
     realistic size:
     (a) Destructive confirm modal: 480px, title "Xoá lớp PTE-79-A?", body explaining that
         32 learners lose access and attempt history is retained, a required text input
         "Nhập tên lớp để xác nhận", footer with secondary "Huỷ" and a solid #BE452B
         primary "Xoá lớp".
     (b) Empty state: centred in a card, a 48px blue icon tile, bold "Chưa có phiên thi
         nào", 14px body, primary "+ Create session" and a secondary "Import".
     (c) Error state: a card with a critical icon+label "Không tải được danh sách học
         viên", a 12px monospace correlation ID, and a secondary "Thử lại".
     (d) Loading skeleton: the learners table as skeletons — card with the soft shadow,
         6 rows of #EAEFF4 shimmer blocks at true column widths, header row solid.
     (e) Selected row + bulk bar: three table rows with the middle one selected
         (--brand-tint wash, checkbox checked) and the bulk action bar above.
     (f) Dropdown open: a kebab menu expanded showing four actions, one destructive in
         #BE452B, with the soft card shadow and 7px radius.

T16. Responsive. Two frames.
     Tablet 834x1112: sidebar collapsed to the 80px icon rail with tooltips; stat tiles
     reflow to 2x2; charts go full width in source order; tables scroll horizontally
     inside their card with the first column pinned; filters collapse to a single
     "Filters (3)" button.
     Mobile 390x844: sidebar becomes a slide-over drawer opened by a hamburger; stat tiles
     stack to one column; the top bar keeps only the logo, search icon and avatar; tables
     become stacked cards (one card per learner showing name, class, status pill and a
     chevron); touch targets at least 44px.
```

---

## Ràng buộc khi review output

**1. Palette Modernize gốc fail AA toàn bộ — đã sửa, đừng để Stitch trả lại màu cũ.**
Đo trực tiếp từ `DefaultColors.tsx` của template:

| token gốc | chữ trắng | bậc đã sửa |
|---|---|---|
| primary `#5D87FF` | **3.29:1** | `#4169E8` (4.76) |
| secondary `#49BEFF` | **2.08:1** | `#0E729F` (5.35) |
| success `#13DEB9` | **1.72:1** | `#088068` (4.89) |
| warning `#FFAE1F` | **1.85:1** | `#9C6400` (4.96) |
| error `#FA896B` | **2.37:1** | `#BE452B` (5.15) |

Giữ look: **màu gốc cho tint nền + icon tile + trang trí, bậc đậm cho chỗ có chữ đè lên.**
Chữ gốc `#2A3547` (12.36) và `#5A6A85` (5.48) đạt chuẩn, giữ nguyên.
`divider #e5eaef` chỉ 1.21:1 — đủ làm kẻ trang trí, **không đủ làm viền input** (đã đổi sang `#7C8FAC`).

**2. Reject ngay khi Stitch trả về:**
- Card có viền 1px — style này tách card bằng shadow mềm + nền xanh xám.
- Chữ trắng đè lên pastel gốc.
- Button viết HOA hoặc bold.
- Status chỉ bằng màu, không có icon + label.
- Dual-axis chart.
- Brand color dùng cho series chart.

Câu sửa: `Cards must have no border — separate them with the soft shadow on the tinted page background. Buttons are sentence case at weight 400. Status must be icon + text label + colour. Never put white text on the pastel hues; use the darkened action step.`

**3. Không tự thêm màn hình Reports/Analytics.** Tính năng chưa làm, đã cố ý bỏ khỏi pack.
Nếu Stitch tự sinh "Analytics" trong sidebar, xoá đi.
