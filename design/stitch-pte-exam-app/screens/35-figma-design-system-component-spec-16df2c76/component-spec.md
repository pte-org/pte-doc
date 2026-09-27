# PTE Academic CBT Delivery System — Figma Design System & Component Specification
*Comprehensive token dictionary, component matrix, layout grids, and handoff documentation for Pearson VUE standardized exam UI.*

---

## 1. Global Foundations & Tokens

### 1.1 Color Palette & Semantics

| Token Name | Hex Value | RGB / HSL | Usage & Application |
| :--- | :--- | :--- | :--- |
| `color/brand/primary` | `#0B5FAE` | `rgb(11, 95, 174)` | Primary exam buttons ("Next", "Start Test"), active radio/checkbox states, focus rings, primary brand badges |
| `color/brand/primary-hover` | `#094C8B` | `rgb(9, 76, 139)` | Hover state for primary buttons and interactive links |
| `color/brand/primary-active` | `#073B6D` | `rgb(7, 59, 109)` | Pressed/active button states |
| `color/brand/primary-light` | `#EBF3FC` | `rgb(235, 243, 252)` | Selected row/card background, radio card active fill, highlighted option tint |
| `color/brand/primary-subtle` | `#F0F6FF` | `rgb(240, 246, 255)` | Instruction header tint, sub-navigation pill backgrounds |
| `color/brand/navy-dark` | `#002244` | `rgb(0, 34, 68)` | Pearson deep corporate navy, dark section badges, high-contrast modal headers |
| `color/surface/canvas` | `#F7F9FF` | `rgb(247, 249, 255)` | Main window background for desktop test delivery window |
| `color/surface/card` | `#FFFFFF` | `rgb(255, 255, 255)` | Workstation cards, stimulus containers, input fields, white surface containers |
| `color/surface/subtle` | `#F1F4F9` | `rgb(241, 244, 249)` | Audio player tracks, disabled button backgrounds, table alternate rows |
| `color/border/default` | `#C9CFD9` | `rgb(201, 207, 217)` | Standard institutional container borders, question dividers, card outlines |
| `color/border/subtle` | `#E2E7EE` | `rgb(226, 231, 238)` | Light table borders, soft dividers, badge borders |
| `color/border/active` | `#0B5FAE` | `rgb(11, 95, 174)` | Active selection borders, active text input border |
| `color/text/primary` | `#1E293B` | `rgb(30, 41, 59)` | Standard high-contrast reading text, transcript body, question prompts |
| `color/text/secondary` | `#475569` | `rgb(71, 85, 105)` | Secondary notes, disclaimers, item reference tags, audio durations |
| `color/text/muted` | `#64748B` | `rgb(100, 116, 139)` | Footers, workstation engine watermarks, disabled state labels |
| `color/text/inverse` | `#FFFFFF` | `rgb(255, 255, 255)` | Text on primary buttons, navy header text, dark badge text |
| `color/status/warning-fill` | `#FEF3C7` | `rgb(254, 243, 199)` | Amber warning background (pooled timer warning, advisory banner) |
| `color/status/warning-text` | `#B45309` | `rgb(180, 83, 9)` | Pooled timer badge text, advisory icons |
| `color/status/warning-border` | `#FCD34D` | `rgb(252, 211, 77)` | Timer warning border |
| `color/status/danger-fill` | `#FEF2F2` | `rgb(254, 242, 242)` | Negative marking notice background, error validation fill |
| `color/status/danger-text` | `#DC2626` | `rgb(220, 38, 38)` | Negative marking warning text, recording active indicator |
| `color/status/danger-border` | `#FECACA` | `rgb(254, 202, 202)` | Penalty warning card border |
| `color/status/success-fill` | `#DCFCE7` | `rgb(220, 252, 231)` | Success confirmation badge background, completion banner fill |
| `color/status/success-text` | `#16A34A` | `rgb(22, 163, 74)` | Submission completed status text, verification checkmark |
| `color/status/success-border` | `#86EFAC` | `rgb(134, 239, 172)` | Final submission border |
| `color/interactive/highlight` | `#D9EBFF` | `rgb(217, 235, 255)` | Highlight Incorrect Words selected word background (`#1E40AF` text) |

---

