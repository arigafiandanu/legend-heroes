"""Whisperwood art: ground/path tileset + y-sorted prop sprites (LH-48).

Output:
  assets/maps/whisperwood_tiles.png    16×16 tiles, 8 per row
  assets/maps/whisperwood_tiles.json   tile names in sheet order
  assets/images/props/whisperwood_props.png + props JSON (frames, bases)

The ground is two layers. Base tiles are opaque (grass tone variants and the
path autotile); decoration tiles are transparent (grass, flowers, clover…)
and sit on a layer above, so any decoration works on any base tone.
"""
import json
import math
import random
import zlib

import palette
from pixel import Canvas, TileNoise, shade

P = palette.RGB
LEAF, DIRT, BARK, MOSS, STONE, TEAL = P["leaf"], P["dirt"], P["bark"], P["moss"], P["stone"], P["teal"]
T = 16


def seed_of(name):
    """Stable per-name seed (str hash() changes on every Python run)."""
    return zlib.crc32(name.encode()) % 9973


def window(x, y, power=1.0):
    """1 in the middle of a tile, 0 at its border. Anything scaled by it
    leaves the tile edges untouched, so every variant tiles with every other."""
    return (math.sin(math.pi * (x + 0.5) / T) * math.sin(math.pi * (y + 0.5) / T)) ** power


def _noise(pair, x, y):
    return pair[0](x, y) * 0.6 + pair[1](x, y) * 0.4


def _own_noise(seed):
    return [TileNoise(seed, cell=8), TileNoise(seed + 1, cell=4)]


# ------------------------------------------------------------ grass base

# Shadows lean teal, sunlit grass leans warm moss (hue shifting).
FLOOR_RAMP = [TEAL[0], LEAF[1], LEAF[2], LEAF[2], LEAF[2], MOSS[0], LEAF[3]]
_FLOOR_SHARED = _own_noise(11)


def floor_tone(x, y, own=None, bump=0.0):
    """Shared noise at the tile border, the variant's own noise inside."""
    n = _noise(_FLOOR_SHARED, x, y)
    if own is not None:
        w = window(x, y, 0.5)
        n = n * (1 - w) + _noise(own, x, y) * w
    return shade(FLOOR_RAMP, 0.2 + n * 0.45 + bump, x, y)


def floor(seed, bumps=()):
    """Opaque grass. `bumps` are (cx, cy, radius, amount) sunlit (+) or
    shaded (−) patches, faded out before the tile edge."""
    own = _own_noise(seed)
    c = Canvas(T, T)
    for y in range(T):
        for x in range(T):
            b = sum(a * math.exp(-((x - cx) ** 2 + (y - cy) ** 2) / (r * r)) for cx, cy, r, a in bumps)
            c.set(x, y, floor_tone(x, y, own, b * window(x, y)))
    return c


FLOORS = {
    "floor": (),
    "floor_b": ((5, 6, 5, -0.1),),
    "floor_sun": ((9, 7, 5, 0.3),),
    "floor_sun_b": ((5, 10, 4, 0.28), (11, 4, 3, 0.2)),
    "floor_shade": ((8, 9, 6, -0.18),),
    "floor_shade_b": ((11, 6, 5, -0.16), (4, 11, 4, -0.12)),
}


# ------------------------------------------------------------ path

DIRT_RAMP = [DIRT[0], DIRT[1], DIRT[1], DIRT[1], DIRT[2]]
_DIRT_SHARED = [TileNoise(5, cell=8), TileNoise(8, cell=4)]


def dirt_tone(x, y, own):
    """Mostly mid-brown so the path stays calmer than the characters. The
    tile border is plain mid-brown and all texture lives inside, so no
    blotch lines up along the 16px grid."""
    w = window(x, y, 0.7)
    n = 0.35 * (1 - w) + _noise(own, x, y) * w
    return shade(DIRT_RAMP, 0.2 + n * 0.75, x, y)


