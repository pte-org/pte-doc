# Stitch Prompt — vendor-web (Platform Admin)

App: `pte-web/apps/vendor-web`. Role: PLATFORM_ADMIN / PLATFORM_AUTHOR.

Style: dùng **chung design system** với [stitch-tenant-web-prompt.md](stitch-tenant-web-prompt.md) —
mục D0 dưới đây giống hệt, chỉ khác nav và nội dung. Output hai app sẽ ghép được với nhau.

**Cách dùng:** dán **PROMPT D0** trước → generate app shell. Sau đó mỗi lần dán **một screen**,
mở đầu bằng:
`Keep the EXACT same design system, shell, type scale and component styling as the previous screen. Now generate:`

> **Tạm hoãn:** các màn hình thống kê nặng (scoring pipeline health, report rebuilds, platform-wide
> analytics) đã được bỏ khỏi pack — tính năng chưa làm. V1 vẫn giữ vài chỉ số và 1 biểu đồ đơn giản.

---

## Screen Inventory (13)

### A — Đã có route trong `vendor-web`

| # | Screen | Route | Component hiện có |
|---|---|---|---|
| V1 | Platform overview | `/admin` | `dashboard/OverviewView`, `_AdminStatGrid`, `_RecentTenantsTable`, `_SystemNoticeBanner`, `_VietnamTenantMap` |
| V2 | Tenants list | `/admin/tenants` | `tenancy/*` |
| V3 | Tenant detail | `/admin/tenants/[publicId]` | `_TenantDetailModal` |
| V4 | Licences & quota | `/admin/licenses` | `licensing/LicensingView`, `_LicenseStatGrid`, `_LicenseTable` |
| V5 | Grant quota + lịch sử | trong V4 | `GrantQuotaModal`, `QuotaHistoryModal` |
| V6 | Question bank | `/admin/questions` | `questionbank/QuestionBankView`, `_QuestionFilters`, `_QuestionStatGrid`, `_QuestionTable` |
| V7 | Question editor | trong V6 | `QuestionEditorForm` |
| V8 | Exam builder | `/admin/exams` | `examoperations/ExamBuilderForm` |
| V9 | Login | `/login` | `auth/LoginView`, `_AuthBrandPanel` |

### B — Roadmap (chưa có route)

| # | Screen |
|---|---|
| V10 | Create tenant wizard |
| V11 | Platform users & roles |
| V12 | Platform settings & feature flags |

### C — Hệ thống

| # | Screen |
|---|---|
| V13 | State pack + responsive |

---

## PROMPT D0 — Design System Anchor (dán đầu tiên)

