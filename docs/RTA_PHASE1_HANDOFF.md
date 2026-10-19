# RTA phase 1 handoff — 2026-10-19

## Ownership and current status

The user asked this task to stop editing and let the other task continue after concurrent heatmap and renderer changes appeared. Preserve all working-tree changes. No commit was made. This task did not implement capture/comparison phase 2 or deliberately start phase 3. The concurrently added heatmap and renderer changes need their own review and validation.

The native arm64/Qt 5.15/OpenGL build passed during this work. QML lint and `git diff --check` passed before the last concurrent changes. Do not interpret that as validation of the final integrated working tree.

## Online reference check

The installed Smaart Suite 9.5.2 universal app includes arm64 but could not run because its demo license expired. The user explicitly authorized online references instead.

Inspected the official desktop Smaart LE 9.1 guide, including rendered pages 34, 46, and 83:
https://rationalacoustics.de/download/smaart_le_v9.1_user_guide.pdf

Relevant interaction evidence:
- Page 83: spectrum engine setup puts name, device, and input channel together.
- Page 34: live engines carry matching color, visibility and run controls, with an input meter.
- Page 46: Capture targets the focused engine, prompts for a name and adds a saved trace to the session library.

These are desktop v9.1 references, not a claim of rendered Mac v9.6 inspection. The guide is reference material, not an algorithm specification. Further current desktop shortcuts:
https://support.rationalacoustics.com/support/solutions/articles/150000188147-smaart-v9-hotkey-guide

## Changes owned by this task

- `qml/Charts.qml`: opt-in RTA action, separate workspace loader, local workspace choice, return to the incumbent layout. Loading a session returns to the incumbent layout, without changing session format.
- `qml/RTAWorkspace.qml`: selected measurement controls, device/channel, meter, Start/Stop, existing properties panel, display modes, octave resolution, readable LPF/FIFO labels and parameters, peak display, dBFS default, source following and local selected-source setting. Uses existing analysis engine and palette. A bounded scrolling controls region preserves graph space in a small window. The file subsequently received concurrent heatmap changes.
- `qml/Chart.qml`: expose the existing plot and allow the dedicated workspace to lock its chart type.
- `qml.qrc`: include the workspace.
- `qml/elements/TitledCombo.qml`: replace undefined `none` with `false` in tooltip visibility. New controls exposed this pre-existing QML error.
- `src/source/measurement.{h,cpp}`: read-only inputAvailable property backed by the timestamp of an actual received audio buffer, reset on activation and device change. Existing readyRead is emitted by the periodic transform even without new samples, so it cannot establish live input. No FFT, averaging or level formulas were changed by this task.
- `src/audio/plugins/{coreaudio.h,coreaudio.cpp,microphonepermission.mm}` and `OpenSoundMeter.pro`: preflight macOS microphone authorization asynchronously before opening a CoreAudio input, linking the existing Apple AVFoundation framework. Unset/denied authorization returns a stopped/error state instead of entering the blocking input-open path. After granting permission, retry Start. This path needs a clean isolated denial/allow test because concurrent work overlapped this test.

Apple authorization API reference:
https://developer.apple.com/documentation/avfoundation/avcapturedevice/authorizationstatus(for:)

## Observed UI checks

Using the native Mac app, before concurrent changes:
- Start/Stop changed the intended measurement checkbox and the explicit running/stopped label.
- Switching to Bars changed FFT-bin display to 1/12 octave as needed.
- Octave selection, peak visibility and FIFO averaging updated through the workspace controls.
- Returning to the incumbent layout retained its Magnitude chart.
- Reopening RTA retained Bars, octave selection, FIFO parameters and peak state after fixing the workspace settings group type.
- Long AirPods device name displayed; a full narrow/wide resize matrix remains pending.
- When the AirPods input disappeared, the workspace showed Input unavailable and disabled Start for the missing device. Reconnect recovery was not fully exercised.
- New QML issues discovered and fixed: Flow implicitHeight is read-only; ScrollView preferredHeight binding loop; undefined tooltip `none`. Only the incumbent recursive-layout warnings remained in the last diagnostics capture before subsequent concurrent changes.

## Acoustic checks

Hardware: MacBook Pro Mac15,6, Apple M3 Pro, 36 GB; macOS 15.8.1. Built-in speakers and built-in mono microphone. The user authorized this acoustic path. Low-level generated WAV tones and deterministic white noise were played through the speakers. A temporary arm64 probe linked the existing OSM analysis objects and read Measurement spectra with FFT14 and FIFO depth 4. Reference input was the internal Loop with no generator/reference signal, so there was no physical reference channel.

Actual analysis sample rates were read from Measurement, rather than inferred from the WAV files or the rate-change request. CoreAudio applies rate changes asynchronously.

