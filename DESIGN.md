---
name: BOXZY Admin
description: Conventional desktop operations interface inherited from approved admin references.
colors:
  primary: "#165dff"
  primary-hover: "#0e4acb"
  canvas: "#f3f4f6"
  surface: "#ffffff"
  border: "#e5e7eb"
  input-border: "#d1d5db"
  body: "#1f2937"
  heading: "#030712"
  table-text: "#242933"
  secondary: "#667085"
  muted: "#6b7280"
  table-heading: "#374151"
  hover-surface: "#f9fafb"
  success-surface: "#f0fdf4"
  success-text: "#15803d"
  warning-surface: "#fffbeb"
  warning-text: "#92400e"
  danger: "#dc2626"
  danger-hover: "#b91c1c"
  error: "#b42318"
  loss-surface: "#fff1f0"
  loss-border: "#fecdca"
typography:
  headline:
    fontFamily: "Arial, PingFang SC, sans-serif"
    fontSize: "28px"
    fontWeight: 600
  title:
    fontFamily: "Arial, PingFang SC, sans-serif"
    fontSize: "18px"
    fontWeight: 600
    lineHeight: "28px"
  body:
    fontFamily: "Arial, PingFang SC, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: "20px"
  table:
    fontFamily: "Arial, PingFang SC, sans-serif"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: "17px"
  metric:
    fontFamily: "Arial, PingFang SC, sans-serif"
    fontSize: "26px"
    fontWeight: 700
    lineHeight: "34px"
  metadata:
    fontFamily: "Arial, PingFang SC, sans-serif"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: "16px"
rounded:
  thumbnail: "3px"
  control: "4px"
  toast: "6px"
  panel: "8px"
spacing:
  small: "8px"
  control: "12px"
  medium: "16px"
  panel: "20px"
  gutter: "24px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.surface}"
    rounded: "{rounded.control}"
    padding: "0 16px"
    height: "40px"
  button-primary-hover:
    backgroundColor: "{colors.primary-hover}"
  button-secondary:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.table-heading}"
    rounded: "{rounded.control}"
    padding: "0 16px"
    height: "40px"
  button-danger:
    backgroundColor: "{colors.danger}"
    textColor: "{colors.surface}"
    rounded: "{rounded.control}"
    padding: "0 16px"
    height: "40px"
  input:
    backgroundColor: "{colors.surface}"
    typography: "{typography.body}"
    rounded: "{rounded.control}"
    padding: "0 12px"
    height: "40px"
  navigation-active:
    backgroundColor: "{colors.canvas}"
    textColor: "{colors.primary}"
    rounded: "{rounded.control}"
    padding: "0 16px"
    height: "46px"
  success-tag:
    backgroundColor: "{colors.success-surface}"
    textColor: "{colors.success-text}"
    rounded: "{rounded.control}"
    padding: "4px 8px"
  panel:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.panel}"
    padding: "20px"
  table-header:
    backgroundColor: "{colors.canvas}"
    textColor: "{colors.table-heading}"
    padding: "7px 10px"
---

# Design System: BOXZY Admin

## Overview

**Creative North Star: "The Approved Admin Workspace"**

The existing BOXZY admin reference is the visual authority. This is an inherited, conventional operations interface: neutral surfaces, compact tables, restrained blue actions, and explicit state labels. The title describes the accepted system; it introduces no new visual identity.

`ui.html` uses Operate mode: English labels and persistent working controls. `product-guide.html` uses Read mode: English screenshots beside Chinese product rules. Both are local prototypes; no production backend is connected. Source evidence: `src/input.css`, `tailwind.config.cjs`, sampled components in `src/app.js`, the inline guide stylesheet, and `screens/05-pool.png`.

**Key Characteristics:**
- Neutral gray grouped table headers.
- Long product names retain their identity beside numeric data.
- Global Box operations remain separate from category filtering.
- Centered dialogs protect focused tasks without creating a drawer hierarchy.

## Colors

### Primary
Action Blue identifies primary submission, text links, selected tabs, and the active Box navigation item. Its deeper hover variant is used for filled buttons.