def _profile(seed):
    """Grass depth (px) along one path edge: irregular, with a couple of
    single blades poking out. Both ends are pinned to 3 so every variant
    and corner lines up with its neighbours."""
    r = random.Random(seed)
    raw = [r.choice((2, 3, 3, 3, 4, 4, 5)) for _ in range(T)]
    depth = [round((raw[i - 1] + 2 * raw[i] + raw[(i + 1) % T]) / 4) for i in range(T)]
    for i in r.sample(range(3, 13), 2):
        depth[i] += 1
    depth[0] = depth[1] = depth[14] = depth[15] = 3
    return depth


PROFILES = {side + v: _profile(seed_of(side + v)) for side in "NSWE" for v in ("", "_b")}


def _mirror(corner, x, y):
    """Coordinates measured from `corner` (NW, NE, SW, SE) inwards."""
    return (T - 1 - x if "E" in corner else x), (T - 1 - y if "S" in corner else y)


def path_tile(sides=(), inner=(), variant="", seed=0):
    """Dirt path cell with grass along `sides` (N/S/E/W) and grass nibbles in
    `inner` corners (NE/NW/SE/SW) where only the diagonal is grass."""
    prof = {s: PROFILES[s + (variant if s in sides else "")] for s in "NSWE"}
    grass = [[False] * T for _ in range(T)]
    for y in range(T):
        for x in range(T):
            g = ("N" in sides and y < prof["N"][x]) or ("S" in sides and y > T - 1 - prof["S"][x]) \
                or ("W" in sides and x < prof["W"][y]) or ("E" in sides and x > T - 1 - prof["E"][y])
            for corner in ("NW", "NE", "SW", "SE"):
                u, v = _mirror(corner, x, y)
                if corner[0] in sides and corner[1] in sides and u < 7 and v < 7 \
                        and (6.5 - u) ** 2 + (6.5 - v) ** 2 > 3.5 ** 2:
                    g = True  # rounded outer corner
                if corner in inner and (u + 0.5) ** 2 + (v + 0.5) ** 2 < 14:
                    g = True
            grass[y][x] = g

    own = _own_noise(seed)
    c = Canvas(T, T)
    for y in range(T):
        for x in range(T):
            if grass[y][x]:
                # grass lip facing the light (dirt above or left of it)
                lit = (y > 0 and not grass[y - 1][x]) or (x > 0 and not grass[y][x - 1])
                c.set(x, y, (MOSS[0] if (x * 7 + y) % 5 == 0 else LEAF[3]) if lit else floor_tone(x, y))
            else:
                # grass above or left casts a 1px shadow onto the dirt
                shadow = (y > 0 and grass[y - 1][x]) or (x > 0 and grass[y][x - 1])
                c.set(x, y, DIRT[0] if shadow else dirt_tone(x, y, own))

    r = random.Random(seed)

    def clear(x, y, pad):
        return all(0 <= x + dx < T and 0 <= y + dy < T and not grass[y + dy][x + dx]
                   for dx in range(-pad, pad + 2) for dy in range(-pad, pad + 2))

    for _ in range(r.choice((0, 1, 1, 2))):  # a pebble or two, lit top-left
        x, y = r.randint(2, 12), r.randint(2, 12)
        if clear(x, y, 1):
            c.set(x, y, STONE[2])
            c.set(x + 1, y, STONE[1])
            c.set(x, y + 1, DIRT[0])
            c.set(x + 1, y + 1, DIRT[0])
    for _ in range(2):  # dark specks
        x, y = r.randint(1, 14), r.randint(1, 14)
        if clear(x, y, 0):
            c.set(x, y, DIRT[0])
    return c


