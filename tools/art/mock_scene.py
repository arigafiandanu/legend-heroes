"""Composes a 480×270 Whisperwood mock screen to judge the art in context."""
import json
import random
import sys

from PIL import Image

import whisperwood
from autotile import path_piece

T = 16
tiles_img = Image.open("../../assets/maps/whisperwood_tiles.png").convert("RGBA")
names = ["floor", "floor2", "floor3", "moss", "flowers", "ferns", "mushrooms", "litter"] + list(whisperwood.PATH_PIECES)
tile = {n: tiles_img.crop(((i % 8) * T, (i // 8) * T, (i % 8 + 1) * T, (i // 8 + 1) * T)) for i, n in enumerate(names)}
props_img = Image.open("../../assets/images/props/whisperwood_props.png").convert("RGBA")
frames = json.load(open("../../assets/data/props_whisperwood.json"))

W, H = 30, 17
r = random.Random(4)
path = {(x, y) for x in range(0, 17) for y in (8, 9)} | {(x, y) for x in (15, 16) for y in range(3, 10)} \
    | {(x, y) for x in range(15, 30) for y in (3, 4)}
img = Image.new("RGBA", (W * T, H * T))
for y in range(H):
    for x in range(W):
        if (x, y) in path:
            name = path_piece(lambda a, b: (a, b) in path, x, y)
        else:
            name = r.choices(["floor", "floor2", "floor3", "moss", "flowers", "ferns", "mushrooms", "litter"],
                             [12, 6, 8, 0.5, 0.7, 0.6, 0.25, 0.6])[0]
        img.alpha_composite(tile[name], (x * T, y * T))

props = [("big_tree", 40, 110), ("big_tree", 150, 70), ("small_tree", 105, 60), ("big_tree", 360, 150),
         ("bush", 210, 190), ("rock", 300, 110), ("log", 120, 230), ("stump", 420, 230), ("ashblight", 330, 200),
         ("small_tree", 450, 110), ("big_tree", 440, 260), ("signpost", 262, 124), ("bush", 60, 260), ("big_tree", 230, 60)]
sheet_k = Image.open("../../assets/images/kael_sheet.png").convert("RGBA")
sheet_l = Image.open("../../assets/images/lira_sheet.png").convert("RGBA")
chars = [(sheet_k.crop((0, 96, 32, 144)), 200, 150), (sheet_l.crop((0, 96, 32, 144)), 176, 146)]  # facing right
drawables = [(by, ("prop", n, bx)) for n, bx, by in props] + [(by, ("char", im, bx)) for im, bx, by in chars]
for base_y, (kind, what, bx) in sorted(drawables, key=lambda d: d[0]):
    if kind == "prop":
        f = frames[what]
        spr = props_img.crop((f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"]))
        img.alpha_composite(spr, (bx - f["w"] // 2, base_y - f["h"]))
    else:
        img.alpha_composite(what, (bx - 16, base_y - 48))
out = sys.argv[1] if len(sys.argv) > 1 else "mock.png"
img.resize((W * T * 3, H * T * 3), Image.NEAREST).save(out)
print("mock written", out)
