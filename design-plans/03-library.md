# Left-side saved traces and sessions

Written against: 1e08de2322f5e8849e1ba39e1d3993187a7cc75c plus uncommitted work, 2026-10-19.
Status: plan only. Read MEMORY.md and design-plans/README.md before execution.

## Evidence chain

- Surface and owners: qml/main.qml, qml/SideBar.qml, qml/SourceLayout.qml, qml/source/Stored.qml, qml/source/StoredProperties.qml, qml/RTAWorkspace.qml, qml/menu/Top.qml, src/sourcelist.cpp.
- Problem and runtime evidence: main.qml places the current source sidebar on the right. SideBar.qml already calls source.store() and appends Stored sources. File menu already opens save/open dialogs. RTAWorkspace.followSource currently restricts plots to the selected source UUID.
- Design evidence: explicit user request for easier standardized controls, adjustable RTA sizing and a left trace/session library.
- Scope: native measurement workspace; preserve existing setup for live feedback and PA alignment.
- Uncertainty: no fresh native visual audit was performed during planning. Confirm rendered geometry before implementing final layout values.

## Design decision

Expose the existing source/storage system through a left-side library, with named capture and comparison controls plus session save/open. Functional requirements below come directly from the user, rather than being inferred visual defects.

## Reuse

Use the existing owners listed above, applicationSettings, sourceList and current
appearance palette. Reuse local Qt controls rather than introducing a separate
visual system. Existing exemplars and exact behavioral reuse are identified below.

## Changes

1. Reuse SideBar/SourceLayout and Stored entries on the left. Present live measurements and saved traces clearly, without creating duplicate sources or a parallel model. Preserve grouping and access to existing source properties.
2. Add Capture for the focused live measurement: take an immutable snapshot, allow a name, and add it to the library. Disable capture for missing/stale audio. Keep the existing capture-all shortcut behavior distinct and documented.
3. Expose trace name, color, visibility, rename and removal through existing stored-source properties. Update RTA selection handling to show visible captured overlays alongside the active live measurement; selecting a saved trace must not silently change the measurement input or stop live acquisition. Keep heatmap following its live source.
4. Add visible Save session/Open session actions using the existing file dialogs and SourceList serialization. Verify exact fields already persisted before extending anything. Preserve older files; respect current workspace/default behavior, including Charts.qml returning to the incumbent layout after load unless separately approved.
5. Verify named capture remains unchanged while audio continues, multiple overlays can be toggled, and save/close/reopen restores stored data, names, colors and routing. Exercise cancellation, write errors, absent devices and source deletion. Avoid destructive removal without a recoverable path or confirmation.

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
