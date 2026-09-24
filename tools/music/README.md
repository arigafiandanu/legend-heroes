# Music tools

BGM is composed as code (Python, no dependencies) and rendered with FluidSynth
using the GeneralUser GS soundfont (free for commercial music and software).

## Setup

```sh
brew install fluid-synth ffmpeg
mkdir -p tools/music/soundfonts
curl -L -o tools/music/soundfonts/GeneralUser-GS.sf2 \
  https://github.com/mrbumpy409/GeneralUser-GS/raw/main/GeneralUser-GS.sf2
```

## Render

```sh
tools/music/render.sh hollowmere 60   # <piece> <loop seconds>
tools/music/check_loop.sh hollowmere  # click check at the loop seam
afplay tools/music/out/hollowmere.preview-2x.mp3   # listen, loop point included
```

- `smf.py` writes MIDI, `theory.py` has note/chord helpers, one `<piece>.py` per track.
- The piece renders once plus a silent tail; `render.sh` mixes the tail into the
  loop start so the file loops seamlessly, normalises to −1 dBFS and writes
  `assets/audio/bgm/<piece>.ogg` (+ a 2× MP3 preview in `out/`, git-ignored).
- iOS note: audioplayers on iOS cannot play Ogg Vorbis. When audio is wired in,
  also export `.m4a` (or `.caf`) for iOS.

| Track | File | Status |
| --- | --- | --- |
| Hollowmere (village) | `hollowmere.py` | draft v1 |
| Whisperwood (forest) | — | todo |
| Old Emberline Mine | — | todo |
| Battle | — | todo |
| Boss (Cinder Warden) | — | todo |
| Main theme | — | todo |
