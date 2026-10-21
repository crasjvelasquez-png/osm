# Generator audio-file checks (macOS)

The QtTest suite decodes real WAV (float and 24-bit), AIFF, MP3, AAC/M4A,
ALAC, AAC/ADTS, FLAC and CAF fixtures. It checks rendered channel samples,
gain, 44.1 → 48 kHz playback timing, region bounds, seeking, looping, EOF,
mono duplication and failed-file replacement. It never opens an audio device.

Requires Qt 5 and Homebrew FFmpeg (`/opt/homebrew/bin/ffmpeg`) to generate
fixtures; FFmpeg is **not** an application/runtime dependency.

Build outside the source tree:

```sh
mkdir -p /tmp/osm-audiofile-tests
cd /tmp/osm-audiofile-tests
/opt/homebrew/opt/qt@5/bin/qmake /Users/c4milo/Desktop/osm/tests/generator/audiofile.pro
make -j6
./audiofile-test
```

File decoding currently uses macOS AudioToolbox. Files must be unprotected
mono or stereo; decoded audio is capped at 512 MiB. Files stay in memory for
playback and never upload to a server. Other platform builds retain the
existing signal generators and report that file decoding requires macOS.

Live checks also required after changes: select Generator → Audio file,
choose or drop a file, confirm it opens paused, test play/pause/stop and
seeking, set Start/End and Loop, choose output channels and check channel
modes. The internal reference follows the first selected output. External
interface/acoustic accuracy and long-session performance need separate
hardware validation.
