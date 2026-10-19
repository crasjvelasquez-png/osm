# Resizable RTA, heatmap and library panels

Written against: 1e08de2322f5e8849e1ba39e1d3993187a7cc75c plus uncommitted work, 2026-10-19.
Status: plan only. Read MEMORY.md and design-plans/README.md before execution.

## Evidence chain

- Surface and owners: qml/RTAWorkspace.qml, qml/Charts.qml, qml/main.qml.
- Problem and runtime evidence: RTAWorkspace uses ColumnLayout preferred heights of 0.65 and 0.28 of workspace height; it has no draggable RTA/heatmap divider. Charts.qml already demonstrates a vertical SplitView.
- Design evidence: explicit user request for easier standardized controls, adjustable RTA sizing and a left trace/session library.
- Scope: native measurement workspace; preserve existing setup for live feedback and PA alignment.
- Uncertainty: no fresh native visual audit was performed during planning. Confirm rendered geometry before implementing final layout values.

## Design decision

Provide direct panel resizing with persistent proportions, useful minimum sizes and a reset-layout action.

## Reuse

Use the existing owners listed above, applicationSettings, sourceList and current
appearance palette. Reuse local Qt controls rather than introducing a separate
visual system. Existing exemplars and exact behavioral reuse are identified below.

## Changes

1. Replace the RTA/heatmap height-ratio arrangement with a compatible vertical splitter. Inspect Charts.qml's Qt Quick Controls 1.4 SplitView exemplar; alias imports explicitly to avoid conflicting with Controls 2 widgets.
2. Preserve heatmap visibility and synchronized frequency range. Give the RTA the available graph area when heatmap is hidden; restore the previous split when shown again.
3. Add a horizontal splitter for the left library and chart region as part of library integration. Keep chart and library usable at the existing 768×540 window minimum; support library collapse.
4. Persist user-adjusted proportions through the existing applicationSettings owner, clamp them on smaller displays, and provide Reset layout without clearing measurement defaults or routing.
5. Verify dragging, window resize, restart, heatmap toggle and return to the incumbent chart layout. No control should become permanently unreachable after shrinking the window.

## Scope

- Inherit: selected measurement workspace and directly shared controls only.
- Verify: incumbent charts, defaults dialog, stored source properties and source selection.
- Exclude: DSP, hardware routing changes, generator output, Qt migration and deployment.

## Validation

- Product: complete the user's feedback-finding and PA-alignment setup without extra routing steps.
- Interface: native checks at 768×540, 1024×768 and larger; verify long names, state changes and persistence.
- System: preserve existing settings/storage owners; no duplicate model or theme.
- Repository: follow APPLE_SILICON_SETUP.md for the existing arm64 build; run the installed Qt 5 qmllint on changed QML and `git diff --check`. Record pre-existing diagnostics separately from regressions.

## Stop conditions

Pause edits to overlapping files if another task is actively changing them. Reconcile
with the owner before continuing; never overwrite concurrent defaults or renderer work.
If implementation requires a session format break, DSP modification or a Qt upgrade,
reassess that expanded scope with the user before proceeding.

## Design documentation

After implementation and validation, update MEMORY.md with the accepted behavior,
precise persistence semantics and actual verification results. Retain remaining gaps.
