# Apple Silicon development baseline

## Checkout and tools

Prepared on an M3 Pro, macOS 15.8.1, using Apple clang 17 from Command Line
Tools and native arm64 Homebrew Qt 5.15.19. Branch: `setup/apple-silicon`.
Baseline commit: `1e08de2322f5e8849e1ba39e1d3993187a7cc75c` (upstream
`v1.5.2`). README's v1.4.1 label is stale. The original working tree was clean.
Upstream tags were fetched to populate the build's version string; source HEAD
was not advanced.

The supported build is `OpenSoundMeter.pro` with qmake and make (or Qt Creator
using a Qt 5.15 macOS kit), C++17. There is no CMake project or GitHub Actions
build workflow. The legacy `.travis.yml` uses qmake/make on Linux with Qt 5.14.1;
use the README's Qt 5.15 requirement rather than that old CI dependency version.
`CONTRIBUTING` requests discussion before upstream contributions; this setup
does not submit anything upstream.

Qt modules: Core, GUI/Widgets, QML, Quick, Quick Controls 2, Network, and OpenGL.
The UI also imports Qt Quick Controls 1 and Qt Quick Dialogs 1, so Qt 6 is not a
drop-in replacement. macOS audio uses system CoreAudio and AudioToolbox; no
PortAudio, JACK, ASIO SDK, or external FFT library is required for this build.
PVS-Studio is optional static analysis tooling.

## Build and launch

Install Command Line Tools if absent (`xcode-select --install`), then install
Qt 5 using native Homebrew. Qt 5 is deprecated in Homebrew; its reported disable
date at setup was 2027-05-19. This baseline deliberately retains the project's
Qt generation. Homebrew supplies Qt's transitive libraries.

```sh
HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 brew install qt@5
```

Use a separate build directory to keep generated files out of the repository:

```sh
cd /Users/c4milo/Desktop/osm
# Only needed in clones lacking release tags; does not change checked-out source:
git fetch upstream tag v1.5.2
mkdir -p ../osm-build-apple-silicon
cd ../osm-build-apple-silicon
GRAPH_BACKEND=OPENGL /opt/homebrew/opt/qt@5/bin/qmake ../osm/OpenSoundMeter.pro \
  CONFIG+=release CONFIG-=debug QMAKE_APPLE_DEVICE_ARCHS=arm64
make -j6 > build.log 2>&1
open /Users/c4milo/Desktop/osm-build-apple-silicon/OpenSoundMeter.app
```

App: `/Users/c4milo/Desktop/osm-build-apple-silicon/OpenSoundMeter.app`.
For terminal startup diagnostics, quit the running app first, then:

```sh
cd /Users/c4milo/Desktop/osm-build-apple-silicon
./OpenSoundMeter.app/Contents/MacOS/OpenSoundMeter > startup.log 2>&1
```

This command remains attached until the app exits. Build diagnostics are in
`build.log`. For a genuinely fresh rebuild after toolchain or version metadata
changes, rerun qmake, run `make clean`, then run make again.

## Existing transfer function and delay behavior

Magnitude, Phase, Coherence, and Impulse charts already exist. Each Measurement
selects a device, measurement input (`M:`), and reference input (`R:`).

Delay finding already runs during active measurement: `Measurement::transform`
feeds a 65,536-sample delay finder and transforms it every 25 measurement ticks.
The nominal timer is 80 ms, giving approximately 2 seconds between estimates
when processing keeps up. `estimated()` adds the current compensation to the
residual estimate, while `estimatedDelta()` reports the residual.

Continuous estimation exists; continuous automatic compensation tracking was
not found. `MeasurementProperties.qml` applies the estimate only when the user
clicks the estimate button or invokes its `Ctrl+9` QML shortcut (Command+9 on
macOS). The delay field stores integer samples and displays milliseconds.
`Measurement::updateDelay` adjusts the input buffers when that value changes.
These findings come from source inspection, not an acoustic delay accuracy test.

## Manual audio checklist

1. Connect the interface and select a shared sample rate in Audio MIDI Setup.
   Feed the reference signal electrically into one input and the measurement
   mic into another input on the same interface. Use suitable input levels and
   phantom power only where appropriate; start with speaker output low.
2. Allow microphone access if macOS requests it. Select the Measurement source
   (or add one from the menu), choose the interface in its input device selector,
   set `M:` to the mic input and `R:` to the reference input. Confirm both meters
   respond without clipping. `Loop` is the internal generator feed, not the
   physical reference input for this dual-channel check.
3. Activate the measurement and feed broadband signal through the system.
   Use the chart type selectors to display Magnitude, Phase, Coherence, and
   optionally Impulse. Confirm traces update and coherence is usable over the
   frequency region being evaluated.
4. Wait for the estimated delay button to stabilize, then click it. Confirm the
   delay field adopts that value and the residual estimate approaches zero.
   Check the impulse alignment and phase response. Reapply after moving the mic
   or changing routing; compensation does not automatically follow movement.
5. Validate with a known loopback/delay, then an acoustic path. Run a sustained
   session at the intended sample rate and buffer settings; check dropouts,
   drift, reconnect behavior, repeatable phase/delay, and saved-session reload.
   Record interface model, driver, sample rate, and duration before calling the
   setup ready for a show.

## Limitations and verification

Verified on this Mac: qmake and release make completed successfully; `file`
identified a Mach-O arm64 executable; the app launched and visibly reported
v1.5.2. The Measurement properties exposed the device, M/R inputs, compensation
field, and updating estimated delay button. The chart menu exposed Magnitude,
Phase, and Coherence, and selecting Magnitude opened that chart. The generator
remained off. The default selected input was AirPods with `R: Loop`; this was
not a valid physical dual-channel measurement and no displayed values were
treated as measurement validation. No external interface routing was tested.

Startup output in the sibling build directory's `startup.log` contained three
`Qt Quick Layouts: Detected recursive rearrange. Aborting after two iterations.`
warnings. The process remained running and the UI responded; no fatal error or
QML load failure appeared in the observed startup. Existing compiler warnings
were retained. The first qmake pass also warned about a missing generated
metatypes JSON file; make generated it, and the subsequent clean build passed.

OpenGL is the project's default renderer and was selected for this baseline.
The optional Metal backend uses `GRAPH_BACKEND=METAL` and Apple's Metal compiler;
it was not built or validated. Full Xcode was absent; Command Line Tools suffice
for the OpenGL build. OpenGL is deprecated by Apple.

The development app links to the installed Homebrew Qt frameworks. It is not a
self-contained, notarized distribution. Keep Qt installed; redistribution needs
separate deployment, signing, and licensing review. Measurement calculations
and application source were not changed.

Installation note: the first Homebrew install ran automatic cleanup, including
removal of Homebrew's unused `mbedtls@3` package and old caches. Qt installation
added `qt@5` and `md4c`; use the cleanup suppression above for subsequent installs.

Hardware routing, calibration, delay accuracy, and long-session reliability
require the manual checklist above. App startup alone does not establish them.
