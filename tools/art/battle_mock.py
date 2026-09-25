"""Composes a 480×270 Whisperwood battle screen to judge enemy sprites in
context: forest backdrop, enemies on the left facing right, party on the
right. The party uses overworld frames until battle sprites exist. Engine
effects (shadows, forest overlay) are faked as in mock_scene.py."""
import json
import random
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

import palette

T = 16
W, H = 480, 270
meta = json.load(open("../../assets/maps/whisperwood_tiles.json"))
cols = meta["columns"]
tiles_img = Image.open("../../assets/maps/whisperwood_tiles.png").convert("RGBA")
tile = {n: tiles_img.crop(((i % cols) * T, (i // cols) * T, (i % cols + 1) * T, (i // cols + 1) * T))
        for i, n in enumerate(meta["tiles"])}
props_img = Image.open("../../assets/images/props/whisperwood_props.png").convert("RGBA")
frames = json.load(open("../../assets/data/props_whisperwood.json"))
r = random.Random(7)

img = Image.new("RGBA", (W, H))
for y in range(0, H, T):
    for x in range(0, W, T):
        img.alpha_composite(tile[r.choices(["floor", "floor_b", "floor_sun", "floor_shade"], [8, 3, 1, 1])[0]], (x, y))
        if r.random() < 0.25:
            img.alpha_composite(tile[r.choice(["grass", "grass_b", "clover", "litter", "flowers_blue"])], (x, y))


def prop(name, bx, by):
    f = frames[name]
    img.alpha_composite(props_img.crop((f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"])), (bx - f["w"] // 2, by - f["h"]))


# tree line behind the arena
for i, bx in enumerate(range(-10, W + 40, 34)):
    prop(["big_tree", "pine", "big_tree_b", "small_tree"][i % 4], bx + r.randint(-6, 6), 70 + r.randint(-8, 8))
for i, bx in enumerate(range(8, W, 46)):
    prop(["bush", "pine", "big_tree"][i % 3], bx + r.randint(-6, 6), 96 + r.randint(-4, 6))
prop("ashblight", 300, 262)
prop("rock_small", 450, 256)

enemies = [("moss_wolf", 48, 120, 196), ("ashen_rat", 48, 70, 150), ("blight_sprout", 48, 170, 150),
           ("wisp_moth", 48, 60, 232)]
frame = int(next((a[2:] for a in sys.argv[1:] if a.startswith("-f")), "0"))
shadows = Image.new("L", (W, H), 0)
d = ImageDraw.Draw(shadows)
for name, size, bx, by in enemies:
    rx = size * 0.38
    lift = 8 if name == "wisp_moth" else 0
    d.ellipse([bx - rx, by + lift - 3, bx + rx, by + lift + 3], fill=120)
party = Image.open("../../assets/images/kael_sheet.png").convert("RGBA").crop((0, 48, 32, 96)), \
    Image.open("../../assets/images/lira_sheet.png").convert("RGBA").crop((0, 48, 32, 96))
party_pos = [(380, 170), (420, 214)]
for bx, by in party_pos:
    d.ellipse([bx - 9, by - 3, bx + 9, by + 2], fill=120)
img = Image.composite(Image.new("RGBA", (W, H), (*palette.RGB["night"][0], 255)), img, shadows.point(lambda a: a // 2))

for name, size, bx, by in sorted(enemies, key=lambda e: e[3]):
    sheet = Image.open(f"../../assets/images/enemies/{name}_battle.png").convert("RGBA")
    img.alpha_composite(sheet.crop((frame * size, 0, (frame + 1) * size, size)), (bx - size // 2, by - size))
for im, (bx, by) in zip(party, party_pos):
    img.alpha_composite(im, (bx - 16, by - 48))

tint = Image.new("RGB", (W, H))
td = ImageDraw.Draw(tint)
for y in range(H):
    k = 0.74 + 0.2 * min(1, y / (H * 0.6))  # darker under the canopy at the back
    td.line([(0, y), (W, y)], fill=(int(205 * k), int(225 * k), int(222 * k)))
rgb = ImageChops.multiply(img.convert("RGB"), tint)
light = Image.new("L", (W, H), 0)
ImageDraw.Draw(light).ellipse([150, 120, 360, 250], fill=34)
light = light.filter(ImageFilter.GaussianBlur(30))
rgb = ImageChops.add(rgb, ImageChops.multiply(Image.new("RGB", (W, H), palette.RGB["ember"][3]),
                                              Image.merge("RGB", [light] * 3)))
out = next((a for a in sys.argv[1:] if not a.startswith("-")), "battle_mock.png")
rgb.resize((W * 3, H * 3), Image.NEAREST).save(out)
print("battle mock written", out)