### 1.2 Typography System (Arimo / Inter / System Sans)

*Primary Font Family: `Arimo`, fallback: `system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif`*

| Token Name | Font Size | Line Height | Weight | Letter Spacing | Purpose & Usage |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `typography/display-lg` | 24px (1.50rem) | 32px (1.33) | Bold (700) | -0.01em | Test completion headline, section transition screen titles |
| `typography/display-sm` | 20px (1.25rem) | 28px (1.40) | SemiBold (600) | -0.005em | Sub-header task title ("Write From Dictation", "Re-order Paragraphs") |
| `typography/heading-md` | 18px (1.125rem) | 26px (1.44) | SemiBold (600) | normal | Primary task instruction header ("You will hear a recording...") |
| `typography/heading-sm` | 16px (1.00rem) | 24px (1.50) | SemiBold (600) | normal | Section card header, modal dialog title, stimulus container header |
| `typography/body-lg` | 16px (1.00rem) | 26px (1.625) | Regular (400) | normal | Academic reading text passages, essay text prompt, transcript copy |
| `typography/body-md` | 14px (0.875rem) | 22px (1.57) | Regular (400) | normal | Standard instructional directives, multiple choice option text, FIB prompts |
| `typography/body-md-bold` | 14px (0.875rem) | 22px (1.57) | SemiBold (600) | normal | Option label prefix ("A.", "B."), table headers, field labels |
| `typography/body-sm` | 13px (0.8125rem) | 18px (1.38) | Regular (400) | normal | Audio playback instructions, candidate session table items, disclaimers |
| `typography/caption` | 12px (0.75rem) | 16px (1.33) | Medium (500) | +0.01em | Item count badges, status badges, skill metadata tags, timer numbers |
| `typography/mono-sm` | 12px (0.75rem) | 16px (1.33) | Regular (400) | +0.02em | Audio timestamp (`00:07 / 00:45`), transaction codes, SHA-256 tokens |

---

### 1.3 Spacing & Layout Rhythm

*Base Unit: `4px` grid system.*

| Token Name | Pixel Value | Typical Application |
| :--- | :--- | :--- |
| `space/0` | `0px` | Reset |
| `space/1` | `4px` | Pill internal vertical padding, badge micro-gap, inline icons |
| `space/2` | `8px` | Badge horizontal padding, gap between icon & label, tight card margin |
| `space/3` | `12px` | Standard button vertical padding, table row internal cell padding |
| `space/4` | `16px` | Container internal padding, gap between multiple choice options, toolbar padding |
| `space/5` | `20px` | Card internal padding (default), top header padding, section spacing |
| `space/6` | `24px` | Standard page outer horizontal padding, gap between major screen modules |
| `space/8` | `32px` | Section break padding, primary content vertical margin |
| `space/10` | `40px` | Large hero container padding |
| `space/12` | `48px` | Maximum bottom navigation bar clearance |

---

### 1.4 Corner Radii & Elevation Tokens

| Token Name | Value | Purpose & Target Elements |
| :--- | :--- | :--- |
| `radius/none` | `0px` | Pearson VUE legacy full-bleed containers |
| `radius/sm` | `3px` / `4px` | Standard buttons, badges, input fields, multiple choice option cards, dropdowns |
| `radius/md` | `6px` | Main content cards, audio player container, response box, NDA scroll panel |
| `radius/lg` | `8px` | Transition hero container, completion audit summary card |
| `radius/full` | `9999px` | Circular radio buttons, circular avatar icon, rounded status pills |
| `shadow/none` | `none` | Standard CBT border-driven elevation (0px blur, 1px border `#C9CFD9`) |
| `shadow/sm` | `0 1px 2px 0 rgba(0, 0, 0, 0.05)` | Light lift for active dragged tokens (Drag & Drop Blank words) |
| `shadow/dropdown` | `0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)` | Open dropdown select menus (Reading & Writing FIB) |

---

## 2. Desktop Shell Architecture & Fixed Frames

