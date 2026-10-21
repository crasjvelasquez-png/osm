# Dante monitoring beside the SPL readings

Status: implementation plan only. Written 2026-10-21 against `1ee9585fc94b75fdee053bea9709cf01c0484d4f`.
Priority: minimal OSM CPU overhead and accurate, explicitly scoped primary/secondary status.
Execution handoff: a separate agent should work in `/Users/c4milo/Desktop/osm`, read this entire document, and start with the post-reinstall feasibility milestone below. The user is reinstalling Dante Controller and has no active Dante network available. Do not interact with the installer, interrupt the reinstall, or interpret the current broken installation as an API limitation.

No working telemetry API, SDK, Dante hardware, or CPU benchmark has been verified. Proceed autonomously with read-only investigation and isolated implementation where the evidence permits; report the exact blocked dependency when it does not. Do not mark the full feature complete based on a mockup or fake telemetry.

## Local test evidence and first execution milestone

Observed before the reinstall on 2026-10-21:

- Controller and `DanteControllerAgent` processes were present, but the Controller window displayed: “Dante Controller was unable to connect to the Dante Control and Monitoring manager.” The dialog said Controller could not function without that connection and identified the conmon service/daemon as the likely cause. This is an observed service-connection failure, not a confirmed root-cause diagnosis.
- `ps -axo pid,comm | rg -i 'dante|conmon'` returned Controller-related processes but no matching conmon process. This limited process-name check does not establish whether a differently named service exists.
- `lsof -nP -iTCP:8028 -sTCP:LISTEN` produced no listener output under the current user's visibility. No HTTP/GraphQL request was sent, and no monitoring data was pulled.
- Testing stopped when the user began reinstalling. Controller-closed behavior, network-interface data access, API availability, CPU cost, and live device health remain untested.

After reinstall has finished, execute these five bounded steps:

1. **Recheck installation health.** Record installed Controller version/architecture, relevant processes and service status, and the visible Controller state using native UI inspection. Verify whether its normal network view opens without the conmon error. Do not reboot, reinstall, alter interfaces, change routes, or restart system daemons as part of this feature task. If the same error persists, record it as an environmental blocker and continue only independent fixture/model work.
2. **Inventory the local integration surface.** Inspect listening sockets belonging to Controller and its monitoring service, using read-only process/socket tools. Check vendor documentation for the observed version. Distinguish a UI-owned process from a persistent service; do not scan unrelated hosts or dump credentials, environment variables, or private databases. A missing port alone is not proof that no integration exists.
3. **Attempt bounded local read-only access.** If a local HTTP endpoint is actually observed and its protocol/path is established by documentation or installed interface metadata, make a short-timeout request for service/schema information and available interface/device status. No mutations, routing changes, authentication bypass, or guessed network-role mapping. A localhost-only introspection probe may establish technical accessibility of an undocumented endpoint; label it experimental, not supported. Save sanitized request/response examples and errors. Do not build a production dependency on that endpoint without revising the compatibility decision explicitly.
4. **Verify the empty-network case.** Record separately: provider reachable, local adapters available/assigned, discovery complete or still pending, and devices observed. A successful empty discovery result means **No Dante devices detected**, not **Primary down / Secondary down**. A failed service connection means **Monitoring unavailable**. If an adapter role is unassigned, show **Not configured**; if role health is not exposed, show **Unknown**. Record discovery completion semantics; an empty startup snapshot is not sufficient evidence that discovery finished.
5. **Check the Controller dependency and publish a decision.** Once reinstall is complete and Controller works, quit/reopen the Controller UI normally only when no installer or unsaved configuration is active. Compare service availability and the same read-only query before/after; restore Controller to open. Do not kill the monitoring daemon. Record whether the integration needs the UI, a separate persistent service, or a manager. Write `design-plans/dante-feasibility.md` with version, commands, sanitized results, capability matrix, recommendation, and unresolved hardware tests before selecting the production provider.

The capability matrix must cover local adapter identity/link, explicit primary/secondary assignment, per-device primary/secondary link, redundant/switched mode, discovery completion, freshness/disconnection, notifications versus polling, Controller-closed behavior, arm64 support, and redistribution requirements. Mark each **verified**, **documented only**, **unsupported**, or **untested** with evidence; never substitute plausibility for a result.

### Decision after the probe

