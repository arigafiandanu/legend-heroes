"""Fails if an image uses colours outside LH-48 or semi-transparent pixels."""
import sys

from PIL import Image

import palette

bad = 0
for path in sys.argv[1:]:
    img = Image.open(path).convert("RGBA")
    colours = {p for p in img.getdata()}
    off = {p[:3] for p in colours if p[3] == 255 and p[:3] not in palette.ALL}
    alpha = {p[3] for p in colours if p[3] not in (0, 255)}
    status = "ok" if not off and not alpha else "FAIL"
    print(f"{status}  {path}: {len(colours)} colours" +
          (f", off-palette {['#%02X%02X%02X' % c for c in sorted(off)][:8]}" if off else "") +
          (f", semi-transparent alpha {sorted(alpha)[:5]}" if alpha else ""))
    bad += bool(off or alpha)
sys.exit(1 if bad else 0)