### Neutral
Canvas Gray underlies White surfaces and is also the two-level table-header fill. Soft Border separates rows and regions. Body, Table Text, and Table Heading provide the text hierarchy; Secondary and Muted identify supporting information. These are the actual coexisting implementation colors, not a newly consolidated palette.

### State colors
Success green, warning amber, and destructive red supplement explicit labels. Error text identifies invalid fields. State must never depend on color alone.

**The Neutral Header Rule.** Table grouping is expressed through gray fills, borders, and labels; blue denotes actionable or selected content.

## Typography

Arial with the existing Chinese sans-serif fallback supports both surfaces. The operation UI uses a compact body and table scale; page and section headings use semibold weight. Metrics are larger and bold. Tabular numerals align amounts, weights, percentages, and counts. There is no marketing display typography in this system.

The table name has two visible lines with SKU metadata beneath. Do not reduce the type scale to fit more rows. The guide has its own reading rhythm: body line height 1.75, 21px page heading, 23px section heading, and 15px explanation headings.

**The Identity Before Density Rule.** Preserve readable product identity and access to the full name before increasing the number of visible rows.

## Layout

Desktop is the primary surface at 1600px and 1280px. The operation shell has a fixed 60px header, 220px sidebar, 24px desktop gutters, and a fixed global footer of at least 64px. The main document reserves bottom space for that footer. Compact economics occupy one row on desktop.

The prize-pool table has a 1220px minimum width. Its product column is 320px and its action column is 42px. Product identity and row actions remain sticky during horizontal scrolling; both gray header rows are sticky during vertical scrolling. The table viewport scrolls independently and uses a 235px minimum height. Data row CSS sets a 64px target; content and cell padding may increase the rendered height. Do not record target row height as a guaranteed number of visible records.

Below 1180px, the sidebar becomes 64px, labels disappear, and simulation moves beneath the metrics. Below 760px, navigation is hidden, forms stack, and the table retains horizontal scrolling. This is a graceful narrow fallback, not a separately designed phone application.

The reading guide uses a 208px section index, a 76px top bar, and image/explanation columns in a 1.5:1 ratio with 28px gap. Below 1200px those columns stack; below 700px its index becomes an in-flow compact list. Images open in a larger dialog for inspection.

## Elevation & Depth

Resting panels are flat White surfaces on Canvas Gray. One-pixel separators carry structure. Elevation is reserved for transient layers: dialogs, menus, and toast feedback. Exact shadows, overlay opacity, and motion are recorded in the sidecar rather than primitive tokens.

**The Transient Depth Rule.** Permanent data surfaces stay flat; temporary interaction layers receive elevation.

## Shapes

Controls and table boundaries use small rounded corners. Panels and dialogs use the larger panel radius. Product thumbnails have a subtle border and the smallest corner radius. The pill silhouette is reserved for whole-Box switches. No gradients or ornamental effects are inherited from the approved interface.

## Components

### Buttons
Primary actions are filled blue; secondary actions are white with a neutral border; destructive confirmation uses red. Buttons use a consistent height and horizontal padding. Hover changes color, focus-visible supplies a two-pixel blue outline with three-pixel offset, and disabled buttons reduce opacity and prohibit pointer submission. Color transitions last 150ms; reduced-motion disables transitions and animation.

### Inputs / Fields
Inputs use White fill, Input Border, and a small radius. Focus changes the border and adds a blue outline. Disabled inputs have a light gray background and muted text. Field errors remain adjacent. Inline weights are a compact exception at 66px wide and 32px high.

### Navigation
The active sidebar item has a neutral background and blue icon/text. Page and rarity tabs use an underline rather than filled cards. Whole-Box import, export, and add actions sit above rarity tabs. Sidebar icons are inline stroked SVG, not glyph characters.

### Chips
Small rounded tags use color with explicit text for Live, draft availability, and similar state. List switches omit redundant visible Live/Offline text, while retaining accessible state semantics.

### Cards / Containers
Flat white panels provide a single layer of grouping. General panels use 20px padding; the compact pool panel uses 16px 20px 10px. Avoid adding inner cards around each field or metric.