PATH_PIECES = {
    "path": ((), ()),
    "path_n": (("N",), ()), "path_s": (("S",), ()), "path_w": (("W",), ()), "path_e": (("E",), ()),
    "path_nw": (("N", "W"), ()), "path_ne": (("N", "E"), ()),
    "path_sw": (("S", "W"), ()), "path_se": (("S", "E"), ()),
    "path_in_nw": ((), ("NW",)), "path_in_ne": ((), ("NE",)),
    "path_in_sw": ((), ("SW",)), "path_in_se": ((), ("SE",)),
}
# Extra looks for the pieces that repeat most. Pick one at random per cell.
PATH_VARIANTS = {"path": ["path_b", "path_c"], "path_n": ["path_n_b"], "path_s": ["path_s_b"],
                 "path_w": ["path_w_b"], "path_e": ["path_e_b"]}


# ------------------------------------------------------------ decorations (transparent)

def tuft(c, x, y, r, tall=False):
    """Grass tuft rooted at (x, y): blades lean outwards, tips catch light."""
    for dx in r.choice(((-1, 0, 1), (-2, -1, 0, 1), (0, 1), (-1, 0, 1, 2), (-1, 0))):
        h = r.randint(3, 5) if tall else (r.randint(3, 4) if dx == 0 else r.randint(2, 3))
        lean = (dx > 0) - (dx < 0)
        for i in range(h):
            px = x + dx + (lean if i == h - 1 and dx else 0)
            tip = i == h - 1
            c.set(px, y - i, (LEAF[4] if r.random() < 0.6 else MOSS[1]) if tip else LEAF[3])
        c.set(x + dx, y + 1, LEAF[1])


def grass(c, r, n=2, tall=False):
    spots = [(4, 7), (11, 5), (7, 13), (12, 12), (3, 12)]
    r.shuffle(spots)
    for x, y in spots[:n]:
        tuft(c, x + r.randint(-1, 1), y + r.randint(-1, 1), r, tall)


def flower(c, x, y, petal, dark):
    c.set(x, y - 1, petal)
    c.set(x - 1, y, petal)
    c.set(x + 1, y, dark)
    c.set(x, y, P["ember"][3])
    c.set(x, y + 1, LEAF[3])
    c.set(x - 1, y + 2, LEAF[4])
    c.set(x, y + 2, LEAF[3])
    c.set(x, y + 3, LEAF[1])


FLOWER_COLOURS = {"blue": (P["blue"][3], P["blue"][2]), "pink": (P["pink"][1], P["pink"][0]),
                  "white": (P["cream"][1], P["cream"][0])}


def flowers(colour):
    def draw(c, r):
        petal, dark = FLOWER_COLOURS[colour]
        spots = [(4, 4), (10, 6), (6, 11), (12, 11)]
        r.shuffle(spots)
        for x, y in spots[:3]:
            flower(c, x + r.randint(-1, 1), y, petal, dark)
        tuft(c, 8, 13, r)
    return draw


CLOVER = [".ab.", "abba", ".bc."]


def clover(c, r):
    for x, y in ((2, 3), (9, 5), (5, 10), (11, 11)):
        if r.random() < 0.8:
            c.stamp(CLOVER, {"a": MOSS[1], "b": MOSS[0], "c": LEAF[1]}, x, y)


FROND = [
    "..a.....a..",
    ".ab.....ba.",
    "..ab...ba..",
    "a..ab.ba..a",
    ".bb.bbb.bb.",
    "...bbcbb...",
    ".....c.....",
]


def ferns(c, r):
    c.stamp(FROND, {"a": LEAF[4], "b": LEAF[3], "c": LEAF[1]}, 2, 5, flip=r.random() < 0.5)


def mushrooms(c, r):
    for x, y in ((4, 8), (10, 5)):
        c.stamp(["abba.", "bbcbb", ".ddd.", "..d..", ".eee."],
                {"a": P["red"][2], "b": P["red"][1], "c": P["cream"][1], "d": P["cream"][0], "e": LEAF[1]},
                x - 2, y - 2)