```
You are designing the platform admin console for a multi-tenant PTE (Pearson Test of
English) assessment platform sold to universities and language institutes. Users are
platform operators and content authors. They manage tenants, licences and quota, the
central question bank and exam blueprints.

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
- Vanity metrics (MRR, growth, streaks, confetti). Metrics here are operational:
  tenants, learners under licence, attempts delivered, quota consumed, published items.
- Saturated pastel used as a fill behind small text.

LAYOUT SHELL (identical on every screen)
- Desktop 1440x900. Left sidebar 270px, collapsible to an 80px icon rail.
  Sidebar #FFFFFF, NO right border — it separates because the content plane is tinted.
  Platform logo block 60px tall at the top (this is the vendor's own mark, fixed — it is
  NOT white-labelled).
  Nav items: 14px label, 45px row height, 12px horizontal padding, 7px radius,
  full-width rounded rectangles. ACTIVE item is a filled --brand rectangle with white
  label and white icon; hover is a --brand-tint wash with --brand-ink label.
  Section captions 12px weight 600 #7C8FAC, 24px top margin.
- Top bar 70px #FFFFFF, no border, soft shadow only when scrolled.
  Left: sidebar-collapse icon button, then the breadcrumb (14px, "/" separators).
  Right: search icon button, notification bell with a small red dot badge, 35px circular
  avatar with name and role caption "Platform admin". Header icon buttons are 40px
  circles taking a --brand-tint background on hover.
- Content plane #F2F6FA, 24px page padding, max-width 1200px centred, 12-column grid,
  24px gutters, 24px row gap.
- Cards: #FFFFFF, 7px radius, NO border, 24px padding, signature soft shadow
  `rgba(145,158,171,0.30) 0px 0px 2px 0px, rgba(145,158,171,0.12) 0px 12px 24px -4px`.
  Card header = 18px/600 title, optional 14px #5A6A85 subtitle, action right-aligned.
- Page header: H1 21px/600, 14px #5A6A85 description beneath, actions right-aligned on
  the H1 baseline.

SIDEBAR NAVIGATION
HOME        Dashboard
TENANTS     Tenants · Licences
CONTENT     Question bank · Exam blueprints
SETTINGS    Platform users · Settings

Sidebar bottom: user mini profile plus a compact platform status block —
a mint dot with "All systems operational" and a 12px "Updated 2 min ago".

TYPOGRAPHY
- "Plus Jakarta Sans", Helvetica, Arial, sans-serif — weights 300/400/500/600/700.
  Used for all text including chart labels. No serif anywhere.
- Scale: H1 36/600, H2 30/600, H3 24/600, H4 21/600, H5 18/600, H6 16/600,
  body 14/400 (line-height 1.334), small 12/400.
  Page titles use H4 (21px); card titles use H5 (18px).
- Buttons are sentence case at weight 400.
- Tabular numerals on every table column, axis tick and numeric figure.

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

Unlike the tenant console, this app is NOT white-labelled — the brand blue is fixed.
But keep the same rule that --brand never colours a chart series or a status.

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
- Series colours, fixed, never themed:
  1 #2a78d6 blue, 2 #eb6834 orange, 3 #1baf7a aqua, 4 #eda100 yellow.
  Never more than 4 series; a 5th folds into "Other".
- NEVER a dual-axis chart. Two measures of different scale become two charts.
- Bars have 4px rounded ends on the data end only. Lines 2px. Dots >= 8px.
- Gridlines 1px #E5EAEF, horizontal only, behind the marks. Axis #DFE5EF.
  Tick labels 11px #7C8FAC.
- 2+ series get a legend; a single-series chart gets NO legend — the card title names it.
- Never print a value on every data point — label endpoints and the maximum only.
- Every chart has a hover tooltip showing category, value and unit.

ACCESSIBILITY (WCAG 2.2 AA)
- Body text >= 4.5:1. Visible 2px focus ring on every interactive element.
- Full keyboard operation; tables have real headers and a visible sort affordance.
- Never encode meaning with colour alone — pair with icon or label.
- Support 200% zoom without horizontal scroll on the content column.

Use realistic Vietnamese sample data: institute names (Hanoi Language Institute, Trung
tâm Anh ngữ Sao Mai, IELTS/PTE Academy Đà Nẵng), cities (Hà Nội, TP. Hồ Chí Minh,
Đà Nẵng, Cần Thơ), and staff names (Trần Thị Mai, Lê Minh Quân).

FIRST SCREEN TO GENERATE NOW: V1 below.
```

---

## PROMPT V1–V13