### 2.1 Top Persistent Header (`Header / Candidate Exam Chrome`)
- **Dimensions**: Full width (`100%`), fixed height: `56px`, background: `#FFFFFF`, border-bottom: `1px solid #C9CFD9`.
- **Left Cluster**:
  - Pearson Brandmark / Text Logo (`font-weight: 700`, `font-size: 16px`, `#002244`).
  - Vertical Divider (`1px solid #E2E7EE`, height: `20px`).
  - Exam Series Tag: `"PTE Academic"` (`font-weight: 600`, `font-size: 14px`, `#1E293B`).
- **Center-Right Cluster (Candidate Credentials)**:
  - Candidate Name: `"Nguyen Van A"` (`font-weight: 600`, `font-size: 13px`, `#1E293B`).
  - Candidate ID Badge: `"Candidate ID: 12345678"` (`font-size: 12px`, `#64748B`).
- **Right Utilities**:
  - Headset Volume Icon button (32x32px click target).
  - Item Progress Pill: `"1 of 20"` or `"ITEM 8 OF 20"` (`font-size: 13px`, `#1E293B`).
  - Countdown Clock: `"Time remaining 00:35:00"` with clock icon (`font-weight: 500`, `#1E293B`).
  - Profile Avatar Placeholder: 32x32px circular `#0B5FAE` with user glyph.

### 2.2 Bottom Persistent Action Bar (`Footer / Workstation Controls`)
- **Dimensions**: Full width (`100%`), fixed height: `64px`, background: `#FFFFFF`, border-top: `1px solid #C9CFD9`.
- **Left Action**:
  - Secondary Outline Button: `"Save & Exit"` (Border: `1px solid #0B5FAE`, text: `#0B5FAE`, height: `38px`, padding: `0 16px`, radius: `4px`).
- **Center Audit Meta**:
  - Single-line muted text: `● Workstation Session Verified • Pearson VUE Secure Engine v4.28.1 • Algorithm: [Scoring Type]` (`11px`, `#64748B`).
- **Right Navigation Controls**:
  - Secondary Ghost/Outline Button: `"Previous"` (Disabled or enabled based on item type; gray border `#C9CFD9` or hidden in one-way exam sections).
  - Primary Action Button: `"Next"` / `"Start Test"` (Background: `#0B5FAE`, color: `#FFFFFF`, height: `38px`, padding: `0 24px`, radius: `4px`, `font-weight: 600`).

---

## 3. Core Component Matrix & Variant Specifications

### Component 1: Primary Task Instruction Card (`Banner / Instruction Box`)
- **Figma Structure**: Auto-layout vertical, fill container.
- **Visuals**:
  - Background: `#FFFFFF`.
  - Border: `1px solid #C9CFD9`, with an institutional thick left accent border: `4px solid #0B5FAE`.
  - Internal Padding: `16px 20px`.
  - Radius: `4px`.
- **Children**:
  - Header line: Bold prompt text (`16px`, `line-height: 24px`, `#1E293B`).
  - Sub-guideline: Contextual helper text (`13px`, `#475569`).
  - Metadata Pill Row: Auto-layout horizontal wrap (`gap: 8px`), displaying pills:
    - Audio Status (`⏱ Audio Status: Completed`)
    - Scoring Model (`➕ Partial Credit Scoring` or `⚠️ Negative Marking`)
    - Input Mode (`⌨ Keyboard Input: Text area response`)

---

### Component 2: Audio Stimulus & Recording Container (`Media / Audio Player`)
- **Figma Structure**: Auto-layout vertical, centered or full width, padding: `16px 20px`, background: `#F0F6FF`, border: `1px solid #C9CFD9`, radius: `6px`.
- **Variants**:
  1. `State = Preparing / Countdown`:
     - Badge: `● BEGINS IN: 00:05` (Amber `#B45309`).
     - Progress Bar: 0% filled track.
  2. `State = Playing / Listening`:
     - Badge: `● PLAYING (00:14 / 00:45)` (Primary `#0B5FAE`).
     - Progress Bar: Animated active fill `#0B5FAE` over neutral `#D1DBE8` track.
  3. `State = Playback Finished`:
     - Badge: `● PLAYBACK FINISHED (00:45 / 00:45)` (Gray `#475569`).
     - Progress Bar: 100% solid fill `#64748B`.
  4. `State = Recording (Speaking)`:
     - Badge: `● RECORDING (00:18 / 00:40)` (Red pulse `#DC2626`).
     - Audio Level Waveform / Decibel indicator bars (Green/Yellow/Red gradient).

