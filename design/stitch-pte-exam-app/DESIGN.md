---
name: Standardized Assessment Test Delivery System
colors:
  surface: '#f7f9ff'
  surface-dim: '#d1dbe8'
  surface-bright: '#f7f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#edf4ff'
  surface-container: '#e4effd'
  surface-container-high: '#dfe9f7'
  surface-container-highest: '#d9e3f1'
  on-surface: '#121d26'
  on-surface-variant: '#414751'
  inverse-surface: '#27313c'
  inverse-on-surface: '#e8f2ff'
  outline: '#727783'
  outline-variant: '#c1c6d3'
  surface-tint: '#0a5fae'
  primary: '#004787'
  on-primary: '#ffffff'
  primary-container: '#0b5fae'
  on-primary-container: '#c5daff'
  inverse-primary: '#a6c8ff'
  secondary: '#555f6e'
  on-secondary: '#ffffff'
  secondary-container: '#d9e3f5'
  on-secondary-container: '#5b6574'
  tertiary: '#00522d'
  on-tertiary: '#ffffff'
  tertiary-container: '#196c40'
  on-tertiary-container: '#9aeab3'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d5e3ff'
  primary-fixed-dim: '#a6c8ff'
  on-primary-fixed: '#001c3b'
  on-primary-fixed-variant: '#004786'
  secondary-fixed: '#d9e3f5'
  secondary-fixed-dim: '#bdc7d8'
  on-secondary-fixed: '#121c29'
  on-secondary-fixed-variant: '#3e4756'
  tertiary-fixed: '#a4f4bc'
  tertiary-fixed-dim: '#88d7a1'
  on-tertiary-fixed: '#00210f'
  on-tertiary-fixed-variant: '#00522c'
  background: '#f7f9ff'
  on-background: '#121d26'
  surface-variant: '#d9e3f1'
typography:
  headline-lg:
    fontFamily: Arimo
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
  headline-md:
    fontFamily: Arimo
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 24px
  instruction-bold:
    fontFamily: Arimo
    fontSize: 16px
    fontWeight: '700'
    lineHeight: 24px
  body-passage:
    fontFamily: Arimo
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 25.6px
  body-regular:
    fontFamily: Arimo
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-bold:
    fontFamily: Arimo
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 20px
  timer-tabular:
    fontFamily: Arimo
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 20px
    letterSpacing: 0.02em
  label-meta:
    fontFamily: Arimo
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-bold:
    fontFamily: Arimo
    fontSize: 13px
    fontWeight: '700'
    lineHeight: 18px
  caption:
    fontFamily: Arimo
    fontSize: 11px
    fontWeight: '400'
    lineHeight: 14px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system defines a high-stakes, institutional examination delivery engine modeled on high-security academic testing environments. The interface prioritizes cognitive clarity, visual neutrality, and zero distraction. Every visual flourish—gradients, soft elevations, glassmorphism, or expressive curvature—is strictly eliminated in favor of predictable, utilitarian affordances.

The experience addresses test candidates operating under strict time limits. The system conveys absolute procedural authority, algorithmic fairness, and technical reliability. Visual styling aligns strictly with rigorous academic standards: high-contrast typography, structural grid alignment, crisp 1-pixel borders, and disciplined layout density.

## Colors

The palette uses a deliberate, high-legibility institutional color scheme:

- **Canvas & Panels**: The root canvas background is pure white (`#FFFFFF`). Subordinate containers, item review panels, metadata banners, and card components use a calm, neutral grey (`#F4F5F7`).
- **Primary Brand**: Primary interactions, navigational advancement, and active indicator bars use `#0B5FAE`. On hover, the primary state shifts to `#094C8C`. Focused states receive a sharp, non-blurred `2px solid #0B5FAE` outline with an explicit `2px` offset.
- **Typography Scale**: High-priority text and candidate reading materials utilize `#1F2933` (primary). Metadata, timestamps, item directives, and sub-labels utilize `#5A6473` (secondary). Disabled typography, inactive placeholders, and locked states rely on `#8A94A6`.
- **Dividers & Structural Borders**: Crisp architectural division is maintained via `#C9CFD9` (primary interface border) and `#D8DCE3` (structural header/chrome dividers).
- **Status & Alerts**:
  - Critical/Error: `#D93A3A` foreground / `#B02525` dark accent, accompanied by `#FDECEC` light background fill.
  - Active/Success: `#2E7D4F` for verified completion indicators and confirmation states.
  - Warning/Notice: `#E0A912` warning state accompanied by `#FFF6E5` light notice fill.
  - Track & Inactive Fill: Unfilled progress bars and disabled control buttons use `#E4E7EB` and `#D8DCE3`.

## Typography

The design system standardizes on pure utilitarian sans-serif typography (system fallbacks: `Arial`, `Helvetica`, sans-serif). Type scale rules prioritize reading speed and eliminate visual strain:

