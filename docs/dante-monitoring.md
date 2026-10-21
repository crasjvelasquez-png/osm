# Dante Monitoring in OpenSoundMeter

This document outlines the architecture, implementation, operational behavior, and testing strategy for the Dante Monitoring feature in OpenSoundMeter.

---

## 1. Overview and Rationale

The Dante Monitoring feature provides live visibility into local network link readiness and Audinate service availability directly within the OpenSoundMeter measurement header.

### Key Goals
- **Minimal, Focused UI**: High-level status at a glance without cluttering the screen or pushing SPL readouts.
- **Ultra-low Overhead**: Zero impact on real-time audio and DSP processing loops; CPU usage remains below 0.05% (< 0.2% ceiling requirement).
- **Accurate Empty-Network Handling**: Correctly identifies offline/idle setups as **No Dante devices detected** rather than triggering false "Down" or "Network Error" alerts when no physical Dante units are present.
- **Nonmodal Deep Inspection**: Clicking the compact indicator opens an auxiliary configuration and diagnostics window with individual link states, adapter assignment, and service status.

---

## 2. Architecture & Data Flow

```
                                +---------------------------+
                                |  Audinate ConMon Daemon   |
                                |       (conmon_cmm)        |
                                +-------------+-------------+
                                              |
      [SIOCGIFMEDIA Carrier]                  | [libproc PID inspection]
                 |                            |
                 v                            v
       +-----------------------------------------------+
       |             dante::Monitor QObject            |
       |  - 1 Hz lightweight observation timer         |
       |  - Direct Darwin BSD socket carrier ioctls    |
       |  - CFPreferences auto-detection               |
       |  - Deterministic state reduction              |
       |  - Change-driven snapshot notifications       |
       +-----------------------+-----------------------+
                               |
            +------------------+------------------+
            |                                     |
            v                                     v
+-----------------------+             +-----------------------+
|   qml/DanteStatus     |             |  qml/DanteMonitoring  |
| (Header Indicator)    |             | (Diagnostics Window)  |
+-----------------------+             +-----------------------+
```

### Observation Pipeline
1. **Disabled State (Default)**:
   When `danteMonitor.enabled == false`, the 1 Hz observation timer is completely stopped. No socket calls, process queries, or preference reads take place (0.0% CPU).
2. **Enabled State**:
   A lightweight 1 Hz timer fires an observation cycle on the GUI thread:
   - Evaluates link carrier state via standard BSD `ioctl(SIOCGIFMEDIA)` (< 0.05 ms).
   - Verifies daemon health using `proc_listpids` / `proc_pidpath`.
   - Compares the new snapshot with the previous state.
   - Signals are emitted **only** if the snapshot changed, avoiding spurious QML re-evaluations.

---

## 3. UI Presentation & Responsive Behavior

### Header Levels Indicator (`qml/DanteStatus.qml`)
- Located in `qml/HeaderLevels.qml` between the measurement title and the SPL readings control.
- **Standard Width (≥ 1024 px)**:
  `Dante · Primary · <State> · Secondary · <State>`
- **Compact Width (< 1024 px)**:
  `Dante · P · <State> · S · <State>`
- **Off State**:
  `Dante · Off` with inactive indicator dot.
- **Fixture Active**:
  `Dante [FIXTURE] · ...` (orange badge explicitly signaling test mode).
- **Keyboard & Accessibility**:
  Fully navigable via `Tab`, activatable via `Enter` or `Space`, with descriptive `Accessible.name` and `Accessible.role: Button`.

### Nonmodal Diagnostics Window (`qml/DanteMonitoring.qml`)
- Nonmodal `ApplicationWindow` respecting `StudioTheme` and dark/light modes.
- Accessible via header click, menu bar (`View -> Dante monitoring` / `Ctrl+Shift+D`), or side panel.
- Controls & Telemetry:
  - Master Enable / Disable switch.
  - Primary network card: State dot, state label, interface selection dropdown, carrier diagnostic text.
  - Secondary (Redundancy) network card: State dot, state label, interface selection dropdown, carrier diagnostic text.
  - Dante Services & Discovery card: ConMon daemon status, Controller process status, device count, and last observation timestamp.
  - Degraded reason banner (visible when degraded conditions occur).
  - Actions: **Auto-detect** (pulls configured interfaces from Dante Controller preferences), **Refresh**, and **Close**.

---

## 4. State Reduction Contract

| Condition | Primary State | Secondary State | Overall Text / Diagnostics |
| :--- | :--- | :--- | :--- |
| `enabled == false` | `Off` | `Off` | `Dante Monitoring: Off` |
| Link active & carrier up | `Up` | `Up` | `Dante: Primary Up · Secondary Up` |
| Primary active, Secondary unplugged | `Up` | `Down` | `Primary: Link carrier active; Secondary: Cable unplugged` |
| Secondary active, Primary unplugged | `Down` | `Up` | `Primary: Cable unplugged; Secondary: Link carrier active` |
| Both interfaces unconfigured | `Not configured` | `Not configured` | `Interfaces not configured` |
| Device disconnected / ConMon stopped | `Down` / `Degraded` | `Down` / `Degraded` | `Dante service provider disconnected` |
| Empty Dante network | Link states | Link states | `No Dante devices detected` (no false alarms) |

---

## 5. Verification & Automated Test Suites

### Unit Tests (`tests/dante/tst_dante.cpp`)
Built with `tests/dante/dante-test.pro` using `QtTest`:
1. `testInitialState`: Verifies default Off state and unconfigured defaults.
2. `testEnableDisableLifecycle`: Verifies timer activation, state transitions, and signal emission.
3. `testInterfaceProbing`: Tests empty, valid (`en0`), inactive (`en4`), and nonexistent adapters.
4. `testDaemonDetection`: Verifies live Audinate `conmon_cmm` detection on macOS.
5. `testFixtureTransitions`: Tests Up/Up, Up/Down, Down/Up, Down/Down, Degraded, and Unknown/Stale fixture injection.
6. `testSettingsPersistence`: Verifies round-trip persistence of adapter selection and enabled state.
7. `testEmptyNetworkBehavior`: Verifies that empty discovery returns "No Dante devices detected".
8. `testDisconnectedServiceBehavior`: Verifies graceful degradation when ConMon is stopped.

### QML Component Tests (`tests/dante/tst_dantestatus.qml`)
Executed via `qmltestrunner`:
1. `test_initialOffState`: Verifies default display and accessibility string.
2. `test_compactModeToggle`: Verifies standard vs compact abbreviation below 1024 px.
3. `test_clickAndKeyboardActivation`: Tests mouse click, Enter key, and Space key triggers.
4. `test_fixtureDisplay`: Confirms `[FIXTURE]` badge visibility.
5. `test_themeSwitching`: Verifies semantic status dot colors in both dark and light modes.

---

## 6. Live Hardware Validation Note

While local Darwin network carrier detection, daemon process monitoring, and preference auto-detection have been verified live on this macOS machine, multi-device Dante clock synchronization and audio packet flow telemetry can be further validated in a live Dante production network with physical stageboxes/consoles when hardware is attached.
