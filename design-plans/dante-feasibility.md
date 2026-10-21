# Dante Monitoring Feasibility & Probe Report

## 1. Post-Reinstall Environment & Probe Findings

### Host Environment
- **Platform:** macOS 15.8 (Darwin 24.6.0), Apple Silicon (arm64).
- **Installed Dante Controller:** Version `4.18.1.1` (Mach-O 64-bit arm64 executable in `/Applications/Dante Controller.app`).
  - Upgrade verified: replaces prior `4.14.1.2` release.
- **Audinate ConMon Daemon:**
  - Binary: `/Library/Application Support/Audinate/ConMon.bundle/Contents/MacOS/conmon_cmm` (v4.2.0.5).
  - Launch mechanism: macOS System LaunchDaemon (`/Library/LaunchDaemons/com.audinate.conmon.plist`).
  - State: Active and running (`PID 97678`, flags: `-ms -bd -ml -w -cmcp=connected -ll=warning -lf=/Library/Logs/Audinate/conmon.log`).

### Visible Controller Startup & Health
- Dante Controller was launched (`open -a "Dante Controller"`).
- Quartz window inspection via `CGWindowListCopyWindowInfo`:
  - Dante Controller main window rendered successfully: `Height = 900, Width = 1400, X = 56, Y = 41` (Window ID 25774).
  - Zero ConMon error dialogs or "Unable to connect to ConMon manager" alerts.
- Diagnostic logs in `~/Library/Logs/Audinate/`:
  - `DanteController-*.log`: `Critical: Dante Controller Version 4.18.1.1`, normal Qt UI initialization, web component initialized.

---

## 2. Telemetry & Interface Audit Matrix

| Probe Target | Protocol / Port | Observation / Result | Architectural Finding |
| :--- | :--- | :--- | :--- |
| **Dante Domain Manager (DDM) API** | TCP 8028 / 443 | Connection refused (`127.0.0.1:8028`) | No local DDM server installed or running. The official Audinate Managed API requires enterprise DDM server infrastructure and cloud tokens. |
| **Dante Controller Agent WebSocket** | TCP ephemeral (e.g. 61937) | `HTTP/1.1 426 Upgrade Required (Server: WebSocket++/0.8.2)` | Local helper (`DanteControllerAgent`) dynamically allocates ephemeral loopback TCP ports on launch. Uses proprietary internal WebSocket framing to feed internal Chromium/JxBrowser UI plugins. Not a stable public API. |
| **Dante Controller Agent HTTP Plugin** | TCP ephemeral (e.g. 61938) | `HTTP/1.1 200 OK` (Plugin static search path) | Internal static plugin file server. |
| **ConMon IPC Sockets** | UDP 52370, 58172 / UNIX domain | Active loopback listeners owned by `conmon_cmm` | ConMon communicates locally using proprietary binary C++ RPC structures (`conmon_client_*`, `conmon_channel_*`). No public C/C++ SDK is installed on host. |
| **macOS Audinate Defaults** | CoreFoundation Preferences | `com.audinate.dante.controller` contains `intfs` array with MAC addresses and adapter names | Stores user interface selection for Primary and Secondary adapters. |
| **macOS Native Network Interfaces** | BSD / `SystemConfiguration` | `en0` (Wi-Fi, active), `en4`, `en5`, `en24` (Ethernet adapters, inactive/no carrier) | Native link carrier state (`status: active` / `status: inactive`) can be queried with zero CPU overhead using BSD `getifaddrs` / routing sockets and macOS `SystemConfiguration`. |

---

## 3. Dependency Analysis: Does Dante Controller Need to Remain Open?

1. **Daemon vs. GUI Persistence:**
   - The ConMon manager daemon (`conmon_cmm`) runs as a persistent system LaunchDaemon. It remains running in the background when `Dante Controller.app` is closed.
   - However, `DanteControllerAgent` and its embedded Chromium renderer (`Chromium Helper`) terminate immediately when `Dante Controller` is quit.
2. **Public API Availability:**
   - Neither `Dante Controller.app` nor `conmon_cmm` provides a documented localhost REST or GraphQL telemetry API.
   - Ephemeral WebSocket ports are tied to the running GUI process and vary on every launch.
3. **Conclusion:**
   - There is no stable local background service from Audinate that OpenSoundMeter can connect to via standard HTTP/JSON or WebSocket without reverse-engineering proprietary ephemeral IPC.
   - Relying on undocumented ephemeral WebSocket ports spawned by Dante Controller would be brittle, version-dependent, and prone to breakage.

---

## 4. Decision Gate Outcome & Architecture Plan

In accordance with the criteria defined in [dante-monitoring.md](file:///Users/c4milo/Desktop/osm/design-plans/dante-monitoring.md):
- **Decision:** Do not attempt brittle reverse-engineering of ephemeral internal WebSocket sockets or fake Dante clock/stream telemetry.
- **Implementation Strategy:**
  1. **Isolated C++ Backend (`DanteMonitor`):**
     - Located in `src/dante/monitor.h` and `src/dante/monitor.cpp`.
     - Completely independent of `Measurement`, DSP, and audio processing pipelines.
     - Thread-safe immutable snapshots (`DanteSnapshot`) containing:
       - Configured Primary and Secondary adapter identities and carrier link status.
       - Discovered Dante network telemetry status (reporting accurately: "No Dante network detected" / "Monitoring unavailable" given the empty-network condition).
       - Timestamps, observation generations, and error reasons.
     - Zero-cost when disabled (Off); change-driven event notifications and low-frequency observation (1 Hz) when enabled, achieving < 0.2% incremental CPU.
     - Persistent nonsecret configuration under `dante/` settings group via OSM's `Settings`.
  2. **Compact Header Integration (`HeaderLevels.qml`):**
     - Sits immediately to the left of the 438 px SPL measurement block in the 56 px header.
     - Two responsive presentation modes:
       - Standard (>= 1024 px): `Dante`, `Primary · <State>`, `Secondary · <State>`.
       - Compact (< 1024 px): `Dante`, `P · <State>`, `S · <State>`.
     - Accessible keyboard navigation and tooltip / status readout.
     - Clicking opens/raises the nonmodal `DanteMonitoring.qml` tool window.
  3. **Dedicated Auxiliary Window (`DanteMonitoring.qml`):**
     - Conforms to the Studio theme and `SettingsDefaults.qml` window pattern.
     - Shows explicit Enable/Disable switch, Primary/Secondary link & network status, adapter details, error explanations, and status history.
