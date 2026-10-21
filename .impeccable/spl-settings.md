# Header SPL settings

## Overview

Scoped refinement of the incumbent native Qt input monitor in `qml/HeaderLevels.qml`. Preserve the practical instrument density described in `PRODUCT.md`; `qml/StudioTheme.qml` remains the authority for both themes. This note describes current source behavior, not acoustic validation or a completed native interaction test.

## Layout

Keep the header at 56 px with 16 px horizontal margins and spacing. Its fixed 438 × 48 px reading group retains two 120 px cells and a 198 px SPL cell. Preserve source name, textual input state, the existing dBA Slow and dBC Fast readings, and the bottom separator.

The SPL cell alone gains a subtle theme hover fill, inset by 3 px, with the existing 6 px control radius. Opening settings retains that fill and adds a focus-colored outline. No hover tooltip is present. Clicking opens a compact, nonmodal popup below the header: 320 px wide, 20 px padding, right-aligned with a 16 px inset and a 6 px vertical gap. It must not dim or block the measurement workspace.

## Colors

Reuse shell, panel, hover, separator, text, secondary-text, and focus tokens. The popup uses tonal layering and a separator border with 10 px corners; no new decorative palette, shadow, or motion is introduced.

## Typography

Retain the application font, 12 px secondary labels, 13 px source name, and 17 px semibold readings. The popup title is 16 px semibold. Preserve one decimal place and the existing unavailable and nonfinite reading states.

## Components

- **Reading:** Live uses the existing RMS meter with Fast or Slow response; Average · Leq uses the existing averaging meter with 1, 5, 10, 15, 30, 60, or 120 minute windows. The header label identifies weighting, mode/response, and optional maximum hold.
- **Weighting:** A, C, or Z applies to the SPL reading. The independent dBA Slow and dBC Fast cells retain their settings.
- **Hold and reset:** “Hold highest reading” controls peak hold. Live offers “Reset highest reading,” enabled with a source and hold active. Average offers “Restart average,” enabled with a source; restarting recreates averaging history. Source, weighting, or averaging-window changes also recreate the average so histories do not mix.
- **Lifetime:** Settings are header properties, defaulting to Live, Z, Slow, one minute, and hold off. They are session-scoped; no persistent settings store is added.

## Native keyboard expectations

The SPL button has the accessible name “SPL settings.” Verify Tab/Shift+Tab navigation, a visible keyboard focus indicator, and standard Qt button activation with Space/Enter. Opening the popup must place focus inside it; its mode buttons, combo boxes, checkbox, and reset action must be reachable and operable without a mouse. Escape or an outside press closes the popup. Verify focus returns to the SPL trigger after dismissal and that closed popup controls leave the tab sequence. These are native acceptance checks, not claims of completed testing.

## Do's and Don'ts

Preserve existing header geometry, theme behavior, measurement selection, status warnings, calibration ownership, and plot access. Keep changes local to the SPL settings surface. Do not interpret source inspection as proof of SPL calibration, weighting accuracy, RMS/Leq correctness, peak-hold accuracy, or acoustic measurement validity; those need separate measurement validation.
