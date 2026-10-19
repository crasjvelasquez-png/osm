# Consistent compact measurement controls

Written against: 1e08de2322f5e8849e1ba39e1d3993187a7cc75c plus uncommitted work, 2026-10-19.
Status: plan only. Read MEMORY.md and design-plans/README.md before execution.

## Evidence chain

- Surface and owners: qml/RTAWorkspace.qml, qml/elements/TitledCombo.qml, src/common/appearance.cpp.
- Problem and runtime evidence: The user reports too much text and inconsistent appearance. RTAWorkspace displays persistent explanatory text and long averaging labels. Its controls are loaded by Charts.qml.
- Design evidence: explicit user request for easier standardized controls, adjustable RTA sizing and a left trace/session library.
- Scope: native measurement workspace; preserve existing setup for live feedback and PA alignment.
- Uncertainty: no fresh native visual audit was performed during planning. Confirm rendered geometry before implementing final layout values.

## Design decision

Keep essential live controls visible and move explanatory text and advanced settings into a secondary disclosure. Reuse existing palette and controls.

## Reuse

Use the existing owners listed above, applicationSettings, sourceList and current
appearance palette. Reuse local Qt controls rather than introducing a separate
visual system. Existing exemplars and exact behavioral reuse are identified below.

## Changes

1. Inspect the native workspace before choosing final spacing and sizing. Reuse the existing appearance palette, TitledCombo, Meter and Qt Controls 2 components; do not introduce a second theme.
2. Keep selected source, Start/Stop, input meter, short input status, averaging, resolution and Capture discoverable. Group input routing and advanced display settings behind clearly named controls. Preserve keyboard and tooltip names.
3. Use short status labels such as Running, Stopped, Waiting for audio and Input unavailable. Keep recovery instructions available on demand; never make stale audio look live. Derive displayed units from the plot rather than hardcoding dBFS when another scale is active.
4. Preserve all settings values and defaultsController integration. Changing labels or visual grouping must not change averaging semantics, selected input, smoothing or peak behavior.
5. Verify native appearance and interaction for each input state, long names, control wrapping and existing measurement properties.

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
