# Instrument presentation tokens

Status: implemented in QML on 2026-10-19. These values refine the existing scientific instrument interface; chart and measurement colors retain their existing owners.

| Surface | Dark | Light |
| --- | --- | --- |
| Shell | `#202226` | `#ECEEF1` |
| Panel | `#292C31` | `#F7F8FA` |
| Control | `#31353B` | `#FFFFFF` |
| Hover | `#3B4048` | `#E8ECF2` |
| Separator | `#41464F` | `#D0D5DD` |
| Text | `#F0F2F5` | `#20252D` |
| Secondary text | `#B7BEC8` | `#5C6573` |

The single QML owner is `applicationWindow.ui` in `qml/main.qml`. The existing Material indigo accent and semantic warning/error colors remain separate. Shared fields use a 36-pixel height, 6-pixel radius, 1-pixel border, and 2-pixel accent focus border. Numeric fields reserve 28 pixels for each stepper. Normal text is 14 logical pixels; secondary RTA labels are 12.

Source rows remain 50 pixels high, the sidebar remains 240 pixels wide, and plot/trace colors remain unchanged. The RTA control groups wrap as units with 8-pixel gaps. Presentation changes do not alter measurement or persistence behavior.