Use a supported local provider if its required fields and lifecycle are verified. Use an already available managed provider only if the deployed schema supplies the necessary independent network evidence. If only an undocumented Controller endpoint works, preserve the probe as feasibility evidence and report the integration's unsupported/version-dependent status; do not present it as the selected reliable solution. If no suitable provider is accessible, deliver the tested status model and UI only as an explicitly incomplete development implementation, defaulting to Off/Unavailable. Do not enable fake data in normal application builds or silently replace Dante monitoring with generic Ethernet monitoring.

The absence of physical hardware need not block model tests or a correctly labeled empty-network integration. It does block claims of verified independent link failure, redundancy, end-to-end fault detection, and real-network performance. Keep those acceptance items pending in the final handoff.

## Decision and feasibility gate

Prefer a supported local Dante control/monitoring API with device/interface change notifications, combined with native macOS notifications for this computer's network adapters. This is an architectural preference, not a verified SDK capability or performance result. Before implementation, establish SDK access, Apple Silicon support, documented network-role/link-state fields, event/freshness semantics, Controller/service dependencies, and redistribution compatibility with this GPL repository. Do not embed an audio transport SDK merely to obtain status.

If an existing separate on-premises Dante Domain Manager service exposes the required fields through its supported API, using it may minimize work on the measurement Mac further. Evaluate that route first when such a deployment exists. Do not install a manager on the measurement Mac just to make two indicators work. Director is a supported managed integration option, but adds a cloud dependency for local live monitoring.

Research establishes an important gap: the published Managed API guide includes device connectivity/clocking/latency/subscription summaries and interface addressing, but its documented Interface type does not establish independent primary/secondary link health. Query the actual deployed schema and validate against controlled failures before accepting this backend. Aggregate connectivity OK must never produce two green network indicators. GraphQL audio-channel subscriptions are not evidence of a push-notification API.

No documented public Controller application API was verified. Audinate lists an internal Controller GraphQL UI port, which is not sufficient evidence of a supported integration contract. Avoid UI scraping, reading private Controller databases, or relying on undocumented endpoints. A supported independent backend should not require the Controller UI; SDK/service requirements remain to be proven. Managed API access uses the management service rather than the Controller UI.

If supported per-network telemetry cannot be obtained, defer full Dante monitoring. An explicitly named **This Mac: network links** mode may be proposed separately, but must not silently replace the requested feature. Adapter link-up, IP address, mDNS discovery, and ping cannot establish Dante clock lock, subscriptions, redundancy, or end-to-end audio delivery.

## Evidence chain and reuse

- Requested surface: supplied screenshot, header immediately to the left of all three SPL measurements. `qml/main.qml` instantiates `HeaderLevels` above both workspaces.
- Layout owner: `qml/HeaderLevels.qml`, 56 px header, flexible source-label column, then a fixed 438 px readings block. Main window minimum is 768×540. Preserve meter models, calibration, SPL popup, and source-following behavior.
- Design contract: `PRODUCT.md` requires restrained instrument density, explicit unavailable states, both themes, and continuous status without workspace changes. Reuse `StudioTheme` shell/panel/text/secondaryText/separator/focus/font tokens and `elements/StudioButton.qml`.
- Window exemplar: `qml/SettingsDefaults.qml` demonstrates a separate themed ApplicationWindow and show/raise/requestActivate behavior. Reuse window mechanics, not defaults or measurement-draft semantics.
- Application wiring: `src/main.cpp` owns context objects; `qml.qrc` owns QML resources; `OpenSoundMeter.pro` owns compiled sources. Existing unrelated DelayFinder changes and `docs/delay-finder.md` must remain untouched.

## UI and status contract

Insert a single keyboard-accessible Dante control between the flexible measurement title and the existing readings. Standard presentation: label **Dante**, then **Primary · Up** and **Secondary · Up**, with small status dots and textual states. Do not increase the header height or move the SPL settings hit area. Below 1024 px, abbreviate labels to **P** and **S**, with full accessible names and details on activation. At 768 px, budget about 144 px for this compact control; elide the source title first. Verify real text metrics rather than relying on this estimate.

Click opens one nonmodal **Dante Monitoring** window; repeated activation raises the existing window. Closing it leaves enabled monitoring running. First use presents setup rather than fictitious status; an explicit enable switch controls monitoring and persistence.

The window contains two network rows: role, state, and relevant adapter/device identity. Its small footer identifies scope (this Mac or selected Dante devices), provider, last successful observation, and a concise cause when degraded. Put configuration behind **Configure**. Optional clock warning belongs in details only when supported. No routing matrix, graphs, meters, automatic audio changes, or scrolling event console.

