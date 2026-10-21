# Native Mac studio refinement

Implemented in the existing working tree using Qt 5/QML. The right sidebar stays 240px wide; bottom-dock sizing, split persistence, measurement and generator models, and Defaults save/draft code are unchanged.

## Changes

- Shared `StudioTheme`, flat `StudioButton`, and `StudioTextField` components: system font, 13px controls, 12px secondary text, 15px section headings, 36px standard controls, 6px corners, muted indigo primary actions, and visible focus.
- 56px level header with three aligned readings, retaining its accessible description, tooltip, state handling, and warning colors.
- Compact wrapping RTA inputs, with smoothing in the peak-hold flow. Existing control scroll area, conditional averaging fields, plot splits, and heatmap mapping remain intact.
- Consistent source-row activation/name alignment, reserved action space, long-name elision, and subdued selection behind row content. Existing source colors and meters are retained.
- Segmented Defaults tabs, ruled section headings, shared controls in measurement/generator properties, Audio File Player, Delay Finder, and workspace actions.

## Verified

- Apple Silicon release rebuild of the existing sibling app bundle; executable is Mach-O arm64 and Info.plist passes `plutil -lint`.
- Changed QML passes Qt 5 `qmllint`; `git diff --check` passes.
- Offscreen QtTest: 10 StudioControls checks pass, including keyboard focus, dropdown selection, numeric keyboard editing, text editing, standard control bounds, and both theme palettes. Six Delay Finder checks pass, including absolute-delay application, units, unavailable/expired states, and narrow wrapping.
- An isolated test executable linked the app's actual QML resources and existing application objects, replacing only storage paths with `/tmp/osm-studio-isolated` and using the software/offscreen backend. It loaded the application and checked header/sidebar geometry at 768×540, 1024×768, and 1440×900 in both themes. Defaults loaded with three segments, a reachable-height footer, and usable content area at 760×640 and 620×480 in both themes.
- The real DefaultsController saved and discarded drafts using isolated settings. A second test process reloaded the saved name successfully. User settings and saved sessions were not used by these tests.

Run the retained component tests with:

```sh
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software QT_QUICK_CONTROLS_STYLE=Material /opt/homebrew/opt/qt@5/bin/qmltestrunner -input tests/studio
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software QT_QUICK_CONTROLS_STYLE=Material /opt/homebrew/opt/qt@5/bin/qmltestrunner -input tests/delayfinder
```

## Acceptance still pending

Computer Use returned “not approved to use OpenSoundMeter.” Native screenshots, native font/contrast inspection, complete viewport clipping checks, live/stopped input transitions, real plot rendering/resizing, heatmap gestures, source actions, all Defaults tabs/conditional fields/unsaved-close interactions, and all auxiliary windows have therefore **not** been verified in the native app.

The isolated software-backend test cannot validate OpenGL rendering or audio. It reports unavailable CoreAudio devices and unsupported platform GL/raise operations. It also reports existing layout-rearrange warnings, a Keys attachment warning in ModalDialog, and errors in the unfinished capture-panel bindings in Charts.qml (`hasStored`, source name/active/color bindings). Those bindings were present in the working tree and are outside this visual refinement. This is not a clean native-runtime/QML-error acceptance result.

No external interface, acoustic accuracy, calibration, or long-session audio validation is claimed.