```
V1. Platform overview. Breadcrumb "Dashboard". H1 "Platform overview" with a date-range
    dropdown right-aligned.
    Row 0 — a dismissible system notice banner directly under the page header: a sky
    #E8F7FF block with an info icon, "Bảo trì theo lịch vào 02:00 ngày 20/09 — dự kiến 30
    phút", a "Chi tiết" text link and a small close control on the right.
    Row 1 — four stat tiles, each with a pastel icon tile on the left, the label in 14px
    #5A6A85 above and the figure in 24px/600 below:
    blue "Tenants đang hoạt động 37" · sky "Học viên theo licence 12,480 / 15,000" (with a
    thin usage bar) · mint "Bài thi đã phục vụ 48,213" · cream "Tenant sắp hết quota 4".
    Row 2 — 7/5 split. Left, chart card "Attempts delivered": subtitle "Toàn nền tảng theo
    tháng", a period dropdown in the header, a soft blue bar chart with 12 monthly bars,
    rounded tops, 2 series (PTE Academic, PTE Core), small legend.
    Right, card "Phân bố tenant": a stylised map of Vietnam with dots sized by the number
    of tenants per province, a small legend, and a 12px caption listing the top 3 cities.
    Keep it flat and geometric — no 3D, no satellite imagery, no photo texture.
    Row 3 — full-width card "Tenants mới nhất": table with Tenant (24px rounded-square
    logo placeholder + name + organisation type in 12px beneath), Gói, Học viên
    (used / limit with a thin inline bar and a numeric label), Chi nhánh, Status pill,
    Ngày tạo, and a "Xem" text link.

V2. Tenants list. H1 "Tenants" with primary "+ Add tenant".
    Filter row: search, Status select (Active / Suspended), Package select, Organisation
    type select, a right-aligned "12 of 37 shown" count and a "Clear filters" text button.
    Table columns: checkbox, Tenant (logo placeholder + name + organisation type beneath),
    Package, Learners (used / limit with a 2px inline usage bar that turns cream above 85%
    and blush at 100% — always with a numeric label beside it, never colour alone),
    Branches, Status pill (Active mint / Suspended blush), Created, kebab.
    Sortable headers, sticky header, 1px #E5EAEF row dividers, no zebra.
    Pagination footer "1–10 of 37" with a rows-per-page select.
    Kebab menu: "Manage quota", "Impersonate", "Suspend tenant" (in #BE452B).

V3. Tenant detail. Breadcrumb "Tenants / Hanoi Language Institute".
    Page header band: 48px tenant logo placeholder, tenant name as H1, a Status pill, and
    meta chips (Gói: Institution · Tenant ID in monospace · Ngày tạo).
    Actions right-aligned: secondary "Impersonate", secondary "Suspend", primary
    "Manage quota".
    Tabs: Overview | Chi nhánh | Người dùng | Quota | Phiên thi. "Overview" active with a
    2px --brand underline.
    8/4 split. Left, chart card "Licence usage over time": a single-series line chart
    (#2a78d6, 2px) with a dashed #DFE5EF horizontal reference line labelled "Giới hạn 500"
    at its right end, and only the endpoint and the maximum labelled. No legend.
    Right, two stacked cards: "Thông tin" as a definition list (Loại tổ chức · Người liên
    hệ · Khu vực · Múi giờ), and "Tình trạng" with three status rows, each icon + label +
    value.
    Also render the tenant detail as a MODAL variant (this exists in the product): a 720px
    modal with the same header band and the "Thông tin" definition list, footer with
    secondary "Đóng" and primary "Xem chi tiết".

V4. Licences & quota. H1 "Licences" with primary "+ Grant quota".
    Row 1 — four stat tiles with pastel icon tiles: blue "Tổng ghế đã cấp 15,000" ·
    mint "Đang dùng 12,480" · sky "Đang giữ chỗ 620" · cream "Còn lại 1,900".
    Row 2 — full-width card "Licence theo tenant": table with Tenant, Gói, Đã cấp,
    Đã dùng, Còn lại, Tỉ lệ dùng (a thin bar plus a percentage text label), Hết hạn,
    Status pill, kebab.
    Rows above 85% usage show a cream warning icon+label; rows at 100% show blush
    "Hết quota". Never colour alone — always the numeric label beside the bar.
    Kebab: "Grant quota", "Xem lịch sử", "Thu hồi".

V5. Quota modals. Render two frames.
    (a) "Grant quota" modal, 520px: a read-only tenant row at the top (logo + name +
        current usage), a radio group Cấp thêm / Trừ bớt / Thu hồi, an Amount number
        input, a Gói select, a required Lý do textarea with the 12px helper "Được ghi vào
        audit log", and a footer with secondary "Huỷ" and primary "Áp dụng".
        When "Thu hồi" is selected, a blush warning callout appears with an icon:
        "Thu hồi ghế đang được sử dụng sẽ khoá truy cập của học viên tương ứng."
    (b) "Quota history" modal, 720px: a table with Thời điểm, Hành động (a chip — Cấp
        thêm mint dot, Trừ bớt grey dot, Thu hồi blush dot, each with its text label),
        Số lượng (right-aligned tabular, signed +100 / −25, the sign shown in text not
        colour alone), Người thực hiện (avatar + name), Số dư sau, Ghi chú.
        Footer: secondary "Export CSV", primary "Đóng".

V6. Question bank. H1 "Question bank" with primary "+ New question".
    Row 1 — four stat tiles: blue "Tổng câu hỏi 1,284" · mint "Đã xuất bản 1,102" ·
    cream "Đang chờ duyệt 46" · sky "Bản nháp 136".
    Row 2 — an 8/4 split where the RIGHT side is a 280px filter rail INSIDE the content
    area (not the nav): collapsible checkbox facet groups with 12px uppercase captions —
    Kỹ năng (Speaking, Writing, Reading, Listening), Loại câu hỏi (a scrollable list of
    the 20 PTE task types with a count beside each), Độ khó, Trạng thái (Draft, In review,
    Published, Retired).
    Left: a card containing a search field, a 12px results line "1,284 câu hỏi · 3 bộ lọc
    đang áp dụng", and a dense table with Item ID (monospace), Loại câu hỏi, Trích đoạn đề
    (truncated), Độ khó (a 5-step dot scale with a numeric label beside it), Lượt dùng,
    Status pill, Cập nhật, kebab.

V7. Question editor. Breadcrumb "Question bank / Câu hỏi mới".
    Two-pane. Left 680px form card, fields grouped under 12px uppercase section captions:
    "Phân loại" (Kỹ năng select, Loại câu hỏi select set to "Re-order Paragraphs", Độ khó
    select, Tag multi-select chips), "Nội dung" (a prompt textarea, and a repeatable
    "Đoạn văn" list with drag handles plus add and remove controls), "Thời gian"
    (Prep seconds and Response seconds number inputs prefilled 0 and 75), "Đáp án"
    (an ordered list showing the correct sequence).
    Right 420px sticky column: a "Xem trước" card rendering the actual exam task screen in
    miniature inside a bordered frame, and a "Kiểm tra" panel listing three validation
    rows with pass/fail icon + label ("Đủ số đoạn văn", "Thời gian trong giới hạn",
    "Đã gắn ít nhất 1 tag").
    Sticky footer: secondary "Lưu nháp", secondary "Xem trước", primary "Gửi duyệt".

V8. Exam builder. Breadcrumb "Exam blueprints / PTE Academic Standard".
    Two-pane. Left 720px: an ordered list of exam parts as collapsible sections — Phần 1
    Speaking & Writing, Phần 2 Reading, Phần 3 Listening. Each section expands to rows of
    task-type slots; each row has a drag handle, the task type name, a count stepper,
    prep/response second inputs, and a selection-rule select (Ngẫu nhiên từ kho / Câu cố
    định / Theo độ khó).
    Right 400px sticky: a "Tổng quan" card with total item count and estimated duration
    broken down per part as one stacked horizontal bar (3 segments, series colours 1–3,
    each segment labelled beneath the bar), plus a "Kiểm tra" panel with pass/fail rows
    ("Số câu Speaking đúng chuẩn", "Kho có đủ câu đã xuất bản", "Tổng thời lượng dưới 120
    phút").
    Footer: secondary "Lưu nháp", primary "Xuất bản blueprint".

V9. Login. Desktop split layout, no app shell.
    Left half: a soft blue panel (#ECF2FF) with the platform logo and a simple abstract
    geometric illustration — no mascot, no photography.
    Right half: white panel, centred 400px column. "Welcome back" as H3, "Đăng nhập để
    tiếp tục" in 14px #5A6A85. Email and Password fields, "Remember me" checkbox and a
    "Quên mật khẩu?" text link on the same row, a full-width primary "Sign in" button.
    Also render the error state: an inline blush alert above the fields reading
    "Email hoặc mật khẩu không đúng" with an error icon.

V10. Create tenant wizard. A 5-step horizontal stepper at the top: Tổ chức · Gói · Quản
     trị viên · Thương hiệu · Xác nhận. Step 3 active — completed steps show a mint tick,
     the active step a filled --brand dot, future steps a hollow #DFE5EF dot, connected by
     a 1px #E5EAEF rule.
     Form column 640px: Họ, Tên, Email công việc, Vai trò (a disabled input reading
     "HOST_ADMIN" with the 12px helper "Người dùng đầu tiên bắt buộc là quản trị viên của
     đơn vị"), and a checkbox "Gửi email mời ngay".
     Right rail 320px sticky: a "Tóm tắt" card recapping steps 1–2 as a definition list
     with an "Sửa" text link per row.
     Sticky footer: secondary "Quay lại", text button "Lưu và tiếp tục sau", primary
     "Tiếp tục".

V11. Platform users & roles. H1 "Platform users" with primary "+ Invite user".
     Table: Người dùng (avatar + name + email beneath), Vai trò (11px uppercase ringed
     chips — PLATFORM_ADMIN, PLATFORM_AUTHOR — NOT colour-coded by role), Phạm vi (reads
     "Toàn nền tảng" or a tenant name), Hoạt động gần nhất, MFA (icon + label "Đã bật" /
     "Chưa bật"), Status pill, kebab.
     Also render an open right slide-over "Phân quyền", 420px, with the soft card shadow:
     a role checkbox group with a 12px description under each role, a "Hoạt động gần đây"
     list of 5 entries, and a footer with secondary "Thu hồi truy cập" in #BE452B text and
     primary "Lưu".

V12. Platform settings. H1 "Platform settings" with a left in-page tab rail:
     Feature flags · Bảo mật · Lưu trữ dữ liệu · Tích hợp.
     "Feature flags" active: a list of flag rows, each a card-like block with the flag key
     in monospace, a plain-language description in 14px #5A6A85, and a toggle on the
     right. Beneath each, a "Phạm vi" line showing either "Tất cả tenant" or a chip list
     of specific tenants with a "+4" overflow chip.
     Risky flags carry a cream warning icon+label line "Ảnh hưởng tới phiên thi đang chạy".

V13. State pack and responsive — render as one screen split into labelled panels:
     (a) Destructive confirm modal, 480px: "Tạm ngưng Hanoi Language Institute?", body
         explaining that 312 learners lose access immediately and in-progress attempts are
         aborted, a required text input "Nhập tên tenant để xác nhận", footer with
         secondary "Huỷ" and a solid #BE452B primary "Tạm ngưng".
     (b) Empty state: centred in a card, a 48px blue icon tile, bold "Chưa có tenant nào",
         14px body, primary "+ Add tenant" and secondary "Import from CSV".
     (c) Error state: a card with a critical icon+label "Không tải được danh sách tenant",
         a 12px monospace correlation ID, and a secondary "Thử lại".
     (d) Loading skeleton: the tenants table as skeletons — card with the soft shadow,
         6 rows of #EAEFF4 shimmer blocks at true column widths, header row solid.
     (e) Tablet 834x1112: sidebar collapsed to the 80px icon rail; stat tiles reflow to
         2x2; the chart goes full width; the table scrolls horizontally inside its card
         with the Tenant column pinned.
     (f) Mobile 390x844: sidebar becomes a slide-over drawer; stat tiles stack to one
         column; the tenants table becomes stacked cards (one per tenant showing logo,
         name, usage bar, status pill and a chevron); touch targets at least 44px.
```