Keep this computer's connections separate from remote device health. A Mac with only a primary adapter may still receive reports about remote secondary links; that does not mean the Mac is connected to secondary. Do not infer network roles from adapter order, subnet, or the existence of two Ethernet ports. User mapping identifies intended Mac roles; provider metadata must identify device roles and redundant versus switched operation.

| Display state | Evidence required |
| --- | --- |
| Up | Fresh, explicit link-up for the named scope; does not claim audio delivery |
| Down | Explicit link-down for an expected interface; provider silence alone is insufficient |
| Degraded | Verified warning/failure among the selected expected devices; details identify affected devices |
| Unknown / Stale | Unsupported field, incomplete coverage, missing telemetry, provider failure, or expired observation |
| Not configured / Not supported / Off | Distinct intentional, capability, and monitoring-disabled states; no false alarm |

Retain expected device IDs after disappearance so offline devices do not silently leave the aggregate. All expected, supported links need fresh evidence for an aggregate Up; show failure if confirmed, otherwise Unknown for incomplete coverage. Distinguish secondary intentionally unused from expected-but-down. Never display an active-versus-standby claim: redundant Dante transmits on both networks simultaneously.

## Implementation milestones

1. **Prove the provider before building the feature.** Produce a capability matrix and small read-only probe for the available supported integration. Capture primary/secondary identity, independent link failure, switched/unsupported secondary, observation age, and provider disconnection. Test with Controller closed. If the required fields are absent, record the limitation and stop full-health integration; do not substitute guessed data.
2. **Add an isolated status backend.** Proposed `src/dante/monitor.{h,cpp}` owns normalized immutable snapshots, provider capability flags, expected scope, freshness, and enable/configuration state. Separate provider implementation from status reduction; use native macOS link notifications for local connectivity. Publish via a `danteMonitor` context property in `src/main.cpp`. Persist nonsecret configuration under a dedicated `dante/` settings group; use Keychain for API credentials. No credentials in logs or session files. Cancel outstanding work on disable/shutdown.
3. **Add the header and window.** Proposed `qml/DanteStatus.qml` and `qml/DanteMonitoring.qml`, registered in `qml.qrc`, composed by `HeaderLevels.qml` and `main.qml`. Reuse the existing theme and window primitives. Add a discoverable monitoring entry to both menu variants if the header can be hidden. Keep state independent of the selected measurement or TF/RTA workspace.
4. **Optimize the measured path.** Receive events where the supported backend actually provides them. Use one asynchronous networking owner outside DSP/audio callbacks, persistent connections, bounded response sizes, cached identities, and change-only Qt property notifications. For request-only APIs, begin with one batched status request every 2 seconds for the selected scope, never one request per device and never overlapping requests. Respect documented rate limits, back off on failures, and expire data independently of retry timing. Proposed stale deadline: 6 seconds without a trustworthy update, adjusted to documented upstream cadence. A successful HTTP response does not prove device data is fresh. Do not pause health updates just because the details window closes. Avoid per-frame timers, packet capture, audio-stream inspection, or unbounded histories.
5. **Validate correctness and cost.** Add QtTest state-reduction/provider tests and QML tests for interaction/layout; run the existing arm64 Qt 5/qmake build workflow after checking its current location. Exercise live primary-only loss, secondary-only loss, both loss, adapter removal/rename, sleep/wake, single-network operation, stale/cached API responses, revoked credentials, and Controller closure. Compare timestamps with Controller and controlled physical actions. Keep hardware acceptance separate from fixtures.

### Backend contract and test boundaries

Keep provider availability, discovery state, local adapter state, and device-network state as separate fields. Each snapshot needs provider ID/version, configuration generation, stable scope/device IDs, capabilities, explicit role mapping, observation timestamp, last successful transport check, and the normalized status/reason for each role. Track elapsed time with a monotonic clock; wall time is for display only. Discard responses from an earlier provider/configuration generation after switching or disabling monitoring.

Event-driven providers need a documented liveness check or heartbeat. An unchanged link can remain valid while its event stream is healthy; do not mark it stale simply because no change event arrived for six seconds. Conversely, a healthy HTTP connection must not refresh the age of cached device data. If the provider cannot distinguish these cases, expose the uncertainty. Prefer one expiration timer scheduled for the next deadline; do not run a UI animation timer to update “last seen.”