---

### Component 3: Standard Multiple Choice Option Item (`Form / Choice Row`)
- **Figma Structure**: Auto-layout horizontal, padding: `14px 18px`, width: fill container, radius: `4px`.
- **Variants**:
  - `Type = Single Choice (Radio)` vs `Type = Multiple Choice (Checkbox)`
  - `State = Default`:
    - Border: `1px solid #C9CFD9`, Background: `#FFFFFF`.
    - Selector glyph: Unchecked circular radio `○` or square checkbox `□` (18x18px, border `#94A3B8`).
    - Text: `#1E293B` (`14px`, `line-height: 22px`).
  - `State = Hover`:
    - Border: `1px solid #94A3B8`, Background: `#F8FAFC`.
  - `State = Selected`:
    - Border: `1.5px solid #0B5FAE`, Background: `#F0F7FD`.
    - Selector glyph: Checked filled circular radio `◉` or blue filled check square `☑` (`#0B5FAE`).
    - Right-aligned optional badge: `"Selected"` pill (Font size: `11px`, background: `#D9EBFF`, color: `#0B5FAE`).

---

### Component 4: Drag & Drop Word Bank Token (`Interactive / FIB Chip`)
- **Figma Structure**: Auto-layout inline horizontal, padding: `6px 14px`, height: `32px`, radius: `4px`.
- **Variants**:
  - `State = In Bank (Available)`:
    - Background: `#FFFFFF`, Border: `1.5px solid #0B5FAE`, Color: `#0B5FAE`, Font: `13px SemiBold`, Shadow: `0 1px 2px rgba(0,0,0,0.05)`.
  - `State = Dragging`:
    - Background: `#0B5FAE`, Border: `1.5px solid #073B6D`, Color: `#FFFFFF`, Opacity: `90%`, Cursor: `grabbing`.
  - `State = Placed in Blank Slot`:
    - Background: `#EBF3FC`, Border: `1px solid #0B5FAE`, Color: `#0B5FAE`.
  - `State = Empty Target Slot (in passage)`:
    - Height: `30px`, Min-width: `90px`, Background: `#F1F4F9`, Border: `1.5px dashed #94A3B8`, Radius: `4px`.

---

### Component 5: Dropdown In-Text Selector (`Form / In-Text Select`)
- **Figma Structure**: Inline select trigger embedded within body paragraph copy.
- **Specs**:
  - Dimensions: Height: `28px`, Min-width: `130px`, Padding: `2px 28px 2px 10px`.
  - Background: `#FFFFFF` with custom chevron-down icon at `right: 8px`.
  - Border: `1.5px solid #0B5FAE` (or `#C9CFD9` when unselected).
  - Radius: `3px`.
  - Text: `13px`, `#1E293B`.
  - Open Dropdown Menu: Auto-layout vertical list, background `#FFFFFF`, border `1px solid #C9CFD9`, shadow `shadow/dropdown`, option hover `#F0F7FD`.

---

### Component 6: Highlightable Word Element (`Interactive / HIW Word Span`)
- **Figma Structure**: Inline text span with hover & active toggle states.
- **Specs**:
  - Font: `15px`, `line-height: 26px`, font family Arimo.
  - Padding: `2px 4px`, Radius: `2px`, Margin: `0 1px`.
  - `State = Normal`: Color `#1E293B`, background `transparent`.
  - `State = Hover`: Background `#E2E8F0`, cursor `pointer`.
  - `State = Active Highlighted`: Background `#D9EBFF`, Color: `#0B5FAE`, font-weight `600`, Border-bottom: `2px solid #0B5FAE`.

---

### Component 7: Response Textarea & Live Metric Counter (`Input / Exam Textarea`)
- **Figma Structure**: Auto-layout vertical, border: `1px solid #C9CFD9`, radius: `4px`, background: `#FFFFFF`.
- **Sub-elements**:
  - Utility Toolbar: Auto-layout horizontal (`Cut`, `Copy`, `Paste` buttons with keyboard shortcut indicators).
  - Textarea: Multi-line text field (`font-size: 14px`, `line-height: 22px`, font: Arimo, padding: `12px 16px`, min-height: `180px`).
  - Footer Bar: Auto-layout horizontal space-between (`padding: 8px 14px`, background: `#F8FAFC`, border-top: `1px solid #E2E7EE`):
    - Left: Counter pill: `13 words • 115 characters` (`font-size: 12px`, `#475569`).
    - Right: Storage indicator: `☁ Auto-saved to test buffer` with green status dot.

