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
tools/music/render.sh hollowmere      # <piece>; loop length comes from the piece
tools/music/check_loop.sh hollowmere  # click check at the loop seam
afplay tools/music/out/hollowmere.preview-2x.mp3   # listen, loop point included
```

- `smf.py` writes MIDI, `theory.py` has note/chord helpers, one `<piece>.py` per track.
- The piece renders once plus a silent tail; `render.sh` mixes the tail into the
  loop start so the file loops seamlessly, normalises loudness (exploration
  −14 LUFS, battle −13, boss −12.5; limiter at −1 dBFS) and writes
  `assets/audio/bgm/<piece>.ogg` (+ a 2× MP3 preview in `out/`, git-ignored).
- iOS note: audioplayers on iOS cannot play Ogg Vorbis. When audio is wired in,
  also export `.m4a` (or `.caf`) for iOS.

| Track | File | Loop | Loudness |
| --- | --- | --- | --- |
| Hollowmere (village) | `hollowmere.py` | 60.0 s | −14 LUFS |
| Whisperwood (forest) | `whisperwood.py` | 65.5 s | −14 LUFS |
| Old Emberline Mine | `emberline_mine.py` | 63.2 s | −14 LUFS |
| Battle | `battle.py` | 51.2 s | −13 LUFS |
| Boss: Cinder Warden | `boss.py` | 55.7 s | −12.5 LUFS |
| Main theme: Legend Heroes | `main_theme.py` | 72.0 s | −14 LUFS |

`arrange.py` validates that every melody bar fills the meter and warns when a
long melody note rubs a semitone against the bar's chord.
