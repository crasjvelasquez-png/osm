# Easier live measurement workflow

Status: planned; no application changes made by this planning task.
Written 2026-10-19 against commit 1e08de2322f5e8849e1ba39e1d3993187a7cc75c
plus the current uncommitted working tree. Re-read current files before execution:
new defaults-controller work appeared during discovery and must be preserved.

## User requirements

Primary tasks are live feedback finding and PA tuning/alignment. The user reports
an interface called “Komplete Kontrol 6,” a dbx RTA-M microphone, and a physical
reference from the show board. Board models vary. Existing setup works. The main
requests are consistent appearance, less text, easier controls, adjustable RTA
size, and a Smaart-inspired left-side library for traces and sessions.

## Design language

- Audited surface: native measurement workspace, RTA, heatmap and source sidebar.
- Design sources: user requirements, existing QML controls and appearance palette.
- Documented decisions: preserve setup and DSP; simplify presentation; left-side library.
- Governing owners: qml/main.qml, Charts.qml, RTAWorkspace.qml, SideBar.qml,
  SourceLayout.qml, elements/TitledCombo.qml, src/common/appearance.cpp.
- Explicit exceptions: None documented.

## Evidence and proposed sequence

| # | Problem | Evidence | Proposed change | Scope | Confidence |
| --- | --- | --- | --- | --- | --- |
| 1 | Too much text and inconsistent feel | User report; RTAWorkspace composes persistent status/help text and fixed-width control groups | Compact primary controls with secondary settings disclosure | RTA controls and shared styles used there | High on need; visual design requires native inspection |
| 2 | RTA panel size cannot be adjusted directly | User report; RTAWorkspace uses preferred height ratios in ColumnLayout while Charts uses SplitView | Draggable, persistent panel divider | RTA and heatmap | High |
| 3 | Library is not on the requested left side | User request; main.qml places SideBar after Charts in a two-column grid | Integrate existing source library on the left with clear capture/session actions | Workspace shell and library | High |

## Improve first

Simplify the controls first. This addresses the user's main frustration and defines
which controls must remain usable when resizable panels and the library are added.

## Implementation order

1. [Consistent compact controls](01-controls.md).
2. [Resizable measurement panels](02-layout.md).
3. [Left-side trace and session library](03-library.md).
4. Verify the combined workflow on the native app and actual show hardware.

## Completion gate

Build the existing arm64 Qt 5/OpenGL target; check changed QML and git diff.
Exercise rendered layout at 768×540, 1024×768 and a larger desktop size; verify
long source/device names, collapsed controls, stopped/missing-input states,
plot resizing, capture overlays and session round trips. Confirm defaults still
apply and changes persist as intended. Perform permission/reconnect tests in an
isolated run; never reset permissions or alter system audio while a show is active.
For readiness claims, record a 30-minute RTA/heatmap run with actual hardware,
sample rate, errors and reconnect results. A build alone does not prove accuracy.

## Boundaries

No Qt migration, renderer replacement, DSP change, automatic delay tracking,
SPL-calibration claim, or distribution work. No exact Smaart visual clone is required.
Do not add a second storage system. Keep current application data readable.

## Open details

Confirm exact interface model and channel assignments before hardware testing.
Panel resizing is the working interpretation of “adjust size”; axis zoom and
text/UI scaling remain separate choices. No clarification blocks this plan.
