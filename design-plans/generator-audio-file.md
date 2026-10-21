# Generator audio file

This is a scoped native Generator addition. The existing dark/light Qt Quick Material interface remains the visual authority; this document does not establish a new application design system.

## Entry point and visual treatment

With the Generator target set to **Local**, select **Audio file** in the signal-type list or press **Audio file…** beside the shared gain control. Both open the separate **Generator — Audio file** window. Remote targets omit this signal type and disable the entry button. An already open window explains that Local must be selected and disables local playback controls when a remote Generator is controlled.

The window uses the application's shell background and separator color, the current dark/light Material theme, and the incumbent Indigo accent. Standard Qt Quick buttons, checkboxes, sliders, spin boxes, the existing DropDown, and GeneratorChannelSelect preserve native application behavior. Error text uses theme-aware Material red; missing-output guidance uses theme-aware amber. No custom visual redesign is introduced.

The initial window is 700 × 630 with a 620 × 610 minimum. A scrollable column has 24-pixel outer margins and 12-pixel spacing. Body text is 14 pixels, the file heading is 20 pixels, and the routing explanation is 12 pixels. Long filenames elide in the middle with the full path available on hover; explanatory and error text wrap.

## Controls and states

| State or control | Implemented behavior |
| --- | --- |
| Empty | “Choose an audio file” heading, format/drop guidance, and Choose file…; transport and region controls are disabled. |
| Loading | “Loading audio…” heading; choosing, dropping, transport, region editing, channel mode, and output editing are disabled while decoding. |
| Ready | Filename, duration, sample rate, and Mono/Stereo metadata; Replace file… is available. Loading or replacing a file leaves playback paused. |
| Failed load | A readable inline error explains decoding, channel-count, empty-file, invalid-sample, or decoded-size rejection. A failed replacement preserves the previous file and leaves it paused. |
| No selected outputs | Inline guidance directs the user to Output channel selection. This warning does not itself disable transport. |

**Play/Pause** controls the shared Generator enable state and selects the audio-file signal type when necessary. Pause retains the playhead. **Stop** pauses and returns to Start. The position slider and **−5 sec / +5 sec** seek within the active region. Position and duration display minutes and seconds. At non-looping End, playback stops; a subsequent start begins at Start.

**Start (sec)** and **End (sec)** offer editable hundredth-second values, one-second step buttons, and **Set to playhead** actions. Bounds keep Start before End and End within the file. **Reset full file** restores the full-duration region. **Loop** repeats Start–End. The backend rejects invalid/non-finite region requests and requires at least one decoded frame.

**Gain (dB)** is the existing shared Generator gain, with the same **−140 to 0 dB** integer range in the main Generator and player window. It is not a second file-specific gain stage. Its player control remains available for the local Generator even while a file is loading or absent.

## Local decoding and file limits

Choose one existing local file through the system file dialog or drop one file into the window. Non-local URLs are rejected by the Generator API. Files are decoded with macOS AudioToolbox on the Generator thread into interleaved 32-bit floating-point PCM; the audio callback reads decoded samples. Other platform builds report that decoding requires macOS.

The chooser advertises WAV/WAVE, AIFF/AIF/AIFC, MP3, M4A/ALAC, AAC, FLAC, and CAF. Actual acceptance depends on the native decoder and an unprotected, valid file. Only mono or stereo files are accepted. Decoded PCM is limited to **512 MiB**; this is a decoded-memory limit, not a compressed-file-size limit. Empty and non-finite audio are rejected.

Audio stays in local memory for playback. This feature does not upload files or start playback automatically after selection, dropping, or replacement. Opening the player window alone does not load or play a file.

## Output and reference semantics

Output device, selected output channels, gain, and even-channel polarity are shared with the existing Generator. The player uses the existing device list and channel selector rather than an independent playback destination.

| File channels mode | Samples sent to selected outputs |
| --- | --- |
| Stereo (L / R) | L, R alternating across selected physical outputs in ascending channel order. |
| Mono (L + R) | The average `(L + R) / 2` on every selected output. |
| Left only | L on every selected output. |
| Right only | R on every selected output. |

A mono file supplies the same sample for L and R. Unselected outputs remain silent. Playback rate follows the selected output rate through linear interpolation. Existing gain and even-channel polarity are applied to the routed samples. The internal measurement reference follows the **first valid selected output**, including its gain and polarity; with no valid selected outputs, the reference is zero. It is not an independent stereo sum or external acoustic reference.

## Validation boundaries

`tests/generator/README.md` documents the macOS QtTest suite and fixture-generation requirements. The suite targets real-file decoding, routed sample values, gain, 44.1 → 48 kHz playback timing, region bounds, seeking, looping, EOF, mono duplication, and failed replacement. Homebrew FFmpeg generates fixtures for tests; it is not an application/runtime dependency. These tests do not open an audio device.

Live validation must separately cover entry points, choose/drop and paused loading, play/pause/stop, seeking, region/loop editing, channel modes, output selection, loading/error/remote states, keyboard use, and dark/light appearance in the native window. A passing decoder suite alone does not verify these interactions or rendered layout.

External-interface routing, audible output, acoustic/transfer-function accuracy, and long-session performance require separate hardware validation. This document records implementation behavior and validation scope; it does not certify those checks as completed.

Implementation references: `qml/AudioFilePlayer.qml`, `qml/GeneratorProperties.qml`, `src/generator/audiofile.h`, `src/generator/audiofile.cpp`, `src/generator/generator.cpp`, and `src/generator/generatorthread.cpp`.
