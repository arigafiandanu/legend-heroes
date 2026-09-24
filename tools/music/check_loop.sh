#!/usr/bin/env bash
# Click check at the loop seam: the sample step across end->start must be no
# larger than the biggest step found anywhere inside the loop.
# usage: check_loop.sh <name>
set -euo pipefail
cd "$(dirname "$0")"
python3 - "$1" <<'PY'
import sys, wave, struct
w = wave.open(f"out/{sys.argv[1]}.loop.wav")
n, ch = w.getnframes(), w.getnchannels()
s = struct.unpack('<%dh' % (n * ch), w.readframes(n))
worst = 0
for c in range(ch):
    x = s[c::ch]
    inner = max(abs(x[i + 1] - x[i]) for i in range(len(x) - 1))
    seam = abs(x[0] - x[-1])
    print(f"channel {c}: seam step {seam}, max inner step {inner}")
    worst = max(worst, seam / inner)
sys.exit(0 if worst <= 1.0 else 1)
PY
