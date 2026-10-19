# Project memory — Open Sound Meter

Updated: 2026-10-19.

## How to use this file

Read this file before planning future changes. Preserve confirmed user decisions;
do not treat proposed features or unanswered questions as approved requirements.
Update it with the user's answers and the evidence from completed validation.

## Confirmed intent

The user wants a review of possible upgrades and improvements, with clarifying
questions to establish the functionality they actually want. Record those decisions
here so later changes remain consistent. This request authorizes discovery and
documentation; it does not select a framework migration or a feature implementation.

## Current project evidence

- Native C++17 / Qt 5.15 application using qmake. Existing Apple Silicon setup is
  documented in `APPLE_SILICON_SETUP.md`; its version and dependency observations
  are dated setup evidence, not a fresh upstream release check.
- Local edits include a dedicated RTA workspace, optional heatmap, display and
  averaging controls, input freshness reporting, and macOS microphone permission
  handling. Preserve existing uncommitted work.
- `docs/RTA_PHASE1_HANDOFF.md` records the integration repair and observed native
  UI checks. Its final section supersedes earlier overlapping-test claims.
- Dedicated RTA capture/comparison phase 2 remains incomplete according to the
  handoff. Existing generic application capabilities should be inspected before
  adding duplicate capture/storage mechanisms.
- The Desktop launcher currently points to
  `/Users/c4milo/Desktop/osm-build-apple-silicon/OpenSoundMeter.app`.
  Preserve easy double-click access. This is a development build, not a verified
  standalone distribution.

## Confirmed requirements — user answers, 2026-10-19

1. Primary uses: live feedback finding and PA tuning/alignment.
2. Hardware: user calls the interface “Komplete Kontrol 6”; microphone is dbx
   RTA-M DriveRack Series Reference Microphone. A physical reference input will
   always come from the mixing board; board model changes with each show.
   Verify the interface's exact model/generation and channel names before making
   hardware-specific routing assumptions. Do not silently rename the device.
3. Main frustrations: inconsistent look and feel, too much text, inability to
   adjust size in the RTA workspace, and controls that need to be easier.
4. Current setup works for the user. Preserve startup, routing, defaults and
   existing measurement behavior while improving presentation and layout.
5. User wants saved traces and sessions accessible from the left side, inspired
   by Smaart's workflow. Reuse OSM's existing storage/session capabilities.

## Planned work

The user requested a plan, not implementation, in this turn. See
`design-plans/README.md` and its three implementation plans. Start with simpler
consistent controls, then resizable panels, then trace/session library integration.
Do not change DSP, automatically enable generator output, or assume hardware
calibration has been completed as part of these interface changes.

## Remaining clarification

- Exact interface model/generation and physical input assignments remain unknown.
- Interpret “adjust size” initially as draggable RTA/heatmap and sidebar sizing;
  ask whether the user also means axis zoom or interface/text scaling before
  expanding scope.
- Personal-use versus distribution scope was not answered. Packaging and framework
  migrations are deferred; neither is necessary for this plan.

## Validation boundaries

This discovery pass read source, setup and handoff notes and checked the Desktop
symlink. It did not rebuild, run new acoustic tests, or verify current upstream
versions. The handoff leaves external-interface accuracy, isolated permission and
reconnect coverage, the full session-reload matrix, and a 30-minute release gate
open. Never describe these as passed without new recorded evidence.
