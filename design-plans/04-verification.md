# Presentation verification — 2026-10-19

- The Apple Silicon/OpenGL release build completed with Qt 5 `qmake` and `make -j6`. The executable is arm64 and the Desktop app shortcut points to the built bundle.
- Qt 5 `qmllint` returned success for every changed QML file. `git diff --check` returned success.
- The older app instance closed through its save confirmation. The rebuilt app opened natively; its RTA, three-chart layout, and all three Defaults tabs rendered in both themes. The RTA collapse and Heatmap switches worked. Defaults was closed with Cancel, and the original dark theme and Heatmap preference were restored.
- Native window widths of 1512, 1025, and 768 points were inspected. At 768 points wide, the app stopped resizing at 568 points high, so the requested 768 × 540 state could not be reached.
- Startup emitted three `Qt Quick Layouts: Detected recursive rearrange` warnings. The same warning appears in prior `startup.log`, `rta-startup.log`, and `integration-startup.log` files in the existing build directory. The temporary RTA `preferredHeight` binding loop found during implementation was removed; no binding-loop warning remained in the final runtime output.

The [screenshot manifest](screenshots/manifest.md) is the coverage record. Measurement capture, other chart/source types, session round trips, keyboard numeric editing, and several dialogs remain unverified. The build and screenshots do not establish those acceptance gates.