---

### Component 8: Sub-Header Section Banner (`Header / Sub-Navigation Bar`)
- **Figma Structure**: Auto-layout horizontal space-between, padding: `10px 24px`, background: `#F0F6FF`, border-bottom: `1px solid #C9CFD9`.
- **Elements**:
  - Left cluster: Dark navy category pill (`PART 1: SPEAKING & WRITING` / `PART 2: READING` / `PART 3: LISTENING`) + Task title (`Read Aloud`, `Write Essay`).
  - Middle cluster: Item counter tag (`ITEM 8 OF 20`), Task counter tag (`Task 1 of 3`), Skills pill (`Skills Assessed: Listening & Writing`).
  - Right cluster: Section pooled timer tag (`⏱ Section Pooled Timer: ~11:15 remaining`) or Scoring notice (`⚠️ Negative Marking: +1 / -1`).

---

## 4. Figma Implementation Guide & Dev Handoff

### 4.1 Recommended Figma Layer & Frame Hierarchy
```
PTE-CBT-Delivery-System /
├── 00_Foundations /
│   ├── Color Styles (PTE/Brand, PTE/Surface, PTE/Border, PTE/Status)
│   ├── Typography Styles (PTE/Display, PTE/Heading, PTE/Body, PTE/Mono)
│   └── Effect Styles (PTE/Elevation-None, PTE/Elevation-SM, PTE/Dropdown)
├── 01_Atoms /
│   ├── Badges & Status Pills
│   ├── Icons (Volume, Clock, User, Mic, Play, Pause, DragHandle, Check, Shield)
│   ├── Form Controls (Radio-Single, Checkbox-Multi, Dropdown-Inline)
│   └── Buttons (Primary, Secondary-Outline, Ghost-Previous, Utility-CutCopy)
├── 02_Molecules /
│   ├── Persistent-Header
│   ├── Persistent-Footer
│   ├── Instruction-Card
│   ├── Audio-Stimulus-Player
│   ├── Word-Bank-Tray
│   └── Response-Textarea-With-Metrics
├── 03_Organisms /
│   ├── Question-Card-SingleChoice
│   ├── Question-Card-MultiChoice
│   ├── Question-Card-ReorderParagraphs
│   ├── Question-Card-FillInBlanks-Dropdown
│   ├── Question-Card-FillInBlanks-DragDrop
│   └── Question-Card-HighlightIncorrectWords
└── 04_Templates /
    ├── Template-PreTest (Sign-in, Identity, Equipment Checks, NDA)
    ├── Template-TransitionBreak (Part 1, Part 2, Part 3 instructions)
    ├── Template-QuestionDelivery (Standard 2-column or single column CBT frame)
    └── Template-PostTest (Final audit, summary receipt, TA protocol)
```

### 4.2 Auto-Layout & Constraints Configuration
1. **Desktop Frame**: `Width: 1440px` (or `1920px` for high-res proctor terminals), `Height: 900px` minimum.
2. **Main Layout Frame**: Vertical Auto-Layout, `Spacing: 0`, `Padding: 0`.
   - Top Header: `Height: Fixed 56px`, `Width: Fill container`.
   - Sub-header: `Height: Hug contents (min 44px)`, `Width: Fill container`.
   - Content Viewport: `Height: Fill container` (with vertical scroll permitted if stimulus exceeds fold), `Width: Fill container`, `Padding: 24px`.
   - Bottom Footer: `Height: Fixed 64px`, `Width: Fill container`.
3. **Responsive Behaviors**:
   - Content container maximum width: `1120px` to `1200px` centered with auto-margins to ensure comfortable academic reading eye travel distance (60–80 characters per line).

---

*This specification matches 100% of the screens generated in the PTE CBT suite (Screens 1 through 33) and is immediately ready for Figma component library setup, variable token authoring, and frontend engineering handoff.*