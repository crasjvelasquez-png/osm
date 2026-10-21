# Delay Finder: find, review a held result, apply

Status: implementation plan only; no application changes made.
Written against: `0356b6a375ee00dc1db89d5109d5f416bda3513c` on 2026-10-21.
Working tree already contains an unrelated change to `qml/RTAWorkspace.qml`; preserve it.

## Evidence chain

- Surface: chart-workspace alignment toolbar, composed by `qml/Charts.qml:126–155`.
- Problem: the user reports that changing readings are distracting and too fast to use. `qml/DelayFinder.qml` replaces `estimatedSamples` on every `delayEstimateUpdated`, immediately updates distance, shows cursor-dependent wavelengths, and expires the result after three seconds.
- Local design evidence: `PRODUCT.md` calls for restrained instrument-like UI, stable numeric widths, explicit input states, and reuse of measurement models and shell tokens. `qml/StudioTheme.qml` and `qml/elements/StudioButton.qml` own the existing appearance.
- Runtime owner: `qml/DelayFinder.qml`. `Charts.qml` supplies the selected local Measurement and chart cursor frequency; it hides the pill in the RTA workspace.
- Estimate owner: `src/source/measurement.cpp`, `Measurement::transform()` and `Measurement::estimated()`. The 20 ms timer in `measurement.h` and every-25-transform estimate give a nominal 500 ms update interval. Actual timing depends on processing load. `estimated` is the absolute reference-delay target in samples; `estimatedDelta` is not the value to apply.
- Uncertainty: repeatability thresholds and acquisition time require native/known-delay validation. Current source exposes no dedicated delay-confidence metric; consistent estimates alone do not prove a correct acoustic arrival or adequate excitation.

## Smaart inspiration

Use Smaart's deliberate Find → inspect completed result → Insert workflow, with a separate action to find again. Its basic presentation distinguishes measured delay, current delay setting, and their difference. Keep OSM's existing **Apply** wording and compact native pill.

Sources checked on 2026-10-21:

- [Rational Acoustics: Delay Finder vs. Delay Tracker](https://rationalacoustics-support.freshdesk.com/support/solutions/articles/150000184350-delay-finder-vs-delay-tracker): initiating Find, explicitly inserting the result, rerunning Find, and the separate continuous tracker workflow.
- [Smaart LE v9.1 User Guide, Delay Finder section / Figure 59](https://rationalacoustics.de/download/smaart_le_v9.1_user_guide.pdf): completed measured/current/delta readouts and user review before insertion.
- [Rational Acoustics: Advanced Delay Finder](https://rationalacoustics-support.freshdesk.com/support/solutions/articles/150000188314-advanced-delay-finder-a-guide): advanced IR plotting and frequency filtering are separate capabilities, outside this change.

The capture window, median, and repeatability threshold below are proposed OSM behavior, not claims about Smaart's algorithm. Do not describe this implementation as equivalent to Smaart's dedicated IR measurement.

## Design decision

Replace automatic live presentation with an explicitly started, bounded capture. Hold the accepted result until Find again, Apply, or a measurement-context invalidation. Keep secondary information in a closed-by-default details popover. Continuous acquisition in the measurement engine continues normally; only the pill's presentation and capture state change.

## Reuse

- Retain the `DelayFinder` component and existing toolbar placement and bindings.
- Use `StudioButton` and `applicationWindow.ui` font, spacing, control-height, radius, panel, text, secondary-text, separator, and focus tokens. Preserve supplied surface/text/outline colors.
- Use Qt Quick Controls 2 `Popup` for details, styled with those existing tokens; no new shared component or dependency is needed.
- Retain the existing 20 °C distance conversion and metres/feet control, with wording that distance is a time-equivalent and includes any system latency.
- Extend `tests/delayfinder/tst_delayfinder.qml` and its fake Measurement rather than introduce a second test harness.

## Changes

### 1. Model an explicit capture in `qml/DelayFinder.qml`

Use named states: `idle`, `capturing`, `held`, `applied`, `unstable`, `unavailable`. Keep an explicit held-result-valid flag and captured measurement identity/sample rate/current reference delay. Store all calculations in samples until formatting for display.

- Initial state: no automatic capture; **Find Delay** is enabled only with a selected live, error-free input and positive sample rate. Apply is disabled.
- Find Delay / Find again: clear the previous candidate and result validity, snapshot context, then collect only subsequent finite `estimated` values received through `delayEstimateUpdated`. Do not seed from the cached estimate or count `estimatedChanged`/level updates as independent estimates.
- Capture for 2,000 ms. Require at least three updates. Accept only if the full captured range is at most `max(1 sample, ceil(sampleRate × 0.0001))`, initially about 0.10 ms. Use the rounded median of all accepted samples as the held absolute target. Keep duration, minimum count, and threshold named and testable.
- With sufficient but inconsistent readings: enter `unstable`, show **Readings vary — find again**, and disable Apply. With insufficient readings: show **Not enough readings — find again**. Do not automatically retry or retain an older actionable result.
- During capture show **Finding…**, without intermediate numbers, flashing, a ticking countdown, or animated width. Disable Find while capturing; allow **Cancel** in its place. Cancel returns to idle and makes no delay change.
- On success: enter `held`; show the fixed value to two decimal places in ms. Later estimate signals must never replace it. No elapsed-time expiry of a healthy held result.

The repeatability gate is conservative: a single large outlier rejects the capture. It is not a signal-quality detector. Use the factual failure labels above rather than claiming the signal is definitely bad. Validate the initial 0.10 ms tolerance against a known delay before treating it as a final tuning value.

### 2. Preserve validity and Apply semantics

- Invalidate and cancel timers/buffers on measurement selection, active/error state, device, sample rate, data/reference channels, input filter, window function, or externally changed reference delay. Capture and held state must never survive a change to the signal path or estimate basis.
- Retain an estimate heartbeat independently of the held number. A 250 ms watchdog checks `inputAvailable` and time since the last estimate; invalidate after three seconds without an estimate or immediately when other live conditions fail. Read `inputAvailable` directly in the timer: its getter is time-based and its `levelChanged` notifier may stop when audio stops. Heartbeats do not change held digits or produce visible activity.
- Returning input enables Find Delay but does not resurrect the old result or start acquisition automatically. A valid zero or negative estimate remains a valid value.
- Recheck context and live/heartbeat validity inside Apply. Write exactly `measurement.delay = Math.round(heldSamples)` once; never add to the existing delay. Apply remains an explicit user action.
- Treat the component's own delay write as a distinct transaction so its synchronous `delayChanged` cannot cause an inconsistent state. After applying, enter `applied`, show the applied value with a quiet **Applied** label, disable Apply, and offer Find again. Keep that displayed value fixed; other context changes still invalidate it. Applying an unchanged value must complete too, even when no `delayChanged` is emitted.
- If the pill becomes hidden when switching to RTA, cancel an in-progress capture and close details. A held result may remain while the same context and heartbeat stay valid; returning to charts never starts a find automatically. Component destruction cancels all pending work.

### 3. Make the compact pill stable and details intentional

- Main row: **Delay Finder**, a stable result/status area, **Find Delay** (then **Find again**), **Apply**, and a quiet **Details** disclosure. Reserve consistent widths for result/status and changing action labels; use tabular numerals where supported. Do not let new digits move neighboring toolbar controls.
- Apply stays present but disabled until `held`. Details is disabled until a result exists. No inline distance or wavelengths in the collapsed pill.
- Details opens a small anchored nonmodal popover with the selected measurement name, **Measured**, **Current**, and **Change** in ms. Before Apply, Change is `(heldSamples − capturedCurrentDelaySamples) / capturedSampleRate × 1000`, with an explicit sign. Current means the reference delay captured for this result, not a second estimate. External delay changes invalidate the result rather than silently change this comparison.
- After Apply, details presents Current equal to the applied setting and Change equal to zero. Measured remains the held target. Use two decimal places, preserving negative values.
- Put distance, the metres/feet switch, and wavelength readout below those values. Label distance **Equivalent distance (20 °C)**. Wavelengths use the held delay and the chart cursor frequency, with the frequency visibly labelled **at … Hz**; these secondary values may follow cursor movement only while details is open. Hide the wavelength row for non-Hz/invalid cursor frequencies. No cursor-dependent value appears in the closed pill.
- Details opens by click/keyboard, closes with Escape/outside click or invalidation, and does not steal chart interaction while closed. Focus returns to its opener. Tooltips supplement controls; they do not contain the only explanation of applying reference delay.
- Bound the popover to the available window and retain wrapped Flow behavior on narrow widths. Long measurement names elide inside details with full text available on hover/focus. State changes must not change the number of toolbar rows at a fixed available width. Test actual status text lengths before selecting the reserved widths.

### 4. Extend behavior tests and verify native rendering

Replace tests that assume immediate live display and three-second held-result expiry. Keep existing object names where meaningful and add stable names for Find, Cancel, details, and measured/current/change fields.

Cover:

1. Explicit start; no pre-click samples; sufficient stable samples produce one held median; subsequent wildly different estimates cannot change it; Find again discards it; cancel does not apply anything.
2. Insufficient/variable/nonfinite readings, exact threshold boundaries, late signals after cancellation/context change, zero/negative targets, 44.1/48/96 kHz conversion, and an even-count median. Test with shortened configurable capture timings; retain a production-duration smoke check.
3. Absolute Apply with an existing nonzero delay, unchanged-target Apply, double-click/repeated Apply, context invalidation during capture/hold, and absence of new estimates. Verify no delayed timer can apply or restore a cancelled result.
4. Held result survives more than three seconds with valid heartbeats; missing input/heartbeat clears it; reconnect requires Find; fake source models the real `levelChanged` notifier. Verify selection, channels, device, rate, filter/window changes, manual delay, and RTA visibility behavior.
5. Details current/measured/signed-change values, applied zero change, distance units, Hz-only wavelengths, collapsed cursor independence, keyboard open/close, and narrow layout. Native inspection checks both themes and stable toolbar geometry across all states.

## Scope

- Inherit: chart-workspace Delay Finder only, including its selected-measurement and cursor bindings in `qml/Charts.qml` if visibility cancellation needs wiring.
- Verify: adjacent toolbar controls and chart area, RTA switching, reference-delay field synchronization, and keyboard focus.
- Exclude: estimator/DSP changes, faster background estimation, automatic delay insertion/tracking, Live mode, new shortcuts, saved result history, session/default persistence, external-device delay control, and advanced IR plots/bandpass filtering. The existing RTAWorkspace edit remains untouched.

## Validation

- Product: with a known reference delay, Find produces a repeatable held target; review it without rushing, then Apply and confirm the existing reference-delay control changes to that absolute sample target. Inspect TF phase/impulse behavior before and after. Record input setup and measured error; a fake-source test cannot establish acoustic accuracy.
- Interface: capture native screenshots at 768×540, 1024×768, and a larger desktop size in both themes, plus a 280 px component-width test. Exercise every state, long names, details near window edges, changing chart cursor, stopped/missing input, and RTA return. Compare toolbar geometry before/after readings and confirm no clipping or unexpected chart movement.
- System: reuse existing theme/buttons; all capture state stays local to DelayFinder. No writes to delay outside Apply, no session-format change, no background retries, and no changes to existing acquisition/DSP.
- Repository: run `QT_QUICK_BACKEND=software /opt/homebrew/opt/qt@5/bin/qmltestrunner -input tests/delayfinder -platform offscreen` and `git diff --check` → all pass.
- Build: use the existing sibling Apple Silicon Qt 5/OpenGL build documented in `APPLE_SILICON_SETUP.md`. In `/Users/c4milo/Desktop/osm-build-apple-silicon`, run `GRAPH_BACKEND=OPENGL /opt/homebrew/opt/qt@5/bin/qmake ../osm/OpenSoundMeter.pro CONFIG+=release CONFIG-=debug QMAKE_APPLE_DEVICE_ARCHS=arm64`, then `make -j6 > build.log 2>&1`. Verify the executable with `file OpenSoundMeter.app/Contents/MacOS/OpenSoundMeter` and inspect the rebuilt app. Report offscreen, native, and real-signal checks separately; a build does not prove the measurement is correct.

## Stop conditions

- If the two-second window rarely receives three independent estimates, measure actual cadence and revise the bounded duration; do not speed up DSP as part of this change.
- If the repeatability gate accepts incorrect or unexcited-signal results in known-delay tests, stop any reliability claim. Document the missing confidence information and propose estimator-quality work separately rather than inventing a confidence percentage or silently widening the scope.
- If the current estimate basis or validity cannot be preserved using the existing signals, resolve the missing contract before enabling Apply; do not apply an old cached estimate.
- Re-read current source before execution and preserve concurrent changes. Any need to alter DSP, shared control behavior, persistence, or the unrelated RTA work requires a revised plan.

## Design documentation

After acceptance and successful validation, document the Find/review/Apply workflow, local repeatability limitation, and separate tracking scope in the existing alignment user documentation under `docs/` if one governs this surface. If none exists, add a concise `docs/delay-finder.md`; do not change the general design language or overwrite prior plans.
