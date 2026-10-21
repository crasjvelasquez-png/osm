# Delay Finder

The Delay Finder assists in finding and applying reference delay for live transfer-function measurements.

Inspired by Smaart's "Find Delay" / "Insert" workflow, the Delay Finder replaces continuous live jitter with an explicit, stable **Find → Hold → Apply** cycle.

## Workflow

1. **Find Delay**:
   - When a valid, active measurement with live input is selected, the **Find Delay** button is enabled.
   - Clicking **Find Delay** starts a 2-second capture window. During capture, the button label changes to **Cancel**, allowing you to abort if desired.
   - Delay Finder collects incoming estimates emitted by the measurement engine.

2. **Hold and Inspect**:
   - To prevent applying noisy or spurious readings, the capture completes only if at least 3 estimates are recorded with a spread within $\le 0.10$ ms.
   - If readings vary or insufficient readings are gathered, the pill displays `"Readings vary — find again"` or `"Not enough readings — find again"`.
   - On a successful capture, the median estimate is locked into a stable **Held** state. The result does not flicker or time out.
   - You can click **Details** to open an inspector popover showing:
     - **Measured**: The newly estimated delay.
     - **Current**: The measurement's active reference delay when capture started.
     - **Change**: The signed delta between measured and current.
     - **Equivalent distance**: In meters or feet (calculated assuming standard air temperature of 20 °C).
     - **Wavelengths ($\lambda$)**: Number of wavelengths at the active chart cursor frequency.

3. **Apply**:
   - Clicking **Apply** sets the measurement's reference delay (`measurement.delay`) to the measured target.
   - The pill transitions to the quiet **Applied** state without causing self-invalidation or jumping.
   - You can click **Find again** whenever you want to perform another measurement.

## Invalidation & Watchdog

The held result remains visible until:
- The measurement is changed or deselected.
- Audio input is lost or stopped for $>3$ seconds.
- Stream or measurement configuration changes (active state, device ID, sample rate, data/reference channels, or manual delay adjustments).