Use one worker/event-loop owner for network operations where needed, with queued immutable updates to the GUI; never call networking or parse telemetry in an audio callback. Coalesce bursts without hiding faults; only emit property changes when values change. Bound retry frequency and diagnostics, stop subscriptions/timers on disable, and revalidate after sleep/wake. Persist configuration only, never a green runtime state across launches. Monitoring must not activate measurement acquisition at startup.

Create `tests/dante/` following the repository's existing QtTest conventions. Test empty discovery versus unavailable service; missing role metadata; all expected devices healthy; one missing device; explicit primary/secondary failures; intentional unused secondary; switched mode; partial/unknown fields; stale data; healthy idle event streams; reconnection; out-of-order responses; configuration changes; disable and shutdown. Fixture injection must be confined to tests/development and visibly labeled when rendered.

## Executor deliverables and completion criteria

1. `design-plans/dante-feasibility.md`: reproducible post-reinstall probe, evidence matrix, supported-provider decision, and Controller/service dependency answer. Include exact errors and limits without secrets or full local network inventory.
2. If feasible, isolated backend and QML integration in the named files, plus any platform provider files required. Keep UI-provider coupling out of `Measurement` and DSP classes. Before editing, recheck current source and uncommitted work; the commit and file list in this plan are a baseline, not permission to overwrite newer changes.
3. QtTest/QML test targets with exact commands and results, a rebuilt arm64 application using the checkout's verified build workflow, and native screenshots of both themes and minimum/standard widths. An HTML mockup does not count as native rendered verification.
4. Performance evidence separated into local no-network measurements, simulated-device scaling, and pending real-network measurements. If Controller must stay open, include its process/service overhead in the reported system cost, not just OSM's incremental CPU. State workload, run duration, device count, hardware, and sampling method.
5. `docs/dante-monitoring.md` if implemented, and a final handoff stating what works, which provider is used, whether Controller must stay open, known limitations, and the single next hardware-validation step. If blocked, state the smallest missing dependency and retain useful probe/test artifacts; do not call the feature complete.

## Performance and acceptance

Compare monitoring Off, enabled/header-only, and window-open using the same release build, measurement workload, device count, and 10-minute runs. Include 1, 10, and the intended maximum monitored-device count. Report incremental CPU (100% = one core), wakeups, memory, request rate, and fault detection time, including upstream telemetry delay. Proposed engineering target: less than one percentage point of one core on average for the typical scope, no growing memory/log usage, no new audio dropouts, and no measurable regression in measurement processing. This target is not a guarantee or benchmark result. If missed, profile before increasing polling intervals and hiding faults.

Native UI checks: 768×540, 1024×768, and large desktop; dark/light themes; long names; every state; keyboard activation; repeated open/close; no overlap with dBA Slow/dBC Fast/SPL or the SPL popup. No full-header repaint on unchanged readings. Existing SPL, calibration, RTA/TF, generator, and saved-session behavior remain unchanged.

Repository check after implementation: `git diff --check`; build with the verified existing Qt 5 arm64 configuration, run the new test targets, and document exact commands/results. For this planning task, only this document and an optional mockup are created; no app tests or CPU claims are implied.

## Stop conditions and documentation

Stop full Dante integration if there is no supported provider for independent network states, SDK access/distribution/platform requirements cannot be met, or data freshness cannot be established. Do not silently widen scope to routing, audio transport, proprietary protocol reverse engineering, or deployment of new infrastructure. After implementation, document supported providers, exact state meanings, scope, and measured limits in `docs/dante-monitoring.md`.

## Sources checked 2026-10-21

- [Dante Managed API](https://www.getdante.com/products/network-management/dante-managed-api/): supported managed integration and customer prerequisites.
- [Managed API User Guide](https://dev.audinate.com/GA/managed-api/userguide/pdf/latest/): published DDM schemas; Interface addressing fields and DeviceStatus summaries, not a verified two-link health interface. Published schema may lag deployed versions.
- [Dante routing and redundancy](https://dev.audinate.com/GA/dante-controller/userguide/webhelp/content/routing_media.htm): simultaneous primary/secondary transmission.
- [Dante ports](https://support.getdante.com/hc/en-gb/articles/5508285534239-Which-network-ports-does-Dante-use): internal Controller GraphQL UI port does not establish public API support.
- [Audinate on Dante API and product development](https://www.audinate.com/press/audinates-dante-now-supported-in-more-than-3000-device/): vendor evidence of custom control/monitoring API availability; not confirmation of current SDK access, arm64 support, or notification fields.