---

## Ràng buộc khi review output

**1. Palette Modernize gốc fail AA toàn bộ — đã sửa, đừng để Stitch trả lại màu cũ.**

| token gốc | chữ trắng | bậc đã sửa |
|---|---|---|
| primary `#5D87FF` | **3.29:1** | `#4169E8` (4.76) |
| secondary `#49BEFF` | **2.08:1** | `#0E729F` (5.35) |
| success `#13DEB9` | **1.72:1** | `#088068` (4.89) |
| warning `#FFAE1F` | **1.85:1** | `#9C6400` (4.96) |
| error `#FA896B` | **2.37:1** | `#BE452B` (5.15) |

Giữ look: **màu gốc cho tint nền + icon tile + trang trí, bậc đậm cho chỗ có chữ đè lên.**
`divider #e5eaef` chỉ 1.21:1 — đủ làm kẻ trang trí, không đủ làm viền input (đã đổi sang `#7C8FAC`).

**2. Reject ngay khi Stitch trả về:**
- Card có viền 1px — style này tách card bằng shadow mềm + nền xanh xám.
- Chữ trắng đè lên pastel gốc.
- Button viết HOA hoặc bold.
- Status chỉ bằng màu, không có icon + label.
- Dual-axis chart.
- Bản đồ ở V1 vẽ kiểu 3D / ảnh vệ tinh — phải phẳng, hình học.

**3. Khác biệt duy nhất về màu so với tenant-web:** app này **không** white-label, brand blue cố
định. Mọi token còn lại giống hệt để output hai app ghép được với nhau.

**4. Không tự thêm màn hình thống kê.** Scoring pipeline health, report rebuilds và analytics
toàn nền tảng đã cố ý bỏ khỏi pack — tính năng chưa làm.
