"""Whisperwood art: ground/path tileset + y-sorted prop sprites (LH-48).

Output:
  assets/maps/whisperwood_tiles.png   16×16 ground + 13-piece path autotile
  assets/images/props/whisperwood_props.png + props JSON (frames, bases)
"""
import json
import math
import random

import palette
from pixel import Canvas, TileNoise, shade

P = palette.RGB
LEAF, DIRT, BARK, MOSS = P["leaf"], P["dirt"], P["bark"], P["moss"]
T = 16


# ------------------------------------------------------------ ground

def floor_color(x, y, seed):
    """Forest floor: mid green with dark hollows and lighter patches."""
    n = TileNoise(seed, cell=8)(x, y) * 0.65 + TileNoise(seed + 1, cell=4)(x, y) * 0.35
    ramp = [LEAF[1], LEAF[2], LEAF[2], LEAF[2]]
    return shade(ramp, n * 0.95, x, y)


TUFT = ["a.a", "a.a"]
TUFT2 = [".a.", "a.a", "a.."]


def floor(seed, tufts=2, extras=None):
    c = Canvas(T, T)
    for y in range(T):
        for x in range(T):
            c.set(x, y, floor_color(x, y, seed))
    r = random.Random(seed)
    spots = [(2, 3), (9, 2), (4, 10), (11, 11), (7, 6)]
    r.shuffle(spots)
    for (x, y) in spots[:tufts]:
        c.stamp(r.choice([TUFT, TUFT2]), {"a": LEAF[3]}, x, y)
    if extras:
        extras(c, r)
    return c


def litter(c, r):
    for _ in range(2):
        x, y = r.randint(1, 13), r.randint(1, 13)
        col = r.choice([P["ember"][0], DIRT[2], BARK[3]])
        c.set(x, y, col)
        c.set(x + 1, y, col)
        c.set(x, y + 1, DIRT[0])


def flowers(c, r):
    for x, y in ((3, 4), (10, 7), (6, 12)):
        for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
            c.set(x + dx, y + dy, P["blue"][3])
        c.set(x, y, P["cream"][1])
        c.set(x, y + 2, LEAF[1])


def mushrooms(c, r):
    for x, y in ((4, 8), (10, 5)):
        c.stamp(["abba.", "bbcbb", ".ddd.", "..d..", ".eee."],
                {"a": P["red"][2], "b": P["red"][1], "c": P["cream"][1], "d": P["cream"][0], "e": LEAF[0]},
                x - 2, y - 2)


CLOVER = [".ab.", "abba", ".bc."]


def moss_patch(seed):
    """A few small clover clumps rather than one blob."""
    c = floor(seed, tufts=0)
    for x, y in ((2, 3), (9, 5), (5, 10), (11, 11)):
        c.stamp(CLOVER, {"a": MOSS[1], "b": MOSS[0], "c": LEAF[1]}, x, y)
    return c


def ferns(seed):
    c = floor(seed, tufts=0)
    frond = [
        "..a.....a..",
        ".ab.....ba.",
        "..ab...ba..",
        "a..ab.ba..a",
        ".bb.bbb.bb.",
        "...bbcbb...",
        ".....c.....",
    ]
    c.stamp(frond, {"a": LEAF[4], "b": LEAF[3], "c": LEAF[1]}, 2, 5)
    return c


# ------------------------------------------------------------- path

_PEBBLES = {(3, 5), (12, 2), (9, 11), (1, 13), (14, 9)}


def dirt_color(x, y, seed=5):
    n = TileNoise(seed, cell=8)(x, y) * 0.7 + TileNoise(seed + 3, cell=4)(x, y) * 0.3
    c = shade([DIRT[1], DIRT[1], DIRT[2]], 0.15 + n * 0.75, x, y)
    if (x, y) in _PEBBLES:
        return P["stone"][3]
    if (x - 1, y - 1) in _PEBBLES or (x, y - 1) in _PEBBLES:
        return DIRT[0]
    return c


def edge_depth(t):
    """Grass overhang depth along an edge; period 8 so neighbours line up."""
    return 3 + round(1.2 * math.sin(t * 2 * math.pi / 8 + 0.6))


