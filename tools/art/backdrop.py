"""Battle backdrops (LH-48), 480×270 and seamless left↔right so wide
screens can repeat them.

Built from the area's own tiles and props. Depth comes from stepping
colours down their palette ramp (far layers darker), which keeps the
image palette-locked instead of tinting it.

Output:
  assets/images/backdrops/<area>.png
"""
import json
import random

from PIL import Image

import palette
from pixel import Canvas

P = palette.RGB
W, H, T = 480, 270, 16
RAMP_OF = {col: (name, i) for name, ramp in palette.RGB.items() for i, col in enumerate(ramp)}
# Where a ramp continues once it runs out of darker steps.
DARKER = {"leaf": ("teal", 0), "teal": ("night", 0), "moss": ("leaf", 1), "bark": ("night", 1),
          "dirt": ("bark", 0), "stone": ("night", 1), "ash": ("night", 1)}


def darker(col, steps):
    for _ in range(steps):
        name, i = RAMP_OF.get(col, (None, 0))
        if name is None:
            return col
        if i > 0:
            col = P[name][i - 1]
        elif name in DARKER:
            n2, j = DARKER[name]
            col = P[n2][j]
    return col


def load(path):
    img = Image.open(path).convert("RGBA")
    return img


def sprite(img, x0, y0, w, h):
    c = Canvas(w, h)
    for y in range(h):
        for x in range(w):
            r, g, b, a = img.getpixel((x0 + x, y0 + y))
            if a:
                c.set(x, y, (r, g, b))
    return c


def stamp(dst, spr, x, y, steps=0):
    """Paste with wrap-around on x (seamless edges), colours stepped darker."""
    for yy in range(spr.h):
        for xx in range(spr.w):
            col = spr.px[yy][xx]
            if col is not None and 0 <= y + yy < H:
                dst.set((x + xx) % W, y + yy, darker(col, steps))


def whisperwood_backdrop(seed=5):
    r = random.Random(seed)
    tiles_img = load("../../assets/maps/whisperwood_tiles.png")
    meta = json.load(open("../../assets/maps/whisperwood_tiles.json"))
    cols = meta["columns"]
    tile = {n: sprite(tiles_img, (i % cols) * T, (i // cols) * T, T, T) for i, n in enumerate(meta["tiles"])}
    props_img = load("../../assets/images/props/whisperwood_props.png")
    frames = json.load(open("../../assets/data/props_whisperwood.json"))
    prop = {k: sprite(props_img, f["x"], f["y"], f["w"], f["h"]) for k, f in frames.items()}

    c = Canvas(W, H)
    c.fill(P["night"][0])
    horizon = 76
    # Ground: sunlit clearing in front, stepping darker toward the trees. The
    # step is checker-dithered over a band so there is no hard seam.
    for ty in range(horizon // T, H // T + 1):
        for tx in range(W // T):
            y = ty * T
            sunny = y > horizon + 40
            name = r.choices(["floor", "floor_b", "floor_sun", "floor_sun_b"], [6, 3, 2, 2] if sunny else [6, 4, 0, 0])[0]
            stamp(c, tile[name], tx * T, y)
            if r.random() < 0.28:
                stamp(c, tile[r.choice(["grass", "grass_b", "clover", "litter", "flowers_blue", "flowers_white"])],
                      tx * T, y)
    # Two dithered steps of shade right under the trees; the fighters stand in the light.
    top = horizon // T * T  # first ground row (tiles start on the grid)
    for y in range(top, horizon + 24):
        for x in range(W):
            if y < horizon + 6 or (y < horizon + 10 and (x + y) % 2):
                steps = 2
            elif y < horizon + 18 or (y < horizon + 24 and (x + y) % 2):
                steps = 1
            else:
                steps = 0
            c.set(x, y, darker(c.px[y][x], steps))
    # Far forest wall: three rows of trees, darkest at the back.
    trees = ["big_tree", "big_tree_b", "pine", "small_tree"]
    for row, (base, steps, gap) in enumerate(((44, 3, 18), (60, 2, 22), (80, 1, 34))):
        x = r.randint(0, gap)
        while x < W:
            k = r.choice(trees)
            s = prop[k]
            stamp(c, s, x - s.w // 2, base + r.randint(-4, 4) - s.h, steps)
            x += gap + r.randint(-4, 8)
    # Undergrowth along the edge of the clearing.
    for _ in range(9):
        k = r.choice(["bush", "bush", "rock_small", "ashblight"])
        s = prop[k]
        stamp(c, s, r.randint(0, W - 1) - s.w // 2, 88 + r.randint(0, 6) - s.h, 1)
    return c


if __name__ == "__main__":
    import os
    os.makedirs("../../assets/images/backdrops", exist_ok=True)
    whisperwood_backdrop().image().save("../../assets/images/backdrops/whisperwood.png")
    print("backdrop written")
