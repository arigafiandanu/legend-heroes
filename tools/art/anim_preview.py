"""Animated GIF of the enemy battle sheets, so animations can be reviewed:
idle → attack → idle → hit → idle → KO for every enemy side by side. Uses
each sheet's JSON (frame ms + engine offsets), with a cast shadow like the
engine's. Usage: python3 anim_preview.py out.gif [scale]"""
import json
import sys

from PIL import Image, ImageDraw

import enemies
import palette

names = list(enemies.ENEMIES)
sheets = {n: Image.open(f"../../assets/images/enemies/{n}_battle.png").convert("RGBA") for n in names}
metas = {n: json.load(open(f"../../assets/images/enemies/{n}_battle.json")) for n in names}
S = enemies.SIZE
SLOT_W, H, BASE = S + 30, S + 20, S + 6
scale = int(sys.argv[2]) if len(sys.argv) > 2 else 4
BG = palette.RGB["night"][1]

script = ["idle"] * 3 + ["attack"] + ["idle"] * 2 + ["hit"] + ["idle"] * 2 + ["ko"]
steps = []  # (anim, frame index, ms)
for anim in script:
    m = metas[names[0]]["anims"][anim]
    steps += [(anim, i, ms) for i, ms in enumerate(m["ms"])]
steps.append(("ko", 2, 700))  # hold the last KO frame

frames, durations = [], []
for anim, i, ms in steps:
    img = Image.new("RGBA", (SLOT_W * len(names), H), (*BG, 255))
    d = ImageDraw.Draw(img)
    for k, n in enumerate(names):
        m = metas[n]["anims"][anim]
        dx, dy = m["offsets"][i]
        x0 = k * SLOT_W + 8 + dx
        flyer = n == "wisp_moth"
        sx = x0 + S // 2
        d.ellipse([sx - 13, BASE - 3 + (6 if flyer else 0), sx + 13, BASE + 2 + (6 if flyer else 0)],
                  fill=(*palette.RGB["night"][0], 255))
        img.alpha_composite(sheets[n].crop((i * S, m["row"] * S, (i + 1) * S, (m["row"] + 1) * S)),
                            (x0, BASE - S + dy))
    frames.append(img.convert("RGB").resize((img.width * scale, img.height * scale), Image.NEAREST))
    durations.append(ms)

out = sys.argv[1] if len(sys.argv) > 1 else "enemies.gif"
frames[0].save(out, save_all=True, append_images=frames[1:], duration=durations, loop=0, disposal=1)
print("gif written", out, len(frames), "frames")