def litter(c, r):
    """Fallen leaves: small two-tone ovals."""
    for _ in range(3):
        x, y = r.randint(2, 12), r.randint(2, 12)
        light, dark = r.choice(((P["ember"][1], P["ember"][0]), (BARK[3], BARK[2]), (MOSS[2], MOSS[1])))
        c.set(x, y, light)
        c.set(x + 1, y, dark if r.random() < 0.5 else light)
        c.set(x + 1, y + 1, dark)
        c.set(x, y + 1, LEAF[1])


def pebbles(c, r):
    for _ in range(3):
        x, y = r.randint(2, 12), r.randint(2, 12)
        c.set(x, y, STONE[3])
        c.set(x + 1, y, STONE[2])
        c.set(x, y + 1, STONE[1])
        c.set(x + 1, y + 1, STONE[1])
        c.set(x + 1, y + 2, LEAF[1])
        c.set(x, y + 2, LEAF[1])


def twig(c, r):
    x0, y0 = r.randint(2, 4), r.randint(7, 10)
    for i in range(9):
        x, y = x0 + i, y0 + (i // 4)
        c.set(x, y, BARK[3] if i % 3 else BARK[2])
        c.set(x, y + 1, BARK[1])
    c.set(x0 + 5, y0 - 1, BARK[2])
    c.set(x0 + 6, y0 - 2, BARK[3])


DECOR = {
    "grass": lambda c, r: grass(c, r, 2),
    "grass_b": lambda c, r: grass(c, r, 3),
    "grass_tall": lambda c, r: grass(c, r, 2, tall=True),
    "flowers_blue": flowers("blue"),
    "flowers_pink": flowers("pink"),
    "flowers_white": flowers("white"),
    "clover": clover,
    "ferns": ferns,
    "mushrooms": mushrooms,
    "litter": litter,
    "pebbles": pebbles,
    "twig": twig,
}


def ground_tiles():
    tiles = [(name, floor(seed_of(name), bumps)) for name, bumps in FLOORS.items()]
    tiles += [(name, path_tile(sides, inner, "", seed_of(name))) for name, (sides, inner) in PATH_PIECES.items()]
    for base, variants in PATH_VARIANTS.items():
        sides, inner = PATH_PIECES[base]
        tiles += [(v, path_tile(sides, inner, "_b" if sides else "", seed_of(v))) for v in variants]
    for name, draw in DECOR.items():
        c = Canvas(T, T)
        draw(c, random.Random(seed_of(name)))
        tiles.append((name, c))
    return tiles


def build_tiles(png, meta, cols=8):
    tiles = ground_tiles()
    rows = (len(tiles) + cols - 1) // cols
    sheet = Canvas(cols * T, rows * T)
    for i, (_, t) in enumerate(tiles):
        sheet.paste(t, (i % cols) * T, (i // cols) * T)
    sheet.image().save(png)
    names = [name for name, _ in tiles]
    with open(meta, "w") as f:
        json.dump({"columns": cols, "tiles": names, "decor": list(DECOR), "variants": PATH_VARIANTS}, f, indent=1)
    return names


# ------------------------------------------------------------ props

# Whisperwood canopies: deep teal shadows, restrained highlights.
CANOPY = [TEAL[0], LEAF[1], LEAF[2], LEAF[3], LEAF[4]]


def canopy(c, clusters, r, ramp=CANOPY, size=(3.5, 5.5)):
    """Foliage made of many small leaf clumps, each lit from the top-left.

    Clumps are drawn top to bottom, so every lower clump's bright top edge
    overlaps the shaded underside of the one above: that is what makes the
    canopy read as layered leaves instead of one shaded ball. `clusters` are
    (cx, cy, rx, ry, bias) ellipses the clumps are scattered in."""
    clumps = []
    for cx, cy, rx, ry, bias in clusters:
        for _ in range(int(rx * ry / 8) + 2):
            a, d = r.uniform(0, 2 * math.pi), math.sqrt(r.random())
            clumps.append((cy + math.sin(a) * d * max(1, ry - 3), cx + math.cos(a) * d * max(1, rx - 3),
                           r.uniform(*size), bias))
    top, bottom = min(q[0] - q[2] for q in clumps), max(q[0] + q[2] for q in clumps)
    left, right = min(q[1] - q[2] for q in clumps), max(q[1] + q[2] for q in clumps)
    for py, px, rr, bias in sorted(clumps):
        g = bias - 0.04 + 0.3 * (0.5 - (py - top) / (bottom - top)) + 0.14 * (0.5 - (px - left) / (right - left))
        for y in range(math.floor(py - rr), math.ceil(py + rr) + 1):
            for x in range(math.floor(px - rr), math.ceil(px + rr) + 1):
                dx, dy = (x + 0.5 - px) / rr, (y + 0.5 - py) / rr
                d = dx * dx + dy * dy
                if d <= 1:
                    light = 0.5 + (-dx * 0.4 - dy * 0.65) * 0.5 - d * 0.12 + g
                    c.set(x, y, shade(ramp, light, x, y, dither=False))
    # a few sun-catching leaves on the top rim
    for y in range(c.h):
        for x in range(c.w):
            if c.get(x, y) == ramp[-1] and c.get(x, y - 1) is None and r.random() < 0.35:
                c.set(x, y, LEAF[5])


def trunk(c, cx, top, bottom, half, flare=7):
    """Bark lit from the left with broken vertical grooves and flared roots."""
    for y in range(top, bottom + 1):
        k = max(0, y - (bottom - flare)) / flare
        hw = half + k ** 1.6 * 6
        for x in range(round(cx - hw), round(cx + hw) + 1):
            off = x - cx
            if y >= bottom - 2 and abs(abs(off) - hw * 0.5) < 0.8:
                continue  # gap between roots
            u = (x + 0.5 - (cx - hw)) / (2 * hw + 1)
            t = 0.95 - u * 0.85
            if round(off) in (-2, 1) and (y * 5 + x) % 9 > 1:
                t -= 0.28
            if y < top + 4:
                t -= 0.3  # the canopy shades the top of the trunk
            c.set(x, y, shade(BARK, t, x, y, dither=False))


def branch(c, x0, y0, x1, y1):
    n = max(abs(x1 - x0), abs(y1 - y0))
    for i in range(n + 1):
        x, y = round(x0 + (x1 - x0) * i / n), round(y0 + (y1 - y0) * i / n)
        c.set(x, y, BARK[2])
        c.set(x + 1, y, BARK[1])


def big_tree(seed):
    """48×64 oak: layered leaf clumps and a flared trunk."""
    c = Canvas(48, 64)
    r = random.Random(seed)
    trunk(c, 24, 34, 62, 4)
    branch(c, 23, 38, 14, 28)
    branch(c, 26, 37, 34, 29)
    canopy(c, [(24, 31, 16, 7, -0.12), (12, 25, 9, 8, -0.02), (36, 25, 9, 8, -0.06),
               (24, 20, 15, 10, 0.02), (16, 13, 9, 7, 0.08), (32, 13, 9, 7, 0.05), (24, 10, 8, 5, 0.1)], r)
    c.outline()
    return c


def big_tree_b(seed):
    """48×64 oak leaning left, with a gap that shows a branch."""
    c = Canvas(48, 64)
    r = random.Random(seed)
    trunk(c, 25, 36, 62, 4)
    branch(c, 24, 40, 12, 30)
    branch(c, 27, 40, 37, 33)
    canopy(c, [(22, 30, 14, 7, -0.1), (36, 28, 8, 6, -0.08), (11, 23, 8, 7, 0.0),
               (25, 20, 14, 9, 0.04), (17, 12, 8, 6, 0.1), (32, 13, 7, 6, 0.06)], r)
    c.outline()
    return c


def small_tree(seed):
    c = Canvas(32, 48)
    r = random.Random(seed)
    trunk(c, 16, 26, 46, 2.5, flare=4)
    canopy(c, [(16, 24, 10, 5, -0.12), (16, 16, 10, 7, 0.0), (15, 10, 6, 4, 0.1)], r, size=(3, 4.5))
    c.outline()
    return c


PINE = [TEAL[0], LEAF[1], TEAL[1], LEAF[2], LEAF[3]]


def pine(seed):
    """32×56 conifer: drooping tiers, upper tiers drape over lower ones."""
    c = Canvas(32, 56)
    trunk(c, 16, 44, 54, 2, flare=3)
    tiers = [(3, 16, 6), (10, 26, 9), (18, 36, 12), (27, 46, 14)]  # top, bottom, half width
    for top, bottom, half in reversed(tiers):
        for x in range(round(16 - half), round(16 + half) + 1):
            off = (x + 0.5 - 16) / half
            if abs(off) > 1:
                continue
            droop = bottom - 2 * abs(math.sin((x + 1) * math.pi / 5)) - abs(off) * 2
            for y in range(top, math.ceil(droop) + 1):
                v = (y - top) / (bottom - top)
                if abs(off) > v ** 0.8 + 0.08:
                    continue  # outside the cone
                t = 0.62 - off * 0.3 - v * 0.35
                if y >= droop - 1:
                    t -= 0.2  # underside of the tier
                c.set(x, y, shade(PINE, t, x, y, dither=False))
    c.set(16, 2, LEAF[4])
    c.outline()
    return c


def bush(seed):
    c = Canvas(32, 24)
    r = random.Random(seed)
    canopy(c, [(10, 15, 7, 5, -0.02), (22, 15, 7, 5, -0.06), (16, 11, 9, 5, 0.1)], r,
           ramp=[LEAF[1], LEAF[2], LEAF[3], LEAF[4]], size=(3, 4.5))
    for x, y in ((9, 10), (19, 8), (23, 13), (13, 15)):
        if c.get(x, y) is not None:
            c.set(x, y, P["pink"][1])
            c.set(x + 1, y + 1, P["pink"][0])
    c.outline()
    return c


def _inside(poly, x, y):
    inside = False
    for (x0, y0), (x1, y1) in zip(poly, poly[1:] + poly[:1]):
        if (y0 > y) != (y1 > y) and x < x0 + (y - y0) * (x1 - x0) / (y1 - y0):
            inside = not inside
    return inside


def boulder(w, h, poly, ridge, split, seed, moss=0.5, crack=()):
    """Faceted rock: a lit top plane, a front face and a dark right face,
    with moss on top so it sits in the forest instead of looking like metal.
    `ridge(x)` is where the top plane ends; `split(y)` where the right face starts."""
    c = Canvas(w, h)
    r = random.Random(seed)
    mask = {(x, y) for y in range(h) for x in range(w) if _inside(poly, x + 0.5, y + 0.5)}
    noise = TileNoise(seed, period=16, cell=4)
    for x, y in mask:
        edge_tl = (x - 1, y) not in mask or (x, y - 1) not in mask
        if x + 0.5 > split(y):
            col = STONE[1] if (x - 1, y) in mask and x - 0.5 <= split(y) else STONE[0]
        elif y + 0.5 < ridge(x):
            col = STONE[3] if edge_tl and r.random() < 0.6 else STONE[2]
            if noise(x, y) < moss:
                col = MOSS[2] if edge_tl else (MOSS[1] if noise(x + 3, y) > 0.35 else MOSS[0])
        else:
            # front face: a lighter band on the lit left side (no dither on small sprites)
            lit = 1 - (x - poly[1][0]) / (split(y) - poly[1][0])
            col = STONE[2] if edge_tl or lit > 0.62 else STONE[1]
        c.set(x, y, col)
    for x in range(w):  # moss dripping over the ridge in a few columns
        ys = [y for y in range(h) if (x, y) in mask and y + 0.5 >= ridge(x) and x + 0.5 <= split(y)]
        if ys and c.get(x, ys[0] - 1) in (MOSS[0], MOSS[1]) and r.random() < 0.5:
            c.set(x, ys[0], MOSS[0])
    for x, y in crack:  # dark crack with a lit lower-left lip
        if (x, y) in mask:
            c.set(x, y, STONE[0])
            if (x - 1, y + 1) in mask and c.get(x - 1, y + 1) != STONE[0]:
                c.set(x - 1, y + 1, STONE[2])
    c.outline()
    return c


def rock(seed):
    return boulder(24, 18, [(2, 16), (1, 12), (2.5, 8), (6, 4.5), (11, 2.5), (16, 3), (20, 6), (22, 10),
                            (21.5, 14), (20, 16)],
                   lambda x: 9 - 0.14 * x, lambda y: 16 + (y - 6) * 0.3, seed, moss=0.5,
                   crack=((11, 9), (11, 10), (12, 11), (12, 12), (11, 13)))


def rock_small(seed):
    return boulder(16, 12, [(1.5, 10.5), (1.5, 7), (4, 4), (8, 2.5), (12, 3.5), (14.5, 7), (14, 10.5)],
                   lambda x: 6 - 0.1 * x, lambda y: 10.5 + (y - 4) * 0.3, seed, moss=0.35)


def log(seed):
    c = Canvas(40, 18)
    for y in range(4, 15):
        for x in range(3, 34):
            t = 0.9 - abs(y - 7) / 8
            if (y in (6, 10, 12) and (x * 3 + y) % 11 > 2) or (x + y * 5) % 13 == 0:
                t -= 0.25  # grain
            c.set(x, y, shade(BARK, t, x, y, dither=False))
    c.blob(35, 9.5, 4, 5.5, [BARK[1], BARK[2], DIRT[2], DIRT[3]], bias=0.2)
    for dx, dy in ((0, -2), (1, -2), (-1, 0), (2, 1), (0, 2), (1, 2)):
        c.set(35 + dx, 9 + dy, DIRT[1])  # growth ring
    c.set(35, 9, BARK[1])
    for x in range(6, 22, 3):
        c.set(x, 4, MOSS[2])
        c.set(x + 1, 4, MOSS[1])
        c.set(x + 1, 5, MOSS[0])
    c.outline()
    return c


def stump(seed):
    c = Canvas(20, 18)
    for y in range(6, 16):
        for x in range(3, 17):
            t = 0.95 - (x - 3) / 15
            if x in (6, 11) and y % 4:
                t -= 0.25
            c.set(x, y, shade(BARK, t, x, y, dither=False))
    c.blob(10, 6, 7, 3, [DIRT[1], DIRT[2], DIRT[3]], bias=0.15)
    for dx in range(-3, 4):
        c.set(10 + dx, 6 + (abs(dx) == 3), DIRT[1])  # growth ring
    c.set(10, 6, BARK[1])
    c.set(5, 5, MOSS[1])
    c.set(6, 5, MOSS[2])
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
    "big_tree_b": (big_tree_b, (-7, -8, 14, 8)),
    "small_tree": (small_tree, (-4, -6, 8, 6)),
    "pine": (pine, (-4, -6, 8, 6)),
    "bush": (bush, (-12, -8, 24, 8)),
    "rock": (rock, (-9, -8, 18, 8)),
    "rock_small": (rock_small, (-6, -5, 12, 5)),
    "log": (log, (-17, -8, 34, 7)),
    "stump": (stump, (-6, -6, 12, 6)),
    "ashblight": (ashblight, (-6, -5, 12, 5)),
    "signpost": (signpost, (-3, -5, 6, 5)),
}


def build_props(png, meta):
    sprites = {name: fn(seed_of(name)) for name, (fn, _) in PROPS.items()}
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
    names = build_tiles("../../assets/maps/whisperwood_tiles.png", "../../assets/maps/whisperwood_tiles.json")
    frames = build_props("../../assets/images/props/whisperwood_props.png", "../../assets/data/props_whisperwood.json")
    print(len(names), "tiles;", len(frames), "props")
