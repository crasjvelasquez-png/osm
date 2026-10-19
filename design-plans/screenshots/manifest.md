# Native screenshot and coverage manifest

Captured 2026-10-19 on macOS at 2× display scale. The user dismissed the microphone permission prompt; no audio output was enabled. Screenshot sizes below are logical window points. The before/after RTA captures have different window sizes and input states, so they document visual direction rather than a pixel-matched comparison.

| View | Theme | Window | Before | After | Coverage |
| --- | --- | --- | --- | --- | --- |
| RTA, expanded, Heatmap on | Dark | Before 1580 × 1012; after 1624 × 1056 | [Before](before/rta-expanded-dark.png) | [After](after/rta-expanded-dark.png) | Full averaging and action labels visible after; input unavailable before and stopped after |
| Three-chart layout | Dark | 1512 × 944 | — | [After](after/chart-layout-three-dark.png) | Navigation from RTA verified |
| RTA, collapsed, Heatmap on | Dark | 1512 × 944 | — | [After](after/rta-collapsed-dark.png) | Collapse control verified |
| RTA, collapsed, Heatmap off | Dark | 1025 × 769 | — | [After](after/rta-collapsed-heatmap-off-dark.png) | Heatmap toggle hides plot and legend |
| RTA, collapsed and expanded | Dark | 768 × 568 | — | [Collapsed](after/rta-collapsed-compact-dark.png), [expanded](after/rta-expanded-compact-dark.png) | Width target checked; native window stopped at its 568-point minimum height |
| RTA, expanded | Light | 768 × 568 and 1512 × 944 | — | [Compact](after/rta-expanded-compact-light.png), [desktop](after/rta-expanded-light.png) | Theme toggle and layout checked |
| Defaults: Measurement, Magnitude, RTA / Spectrum | Dark | 760 × 668 dialog | — | [Measurement](after/defaults-measurement-dark.png), [Magnitude](after/defaults-magnitude-dark.png), [RTA](after/defaults-rta-dark.png) | All tabs opened; Cancel used without changing defaults |
| Defaults: Measurement, Magnitude, RTA / Spectrum | Light | 760 × 668 dialog | — | [Measurement](after/defaults-measurement-light.png), [Magnitude](after/defaults-magnitude-light.png), [RTA](after/defaults-rta-light.png) | All tabs opened; Cancel used without changing defaults |

## Coverage still required

| Family | Status |
| --- | --- |
| One/two chart layouts; ten standard and three experimental chart types; Numeric meter and plot properties | Not captured |
| FIFO/Off averaging and running measurement | Not captured; running state depends on input permission and hardware |
| Stored, Union, Standard Line, Filter, Equalizer, Windowing, Group, nested library, target trace, remote item | Not captured; remote item depends on a peer |
| Defaults scrolled content and save/dirty transactions; generator conditional fields; calculator, remote settings, About, Shortcuts, updater | Not captured |
| Menus beyond View, side drawer, native file/color choosers, error and confirmation dialogs | Not captured |
| Exact 768 × 540 window | App minimum height prevented this size in the native window |

Do not infer coverage of the remaining views from the QML build or source inspection. Full interaction checks should use a disposable workspace and available audio hardware.