- **Passage & Prompt Text**: Prompt prompts and stimulus texts are set at `16px` with a fixed line height ratio of `1.6` (`25.6px`) to ensure comfortable scanning during prolonged reading tasks.
- **Item Directions & Task Prompts**: Instructions directly informing user mechanics (e.g., "Read the text below and speak your answer into the microphone.") are set at `16px` bold (`#1F2933`).
- **Data & Timers**: All session counters, question indices ("Item 9 of 20"), and countdown clocks use `font-variant-numeric: tabular-nums` to eliminate jitter as digits cycle.
- **Metadata**: Supplemental notices, helper instructions, and disabled item badges are maintained at `13px` (`#5A6473`).

## Layout & Spacing

The test delivery canvas relies on an immutable fixed-frame model optimized for standard desktop test-center displays (minimum viewport 1024x768px):

- **Header / Top Bar**: Anchored to the top of the viewport. Height is fixed at exactly `56px`, framed by a bottom border of `1px solid #D8DCE3`.
- **Footer / Bottom Navigation Bar**: Anchored to the bottom of the viewport. Height is fixed at exactly `56px`, bordered by a top divider of `1px solid #D8DCE3`.
- **Content Area**: Positioned centrally between the top and bottom chrome. The core assessment content max-width is strictly capped at `960px` to prevent excessive line lengths in reading passages and to align question inputs with immediate field of view.
- **Vertical Hierarchy**: Spacing between instructions, content stimuli, recording widgets, and response inputs follows a rigid 8px grid (`8px`, `16px`, `24px`, `32px`).

## Elevation & Depth

This system avoids decorative dimensional depth. Elevation is communicated entirely through 2D planar layering and 1px borders:

- **Borders & Dividers**: Visual separation relies on `1px solid #C9CFD9` or `#D8DCE3`. Surfaces remain flat.
- **Shadow Treatment**: UI components, inputs, and cards feature no elevation (`box-shadow: none`). The sole permissible exception is critical floating dialogs (e.g., "Time Expired" alert or "Submit Exam" modal verification), which use a restrained utility shadow: `0 1px 2px rgba(0, 0, 0, 0.08)`.
- **Panels**: Distinction between foreground active zones and background structural containers is conveyed via surface color stepping (`#FFFFFF` on `#F4F5F7`).

## Shapes

The geometric form language is strictly squared and restrained:

- **Border Radius**: A strict maximum radius of `3px` is enforced on buttons, cards, text inputs, status containers, audio widgets, and modal boxes.
- **Progress Bars & Trackers**: The recording status indicator bar and exam timeline track use sharp, square ends (`0px` radius).
- **Prohibitions**: Rounded pills, circle button tags, circular avatars, and soft rounded modals are prohibited.

## Components

### Persistent Exam Chrome
- **Top App Bar**: Viewport fixed, `56px` height, background `#FFFFFF`, bottom border `1px solid #D8DCE3`. Contains institutional wordmark/logo on the far left, exam subject title (`14px` bold `#1F2933`), candidate identifier, audio check utility icon, question indicator ("Item 9 of 20" in `13px` `#5A6473`), and clock countdown display ("Time remaining: 00:24:17" with clock glyph in tabular numbers).
- **Bottom Navigation Bar**: Viewport fixed, `56px` height, background `#FFFFFF`, top border `1px solid #D8DCE3`. Displays "Save & Exit" button aligned flush left; "Previous" and "Next" action buttons grouped flush right.

### Buttons
- Height is fixed at `36px` with horizontal padding of `16px` and a uniform border radius of `3px`. Font size is `14px` bold.
- **Primary Action (e.g., Next)**: Background `#0B5FAE`, text `#FFFFFF`, border none. Hover state `#094C8C`.
- **Secondary Action (e.g., Previous, Audio Playback)**: Background `#FFFFFF`, text `#0B5FAE`, border `1px solid #0B5FAE`. Hover state `#F4F5F7`.
- **Disabled State**: Background `#E4E7EB`, text `#8A94A6`, border none, cursor `not-allowed`.

### Audio / Recording Status Box
- Fixed width `420px`, centered horizontally within the task pane.
- Background `#F4F5F7`, border `1px solid #C9CFD9`, border radius `3px`, padding `16px`.
- Layout: Contains widget status title (`14px` bold `#1F2933`), active state descriptor line (`13px` `#5A6473`, e.g., "Recording in 3 seconds..."), and an embedded recording progress bar.
- Progress bar uses a height of `6px`, flat track background of `#D8DCE3`, square terminals, and dynamic `#0B5FAE` active playback/capture fill.

### Text Inputs & Passage Textareas
- Background `#FFFFFF`, border `1px solid #C9CFD9`, border radius `3px`, padding `10px 12px`.
- Focus state: Border color transitions to `#0B5FAE` accompanied by an outline of `2px solid #0B5FAE`.
- Word counter display: Positioned bottom right beneath textarea, styled in `13px` `#5A6473` (e.g., "Word count: 184").

### Multiple Choice & Checkbox Controls
- Checkboxes: `18px x 18px` square, `2px` radius, `1px solid #C9CFD9` resting border. Active state `#0B5FAE` with a white checkmark.
- Radio buttons: `18px x 18px` standard circle, `1px solid #C9CFD9` border. Selected state exhibits an inner `#0B5FAE` solid disc.
- Option row container: Full-width stacked list item, background `#FFFFFF`, border `1px solid #C9CFD9`, `3px` radius, hover background `#F4F5F7`.