#!/usr/bin/env bash
# Render a looping BGM. The piece is rendered once plus a silent tail; the
# tail (reverb/release after the loop point) is mixed into the loop start, so
# looping playback is identical to an endless performance — no seam.
# usage: render.sh <name> <loop_seconds>
set -euo pipefail
cd "$(dirname "$0")"
name=$1; loop=$2
mkdir -p out ../../assets/audio/bgm
python3 "$name.py"
fluidsynth -ni -g 0.6 -R 1 -C 0 -r 44100 -F "out/$name.full.wav" soundfonts/GeneralUser-GS.sf2 "out/$name.mid" >/dev/null
L=$(python3 -c "print(round($loop*44100))")
ffmpeg -hide_banner -loglevel error -y -i "out/$name.full.wav" -filter_complex \
  "[0]asplit[a][b];[a]atrim=end_sample=$L[head];[b]atrim=start_sample=$L,asetpts=N/SR/TB[tail];[head][tail]amix=inputs=2:normalize=0:duration=first" \
  -c:a pcm_s16le "out/$name.raw.wav"
peak=$(ffmpeg -hide_banner -i "out/$name.raw.wav" -af volumedetect -f null - 2>&1 | sed -n 's/.*max_volume: \(-\{0,1\}[0-9.]*\) dB.*/\1/p')
gain=$(python3 -c "print(round(-1.0 - ($peak), 2))")
ffmpeg -hide_banner -loglevel error -y -i "out/$name.raw.wav" -af "volume=${gain}dB" -c:a pcm_s16le "out/$name.loop.wav"
ffmpeg -hide_banner -loglevel error -y -i "out/$name.loop.wav" -c:a libvorbis -q:a 5 "../../assets/audio/bgm/$name.ogg"
ffmpeg -hide_banner -loglevel error -y -stream_loop 1 -i "out/$name.loop.wav" -c:a libmp3lame -q:a 2 "out/$name.preview-2x.mp3"
echo "$name: peak ${peak}dB, gain ${gain}dB -> assets/audio/bgm/$name.ogg"