def path_tile(sides=(), inner=()):
    """Dirt path cell with grass along `sides` (N/S/E/W) and grass nibbles in
    `inner` corners (NE/NW/SE/SW) where only the diagonal is grass."""
    grass = [[False] * T for _ in range(T)]
    for y in range(T):
        for x in range(T):
            g = ("N" in sides and y < edge_depth(x)) or ("S" in sides and y > 15 - edge_depth(x + 3)) \
                or ("W" in sides and x < edge_depth(y + 5)) or ("E" in sides and x > 15 - edge_depth(y + 2))
            for corner, (cx, cy) in {"NE": (16, 0), "NW": (0, 0), "SE": (16, 16), "SW": (0, 16)}.items():
                if corner in inner and (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 < 15:
                    g = True
            grass[y][x] = g
    c = Canvas(T, T)
    for y in range(T):
        for x in range(T):
            if grass[y][x]:
                c.set(x, y, floor_color(x, y, 11))
            else:
                shadow = (y > 0 and grass[y - 1][x]) or (x > 0 and grass[y][x - 1])
                c.set(x, y, DIRT[0] if shadow else dirt_color(x, y))
    return c


PATH_PIECES = {
    "path": ((), ()),
    "path_n": (("N",), ()), "path_s": (("S",), ()), "path_w": (("W",), ()), "path_e": (("E",), ()),
    "path_nw": (("N", "W"), ()), "path_ne": (("N", "E"), ()),
    "path_sw": (("S", "W"), ()), "path_se": (("S", "E"), ()),
    "path_in_nw": ((), ("NW",)), "path_in_ne": ((), ("NE",)),
    "path_in_sw": ((), ("SW",)), "path_in_se": ((), ("SE",)),
}


def build_tiles(path):
    tiles = [
        ("floor", floor(11, tufts=1)), ("floor2", floor(12, tufts=2)), ("floor3", floor(13, tufts=0)),
        ("moss", moss_patch(14)), ("flowers", floor(15, tufts=1, extras=flowers)), ("ferns", ferns(16)),
        ("mushrooms", floor(17, tufts=0, extras=mushrooms)), ("litter", floor(18, tufts=0, extras=litter)),
    ] + [(name, path_tile(*args)) for name, args in PATH_PIECES.items()]
    cols = 8
    rows = (len(tiles) + cols - 1) // cols
    sheet = Canvas(cols * T, rows * T)
    for i, (_, t) in enumerate(tiles):
        sheet.paste(t, (i % cols) * T, (i // cols) * T)
    sheet.image().save(path)
    return [name for name, _ in tiles]


# ------------------------------------------------------------ props

# Whisperwood canopies: deep teal shadows, restrained highlights.
CANOPY = [P["teal"][0], LEAF[1], LEAF[2], LEAF[3], LEAF[4]]

def big_tree(seed):
    """48×64 oak: layered leaf clusters lit from the top-left, flared trunk."""
    c = Canvas(48, 64)
    r = random.Random(seed)
    bark = [BARK[0], BARK[1], BARK[2], BARK[3]]
    # trunk + roots
    for y in range(34, 62):
        half = 4 + (max(0, y - 54) ** 1.3) * 0.9
        for x in range(int(24 - half), int(24 + half) + 1):
            t = 0.85 - (x - (24 - half)) / (2 * half + 1) * 0.8
            if (x * 3 + y // 3) % 7 == 0:
                t -= 0.3
            c.set(x, y, shade(bark, t, x, y, dither=False))
    for x in range(19, 30):
        c.set(x, 35, BARK[0])  # shade under the canopy
    canopy = CANOPY
    clusters = [(24, 33, 15, 8, -0.3), (12, 27, 10, 9, -0.2), (36, 27, 10, 9, -0.25),
                (24, 22, 17, 13, -0.12), (15, 14, 10, 9, -0.02), (33, 14, 10, 9, -0.08), (24, 9, 11, 8, 0.04)]
    for cx, cy, rx, ry, bias in clusters:
        c.blob(cx + r.uniform(-1, 1), cy, rx, ry, canopy, bias=bias, rng=r, jitter=0.12)
    # leaf texture: short dark arcs under lit clumps
    for _ in range(30):
        x, y = r.randint(8, 40), r.randint(6, 36)
        if c.get(x, y) in (LEAF[2], LEAF[3]) and c.get(x, y + 1) in (LEAF[2], LEAF[3]):
            c.set(x, y + 1, LEAF[1])
            c.set(x + 1, y + 1, LEAF[1])
            if c.get(x - 1, y) == LEAF[3]:
                c.set(x - 1, y, LEAF[4])
    c.outline()
    return c


def small_tree(seed):
    c = Canvas(32, 48)
    r = random.Random(seed)
    for y in range(26, 46):
        for x in range(13, 19):
            c.set(x, y, shade([BARK[0], BARK[1], BARK[2], BARK[3]], 0.9 - (x - 13) / 7, x, y, dither=False))
    canopy = CANOPY
    for cx, cy, rx, ry, bias in [(16, 24, 11, 7, -0.25), (16, 16, 13, 10, -0.1), (12, 9, 7, 6, 0.0), (20, 10, 7, 6, -0.05)]:
        c.blob(cx, cy, rx, ry, canopy, bias=bias, rng=r, jitter=0.12)
    c.outline()
    return c


def bush(seed):
    c = Canvas(32, 24)
    r = random.Random(seed)
    for cx, cy, rx, ry, b in [(10, 15, 8, 7, -0.05), (22, 15, 8, 7, -0.1), (16, 11, 10, 8, 0.08)]:
        c.blob(cx, cy, rx, ry, [LEAF[1], LEAF[2], LEAF[3], LEAF[4]], bias=b, rng=r, jitter=0.1)
    for x, y in ((9, 10), (19, 8), (23, 13)):
        c.set(x, y, P["pink"][1])
    c.outline()
    return c


def rock(seed):
    c = Canvas(24, 20)
    r = random.Random(seed)
    c.blob(12, 12, 10, 7, P["stone"][:4], bias=0.05, rng=r, jitter=0.08)
    c.blob(8, 9, 5, 4, P["stone"][1:5], bias=0.1)
    for x in range(6, 12):
        if c.get(x, 16):
            c.set(x, 16, MOSS[1])
    c.outline()
    return c


def log(seed):
    c = Canvas(40, 18)
    for y in range(4, 15):
        for x in range(3, 34):
            t = 0.9 - abs(y - 7) / 8
            if (x + y * 5) % 9 == 0:
                t -= 0.25
            c.set(x, y, shade([BARK[0], BARK[1], BARK[2], BARK[3]], t, x, y, dither=False))
    c.blob(35, 9.5, 4, 5.5, [BARK[1], BARK[2], DIRT[2], DIRT[3]], bias=0.2)
    c.set(35, 9, BARK[1])
    c.set(36, 10, BARK[1])
    for x in range(6, 20, 3):
        c.set(x, 4, MOSS[2])
        c.set(x + 1, 4, MOSS[1])
    c.outline()
    return c


def stump(seed):
    c = Canvas(20, 18)
    for y in range(6, 16):
        for x in range(3, 17):
            c.set(x, y, shade([BARK[0], BARK[1], BARK[2], BARK[3]], 0.95 - (x - 3) / 15, x, y, dither=False))
    c.blob(10, 6, 7, 3, [DIRT[1], DIRT[2], DIRT[3]], bias=0.15)
    c.set(10, 6, DIRT[1])
    c.set(9, 6, DIRT[1])
    c.outline()
    return c


def ashblight(seed):
    """Blighted plant: ash-purple leaves with glowing ember cracks."""
    c = Canvas(24, 26)
    r = random.Random(seed)
    for cx, cy, rx, ry, b in [(8, 16, 6, 7, 0.0), (16, 15, 6, 8, -0.05), (12, 9, 5, 7, 0.1)]:
        c.blob(cx, cy, rx, ry, P["ash"], bias=b, rng=r, jitter=0.1)
    for x, y in ((12, 8), (12, 9), (11, 10), (12, 11), (8, 15), (9, 16), (16, 13), (15, 14), (16, 15)):
        c.set(x, y, P["ember"][1] if (x + y) % 2 else P["ember"][3])
    c.outline()
    return c


def signpost(seed):
    c = Canvas(18, 24)
    for y in range(9, 23):
        c.set(8, y, BARK[1])
        c.set(9, y, BARK[2])
    for y in range(3, 10):
        for x in range(2, 16):
            c.set(x, y, shade([BARK[1], BARK[2], BARK[3]], 0.9 - (y - 3) / 10, x, y, dither=False))
    for x in range(4, 13, 2):
        c.set(x, 6, BARK[0])
    c.outline()
    return c


# name: (sprite fn, collision box relative to the sprite's bottom-centre base: x, y, w, h)
PROPS = {
    "big_tree": (big_tree, (-7, -8, 14, 8)),
    "small_tree": (small_tree, (-4, -6, 8, 6)),
    "bush": (bush, (-12, -8, 24, 8)),
    "rock": (rock, (-9, -8, 18, 8)),
    "log": (log, (-17, -8, 34, 7)),
    "stump": (stump, (-6, -6, 12, 6)),
    "ashblight": (ashblight, (-6, -5, 12, 5)),
    "signpost": (signpost, (-3, -5, 6, 5)),
}


def build_props(png, meta):
    sprites = {name: fn(hash(name) % 997) for name, (fn, _) in PROPS.items()}
    width = sum(s.w for s in sprites.values()) + 2 * len(sprites)
    height = max(s.h for s in sprites.values())
    sheet = Canvas(width, height)
    frames, x = {}, 0
    for name, s in sprites.items():
        sheet.paste(s, x, height - s.h)
        bx, by, bw, bh = PROPS[name][1]
        frames[name] = {"x": x, "y": height - s.h, "w": s.w, "h": s.h, "solid": [bx, by, bw, bh]}
        x += s.w + 2
    sheet.image().save(png)
    with open(meta, "w") as f:
        json.dump(frames, f, indent=1)
    return frames


if __name__ == "__main__":
    import os
    os.makedirs("../../assets/images/props", exist_ok=True)
    names = build_tiles("../../assets/maps/whisperwood_tiles.png")
    frames = build_props("../../assets/images/props/whisperwood_props.png", "../../assets/data/props_whisperwood.json")
    print(len(names), "tiles;", len(frames), "props")