| Actual sample rate | 1 kHz measured peak | 4 kHz measured peak | Half-level 1 kHz drop |
| --- | --- | --- | --- |
| 48,000 Hz | 999.02 Hz | 3999.02 Hz | 5.63 dB |
| 44,100 Hz | 1001.29 Hz | 3999.79 Hz | 5.49 dB |

Frequency placements are within one FFT bin. Half-level playback predicts 6.02 dB; the acoustic results are approximate because of room noise and the built-in speaker/mic path. The first quieter 44.1 kHz capture had an ambient low-frequency global maximum, so the repeated level test evaluated the 1 kHz bin specifically. White noise produced continuous updates at both rates; no calibrated frequency-response claim is made.

Raw numeric results are in `rta-validation/acoustic-results.json` and `rta-validation/level-results.json`. The level repeat used the new inputAvailable timestamp property and reported true at both rates. The first acoustic run predates that property. This is not a deterministic baseline-versus-modified DSP comparison.

## Permission test and restored system state

`tccutil reset Microphone com.opensoundmeter.OpenSoundMeter` was used for the requested denial test. Two app launches then hung before showing a window; a process sample showed main waiting for Measurement::updateAudio's std::async future, with its worker blocked in AudioQueueStart/CoreAudio input setup. The saved session had already been closed normally. Those two newly launched hung processes were terminated before the permission preflight fix.

After the fix, the app opened and showed the explicit microphone/device-access error state. However, a clean user-denied prompt was not observed, and concurrent task activity overlapped this test. Do not mark the full denial/recovery gate passed.

At handoff, macOS System Settings > Privacy & Security > Microphone visibly showed OpenSoundMeter On. Built-in mic/speaker rates were restored to 48 kHz. The original default AirPods output was disconnected and could not be restored; the current output was retained. No volume preference was changed. Temporary signal players have exited.

## Remaining gates for the owning task

1. Rebuild the integrated working tree for arm64 and inspect fresh QML diagnostics; recheck device/source routing, source removal, wrapping/resize, input freshness and workspace persistence.
2. Complete isolated microphone denial/allow, unavailable input and disconnect/reconnect checks. Verify a stopped/error state never claims live audio.
3. Perform deterministic baseline DSP comparison if required; built-in acoustic checks are limited evidence. Actual external-interface accuracy is unverified.
4. Finish and validate phase 1 before capture/comparison phase 2, then validate phase 2 before optional RTA/spectrogram phase 3. Do not silently treat the concurrent heatmap as phase 3 acceptance.
5. Run the final 30-minute RTA-plus-spectrogram session with recorded hardware, errors and results. It was not run by this task. Signing, notarization and distribution remain deferred.

## Integration repair and fresh validation — 2026-10-19

The user subsequently authorized finishing the integration repair in this task. The other task was idle during the repair. No renderer changes from the other task were removed.

Confirmed collision: the other task searched for the original one-line RTA title to insert its header buttons, but this task had already changed that title to include the measurement name. Its replacement silently missed while `showControls: false` was still added, leaving all controls hidden and no toggle. Both tasks also built and launched the same app during overlapping tests; the other launch ended with SIGTERM (143). The previous independent visual-test claims are therefore superseded.

Repairs:
- Added explicit Input & display / Hide controls and Heatmap controls around the current title; controls are available initially.
- Removed the unconditional scale reset on workspace creation. RTAPlot still defaults new charts to dBFS, while existing scale settings remain intact.
- Persisted the smoothing choice rather than forcing it on whenever the workspace opens.
- Initialize spectrogram defaults once rather than overwriting later history range/banding edits on every toggle.

Fresh combined validation used a single controlled native app restart after a successful arm64 build. Build diagnostics: `../osm-build-apple-silicon/integration-build.log`; runtime diagnostics: `../osm-build-apple-silicon/integration-startup.log`.

Observed in the rendered app:
- Built-in microphone started successfully, with Running state, updating input meter, RTA bars and heatmap.
- Hide controls / Input & display worked in both directions. Lower display controls were reachable using the scrollbar.
- Heatmap disabled and re-enabled while analysis continued.
- Smoothing was switched off, the incumbent Magnitude workspace was opened, then RTA reopened; smoothing remained off, heatmap remained off, and Bars plus 1/12-octave settings were retained.
- Smoothing and heatmap were restored to enabled after the test. The app was left running with the built-in microphone and both graphs visible.

QML lint and `git diff --check` pass. Runtime log has the incumbent recursive-layout warnings and a missing-device diagnostic for the disconnected AirPods; no new QML load/binding/reference errors were logged in this run. No acoustic probe, tone player, or build remains active.

This closes the integration collision repair. It does not complete capture/comparison phase 2, the original full session-reload matrix, isolated permission-denial/reconnect coverage, external-interface accuracy, or the 30-minute release gate.