### Data table
The table has Product, Pricing, Inventory & history, and Probability & cost groups. Names and SKU IDs share the identity column. Hover/focus on a product name exposes the full value. Numeric data align right; editable weights remain left-aligned within their inputs. Row actions use a separately positioned menu so table scrolling does not clip it.

### Dialogs
Native centered dialogs cover focused SKU editing, stock adjustment, import, and confirmations. Standard dialog width is at most 640px with a 32px viewport allowance. Header, scrollable body, and footer remain distinct. Creating a Box uses a full page.

## Do's and Don'ts

### Do:
- **Do** preserve the approved conventional admin components and gray grouped headers.
- **Do** retain all required numeric fields and support scrolling rather than illegibly shrinking them.
- **Do** give long names two lines, a separate SKU line, and access to the full value.
- **Do** keep global Box actions above category filters and global submission in the footer.
- **Do** provide visible keyboard focus and labels for states and icon-only controls.

### Don't:
- **Don't** turn table headers blue or introduce a new visual brand.
- **Don't** use a side drawer for the confirmed centered-dialog tasks.
- **Don't** introduce a creation modal where a full-page Box form is required.
- **Don't** treat a local prototype or a captured UI state as evidence of a production backend.

Not canonized or repaired: narrow viewports intentionally require table scrolling; the hidden mobile sidebar is a fallback, not a complete mobile navigation contract. The screenshot set may precede the last compact CSS refinement; the shipped stylesheet is the token source.

## 2026-10-08 approved refinement
The prize-pool table has no fixed height, viewport height cap, or internal vertical scrollbar. Current-page rows expand naturally and pagination follows the table in document flow. Vertical navigation uses whole-page scrolling; horizontal table scrolling and pinned identity/actions remain available on narrow desktop widths. Remove the header View live version shortcut; remove all Box version management UI. This rule supersedes earlier bounded table-height notes.

Negative expected gross profit uses #b42318 for its label and value plus the text Expected loss. The alert applies only to a calculable value strictly below zero; zero/positive use normal styling, unavailable is an em dash. Remove the Before shipping and fees caption from this metric; retain the cost definition in the product guide.

Stock adjustment uses explicit Add stock / Remove stock radio choices, a blank positive-integer quantity, Current stock → Stock after change preview and an equation. The primary confirmation includes the operation and quantity; Remove uses destructive styling. A zero-stock warning appears only when the valid result is zero. No signed number input or preset quantity.

## Profit and operation review
Expected cost / draw is a text-link entry to Cost breakdown. The centered dialog summarizes six category contributions and three top SKU contributions; it does not create another permanent dashboard panel. Loss notices are embedded in the existing Publish and Set live confirmations. Negative profit is advisory, with no target margin or approval gate.

Simulation not run and Simulation complete use neutral text. Completion is not a profit pass. Simulation outdated retains an amber state. Inline weight input updates calculated cells without replacing the table or losing focus. Invalid input uses the existing error color, a light loss background and an explicit error explanation.

Stock eligibility changes show the expected profit impact in the existing dialog. Live effects use published configuration, not draft economics. The loss surface and border tokens above are the only added alert palette values. Mechanical review also reports inherited Tailwind fallback fonts and pre-existing tokens; those are not a request to replace the approved visual system.

2026-10-12: Dashboard order is filters, activity/pending summaries, realized profit equation, Box breakdown. No sales trends or prior-period changes. Box list shows Min Value and Max Value next to Open price; Basic information includes the two required display-range fields. Preserve existing admin styling.

Latest refinement: Unrealized revenue strip follows Realized profit, with end-date label and two unresolved-state amounts/counts. Box list Value range occupies one column after rarity probabilities. Prize-pool toolbar keeps Add SKU only.


## 2026-10-12 · SKU 库存告警
Stock alert 默认 Off，无默认阈值。开启必填非负整数；剩余库存 ≤ 阈值触发，仅当前 Box/SKU。Apply 应用当前编辑、Save draft 保存草稿、Publish 生效；取消不保存。列表 Low stock 为当前配置预览，不是服务端通知。关闭并应用清空阈值。不影响概率、收益、模拟或上线状态。真实通知渠道、接收人、重复频率尚未确定和接入。详见产品说明「SKU 库存告警」。
