"""Composes a 480×270 Whisperwood mock screen to judge the art in context.

Tiles and sprites stay flat; the mock also fakes the engine's share of the
look (art bible §9) so the art is judged the way it will be seen: elliptical
cast shadows, the forest's dark multiply overlay, warm light breaking
through the canopy and a soft vignette. `--flat` skips those effects.
"""
import json
import math
import random
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

import palette
from autotile import clamped, clean, path_piece, stroke

T = 16
W, H = 30, 17
meta = json.load(open("../../assets/maps/whisperwood_tiles.json"))
cols = meta["columns"]
tiles_img = Image.open("../../assets/maps/whisperwood_tiles.png").convert("RGBA")
tile = {n: tiles_img.crop(((i % cols) * T, (i // cols) * T, (i % cols + 1) * T, (i // cols + 1) * T))
        for i, n in enumerate(meta["tiles"])}
props_img = Image.open("../../assets/images/props/whisperwood_props.png").convert("RGBA")
frames = json.load(open("../../assets/data/props_whisperwood.json"))
r = random.Random(4)


# ---------------------------------------------------------------- path layout

path = clean(stroke([(-1, 10.5), (11.5, 10.5), (11.5, 4.5), (31, 4.5)], 1.45, W, H)
             | stroke([(21.5, 4.5), (21.5, 18)], 1.45, W, H), W, H)
on_path = clamped(path, W, H)

# ---------------------------------------------------------------- ground

img = Image.new("RGBA", (W * T, H * T))
floors = ["floor", "floor_b", "floor_sun", "floor_sun_b", "floor_shade", "floor_shade_b"]
decor = ["grass", "grass_b", "grass_tall", "flowers_blue", "flowers_pink", "flowers_white", "clover", "ferns",
         "mushrooms", "litter", "pebbles", "twig"]
for y in range(H):
    for x in range(W):
        if (x, y) in path:
            name = path_piece(on_path, x, y)
            name = r.choice([name] * 2 + meta["variants"].get(name, []))
            img.alpha_composite(tile[name], (x * T, y * T))
        else:
            img.alpha_composite(tile[r.choices(floors, [10, 4, 1.4, 1.2, 1.2, 1])[0]], (x * T, y * T))
            if r.random() < 0.3:
                d = r.choices(decor, [8, 5, 3, 1.4, 1, 1, 2, 1.5, 0.6, 1.5, 1, 0.8])[0]
                img.alpha_composite(tile[d], (x * T, y * T))

# ---------------------------------------------------------------- props + characters

props = [("big_tree", 34, 116), ("big_tree_b", 128, 72), ("pine", 86, 52), ("small_tree", 200, 34),
         ("big_tree", 300, 150), ("pine", 470, 252), ("big_tree_b", 445, 150), ("small_tree", 468, 40),
         ("bush", 216, 206), ("bush", 62, 262), ("rock", 250, 118), ("rock_small", 290, 214),
         ("log", 118, 226), ("stump", 404, 238), ("ashblight", 392, 198), ("ashblight", 440, 204),
         ("signpost", 392, 106), ("pine", 20, 40), ("big_tree", 150, 290), ("big_tree_b", 410, 300)]
sheet_k = Image.open("../../assets/images/kael_sheet.png").convert("RGBA")
sheet_l = Image.open("../../assets/images/lira_sheet.png").convert("RGBA")
chars = [(sheet_k.crop((0, 96, 32, 144)), 124, 166), (sheet_l.crop((0, 96, 32, 144)), 100, 162)]  # facing right

flat = "--flat" in sys.argv
if not flat:  # engine: cast shadows under everything that stands
    shadows = Image.new("L", img.size, 0)
    d = ImageDraw.Draw(shadows)
    for n, bx, by in props:
        f = frames[n]
        rx = {"big_tree": 17, "big_tree_b": 17, "pine": 11, "small_tree": 10}.get(n, f["w"] * 0.45)
        d.ellipse([bx - rx + 3, by - 5, bx + rx + 5, by + 3], fill=110)
    for _, bx, by in chars:
        d.ellipse([bx - 8, by - 3, bx + 8, by + 2], fill=110)
    shade_col = Image.new("RGBA", img.size, (*palette.RGB["night"][0], 255))
    img = Image.composite(shade_col, img, shadows.point(lambda a: int(a * 0.55)))

drawables = [(by, ("prop", n, bx)) for n, bx, by in props] + [(by, ("char", im, bx)) for im, bx, by in chars]
for base_y, (kind, what, bx) in sorted(drawables, key=lambda q: q[0]):
    if kind == "prop":
        f = frames[what]
        spr = props_img.crop((f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"]))
        img.alpha_composite(spr, (bx - f["w"] // 2, base_y - f["h"]))
    else:
        img.alpha_composite(what, (bx - 16, base_y - 48))

if not flat:
    w, h = img.size
    # forest overlay: multiply toward a cool teal, a little darker at the top
    tint = Image.new("RGB", (w, h))
    td = ImageDraw.Draw(tint)
    for y in range(h):
        k = 0.82 + 0.12 * y / h
        td.line([(0, y), (w, y)], fill=(int(205 * k), int(225 * k), int(222 * k)))
    img = Image.merge("RGBA", (*ImageChops.multiply(img.convert("RGB"), tint).split(), img.getchannel("A")))
    # warm light breaking through the canopy: soft diagonal shafts, additive
    light = Image.new("L", (w, h), 0)
    ld = ImageDraw.Draw(light)
    for x0, width, a in ((150, 46, 38), (300, 30, 30), (40, 22, 22)):
        ld.polygon([(x0, 0), (x0 + width, 0), (x0 + width + 120, h), (x0 + 120, h)], fill=a)
    for cx, cy, rad, a in ((226, 150, 46, 40), (380, 70, 30, 30)):
        ld.ellipse([cx - rad, cy - rad * 0.6, cx + rad, cy + rad * 0.6], fill=a)
    light = light.filter(ImageFilter.GaussianBlur(14))
    warm = Image.new("RGB", (w, h), palette.RGB["ember"][3])
    rgb = ImageChops.add(img.convert("RGB"), ImageChops.multiply(warm, Image.merge("RGB", [light] * 3)))
    # vignette
    vig = Image.new("L", (w, h), 0)
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            d = math.hypot((x - w / 2) / (w / 2), (y - h / 2) / (h / 2))
            vig.putpixel((x, y), int(max(0.0, d - 0.7) * 150))
    vig = vig.filter(ImageFilter.GaussianBlur(6))
    rgb = Image.composite(Image.new("RGB", (w, h), palette.RGB["night"][0]), rgb, vig)
    img = rgb.convert("RGBA")

out = next((a for a in sys.argv[1:] if not a.startswith("--")), "mock.png")
img.resize((W * T * 3, H * T * 3), Image.NEAREST).save(out)
print("mock written", out, "(flat)" if flat else "(engine effects simulated)")
