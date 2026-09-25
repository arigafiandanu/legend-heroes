"""Hollowmere art: village tileset + y-sorted prop sprites (LH-48).

Mood (art bible §8): warm and safe — brighter grass, warm dirt roads,
cream walls, red roofs, ember lanterns.

Output:
  assets/maps/hollowmere_tiles.png + .json   base tiles (grass, road, plaza,
      pond and temple floor with 13-piece grass edges) and decor tiles
  assets/images/props/hollowmere_props.png   houses, shop, temple, trees,
  assets/data/props_hollowmere.json          lanterns, barrels… (+ glows)
"""
import json
import random

import palette
import whisperwood as ww
from pixel import Canvas, TileNoise, shade

P = palette.RGB
LEAF, DIRT, BARK, MOSS, STONE = P["leaf"], P["dirt"], P["bark"], P["moss"], P["stone"]
RED, EMBER, CREAM, BLUE = P["red"], P["ember"], P["cream"], P["blue"]
T = 16

# ------------------------------------------------------------ ground

GRASS_RAMP = [LEAF[1], LEAF[2], LEAF[3], LEAF[3], LEAF[3], MOSS[1], LEAF[4]]
_GRASS_SHARED = ww._own_noise(31)


def grass_tone(x, y, own=None, bump=0.0):
    n = ww._noise(_GRASS_SHARED, x, y)
    if own is not None:
        w = ww.window(x, y, 0.5)
        n = n * (1 - w) + ww._noise(own, x, y) * w
    return shade(GRASS_RAMP, 0.2 + n * 0.45 + bump, x, y)


def grass(seed, bumps=()):
    import math
    own = ww._own_noise(seed)
    c = Canvas(T, T)
    for y in range(T):
        for x in range(T):
            b = sum(a * math.exp(-((x - cx) ** 2 + (y - cy) ** 2) / (r * r)) for cx, cy, r, a in bumps)
            c.set(x, y, grass_tone(x, y, own, b * ww.window(x, y)))
    return c


GRASSES = {
    "grass": (),
    "grass_b": ((5, 6, 5, -0.12),),
    "grass_sun": ((9, 7, 5, 0.25),),
    "grass_sun_b": ((5, 10, 4, 0.22), (11, 4, 3, 0.18)),
}

ROAD_RAMP = [DIRT[1], DIRT[2], DIRT[2], DIRT[2], DIRT[3]]


def road_fill(x, y, own):
    """Warm, well-trodden dirt: lighter than the forest trail."""
    w = ww.window(x, y, 0.7)
    n = 0.4 * (1 - w) + ww._noise(own, x, y) * w
    return shade(ROAD_RAMP, 0.2 + n * 0.7, x, y)


def cobble_fill(x, y, own):
    """Paving: 8×4 stones in staggered rows (repeats every 16 px), each lit
    top-left, with dark mortar joints."""
    row = y // 4
    bx = (x + (row % 2) * 4) % 8
    if y % 4 == 3 or bx == 7:
        return STONE[1]
    stone = (row * 5 + (x + (row % 2) * 4) // 8 * 3) % 7
    base = [CREAM[0], STONE[3], CREAM[0], STONE[2], CREAM[0], STONE[3], CREAM[0]][stone]
    if bx == 0 or y % 4 == 0:
        return CREAM[1] if base == CREAM[0] else STONE[4] if base == STONE[3] else STONE[3]
    if y % 4 == 2 and bx >= 5:
        return STONE[2] if base != STONE[2] else STONE[1]
    return base


WATER_RAMP = [BLUE[0], BLUE[1], BLUE[1], BLUE[2]]
_WATER = [TileNoise(41, cell=8), TileNoise(42, cell=4)]


def water_fill(x, y, own):
    n = ww._noise(_WATER, x, y)
    if (x * 3 + y * 7) % 29 == 0 or (x * 3 + y * 7) % 29 == 3:
        return BLUE[3]  # glints
    return shade(WATER_RAMP, 0.25 + n * 0.6, x, y)


def temple_floor():
    """Cream stone slabs, 8×8, lit top-left."""
    c = Canvas(T, T)
    for y in range(T):
        for x in range(T):
            if x % 8 == 7 or y % 8 == 7:
                col = STONE[2]
            elif x % 8 == 0 or y % 8 == 0:
                col = CREAM[1]
            else:
                col = CREAM[0] if (x * 5 + y * 3) % 23 else STONE[3]
            c.set(x, y, col)
    return c


def fence():
    """Transparent decor tile: two rails and one post; repeats seamlessly."""
    c = Canvas(T, T)
    for y, (top, body) in ((6, (BARK[3], BARK[2])), (10, (BARK[3], BARK[2]))):
        for x in range(T):
            c.set(x, y, top)
            c.set(x, y + 1, body)
    for y in range(3, 15):
        c.set(7, y, BARK[3] if y > 3 else DIRT[3])
        c.set(8, y, BARK[1])
    c.outline()
    return c


def flower_bed(c, r):
    for x, y in ((3, 5), (7, 3), (11, 6), (5, 10), (10, 11), (13, 9)):
        petal, dark = r.choice(list(ww.FLOWER_COLOURS.values()) + [(RED[2], RED[1]), (EMBER[3], EMBER[2])])
        ww.flower(c, x, y, petal, dark)


SURFACES = {
    "road": dict(fill=road_fill),
    "plaza": dict(fill=cobble_fill, shadow=STONE[1], specks=False),
    "water": dict(fill=water_fill, shadow=BLUE[0], specks=False),
}
LIP = (LEAF[4], MOSS[1])
DECOR = {
    "tuft": lambda c, r: ww.grass(c, r, 2),
    "tuft_b": lambda c, r: ww.grass(c, r, 3),
    "flowers_blue": ww.flowers("blue"),
    "flowers_pink": ww.flowers("pink"),
    "flowers_white": ww.flowers("white"),
    "flower_bed": flower_bed,
    "clover": ww.clover,
    "pebbles": ww.pebbles,
}


def surface_name(surface, piece):
    return surface + piece[len("path"):]


def ground_tiles():
    tiles = [(name, grass(ww.seed_of("h_" + name), bumps)) for name, bumps in GRASSES.items()]
    for surface, kw in SURFACES.items():
        for piece, (sides, inner) in ww.PATH_PIECES.items():
            name = surface_name(surface, piece)
            tiles.append((name, ww.path_tile(sides, inner, "", ww.seed_of("h_" + name), grass_tone=grass_tone,
                                             lip=LIP, **kw)))
    tiles.append(("road_b", ww.path_tile((), (), "", ww.seed_of("h_road_b"), grass_tone=grass_tone, lip=LIP,
                                         fill=road_fill)))
    tiles.append(("temple_floor", temple_floor()))
    tiles.append(("fence", fence()))
    for name, draw in DECOR.items():
        c = Canvas(T, T)
        draw(c, random.Random(ww.seed_of("h_" + name)))
        tiles.append((name, c))
    return tiles


def build_tiles(png, meta, cols=8):
    tiles = ground_tiles()
    sheet = Canvas(cols * T, (len(tiles) + cols - 1) // cols * T)
    for i, (_, t) in enumerate(tiles):
        sheet.paste(t, (i % cols) * T, (i // cols) * T)
    sheet.image().save(png)
    names = [n for n, _ in tiles]
    with open(meta, "w") as f:
        json.dump({"columns": cols, "tiles": names, "decor": list(DECOR) + ["fence"],
                   "variants": {"road": ["road_b"]}}, f, indent=1)
    return names


# ------------------------------------------------------------ props

ROOF = [RED[0], RED[1], RED[1], RED[2]]
WALL = [CREAM[0], CREAM[0], CREAM[1]]


def roof(c, x0, y0, x1, y1, ramp=ROOF):
    """Shingled roof plane seen from the front-top, lit from the left."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            t = 0.8 - (x - x0) / (x1 - x0) * 0.4 - (y - y0) / (y1 - y0) * 0.25
            row = (y - y0) // 4
            if (y - y0) % 4 == 3 or (x + row * 3) % 7 == 0 and (y - y0) % 4 == 2:
                t -= 0.35  # shingle edges
            c.set(x, y, shade(ramp, t, x, y, dither=False))
    for x in range(x0, x1 + 1):
        c.set(x, y0, ramp[-1])  # ridge catches the light
        c.set(x, y1, BARK[1])  # wooden eave
        c.set(x, y1 - 1, BARK[2])


def window(c, x0, y0, w=10, h=9, box=True):
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            edge = x in (x0, x0 + w - 1) or y in (y0, y0 + h - 1)
            mid = x == x0 + w // 2 or y == y0 + h // 2
            glass = BLUE[3] if (x - x0) + (y - y0) < 5 else BLUE[2]
            c.set(x, y, BARK[1] if edge else BARK[2] if mid else glass)
    if box:  # flower box
        for x in range(x0 - 1, x0 + w + 1):
            c.set(x, y0 + h, BARK[2])
            c.set(x, y0 + h + 1, BARK[1])
        for i, x in enumerate(range(x0, x0 + w, 2)):
            c.set(x, y0 + h - 1, [RED[2], P["pink"][1], EMBER[3]][i % 3])
            c.set(x + 1, y0 + h - 1, LEAF[3])


def door(c, x0, y0, w=12, h=18):
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            edge = x in (x0, x0 + w - 1) or y == y0
            plank = (x - x0) % 3 == 0
            c.set(x, y, BARK[0] if edge else BARK[3] if x == x0 + 1 else BARK[1] if plank else BARK[2])
    c.set(x0 + w - 3, y0 + h // 2, EMBER[3])  # knob


def house(seed, shop=False):
    """80×64 cottage: shingled roof with chimney, cream wall with timber
    frame, two flower-box windows and a door. Base = bottom of the wall."""
    c = Canvas(80, 64)
    for y in range(0, 10):  # chimney
        for x in range(58, 65):
            c.set(x, y, shade(STONE[:4], 0.8 - (x - 58) / 7 * 0.5, x, y, dither=False))
    for x in range(58, 65):
        c.set(x, 0, STONE[0])
    roof(c, 2, 6, 77, 33)
    for y in range(34, 62):  # wall
        for x in range(5, 75):
            t = 0.75 - (x - 5) / 70 * 0.4
            c.set(x, y, shade(WALL, t, x, y, dither=False))
    for x in range(5, 75):  # shade under the eave, timber beam
        c.set(x, 34, DIRT[3])
        c.set(x, 35, DIRT[3] if x % 2 else CREAM[0])
        c.set(x, 38, BARK[2])
    for x0 in (5, 38, 73):  # timber posts
        for y in range(36, 62):
            c.set(x0, y, BARK[2])
            c.set(x0 + 1, y, BARK[1])
    window(c, 13, 41)
    window(c, 56, 41)
    door(c, 34, 44)
    for x in range(4, 76):  # stone footing
        c.set(x, 62, STONE[2] if (x // 4) % 2 else STONE[3])
        c.set(x, 63, STONE[1])
    if shop:
        for y in range(38, 43):  # striped awning over the door
            for x in range(29, 51):
                c.set(x, y, (RED[2] if y == 38 else RED[1]) if (x // 3) % 2 else (CREAM[1] if y == 38 else CREAM[0]))
        for x in range(29, 51, 3):
            c.set(x, 43, RED[1])
        for y in range(45, 52):  # hanging sign with a coin, between window and door
            for x in range(25, 32):
                c.set(x, y, BARK[2] if x in (25, 31) or y in (45, 51) else BARK[3])
        for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1)):
            c.set(27 + dx, 47 + dy, EMBER[3] if dx + dy == 0 else EMBER[2])
    c.outline()
    return c


def temple_back(seed):
    """112×40 shrine roof and back wall (sits behind the shrine floor)."""
    c = Canvas(112, 40)
    temple_roof = [RED[0], RED[0], RED[1], RED[2]]
    roof(c, 1, 4, 110, 28, temple_roof)
    for x in range(1, 111):  # gold trim along the eave
        c.set(x, 27, EMBER[2] if x % 4 else EMBER[1])
    for y in range(29, 40):  # back wall in shade: stone courses
        for x in range(4, 108):
            row = (y - 29) // 4
            joint = (y - 29) % 4 == 3 or (x + row * 5) % 10 == 0
            c.set(x, y, STONE[0] if joint else STONE[1] if (y - 29) % 4 == 2 else STONE[2])
    # the Crest emblem on the ridge
    for dx, dy, col in ((0, -3, EMBER[3]), (-1, -2, EMBER[2]), (0, -2, EMBER[3]), (1, -2, EMBER[1]),
                        (-2, -1, EMBER[1]), (-1, -1, EMBER[3]), (0, -1, P["white"][0]), (1, -1, EMBER[2]),
                        (2, -1, EMBER[0]), (-1, 0, EMBER[1]), (0, 0, EMBER[2]), (1, 0, EMBER[0]), (0, 1, EMBER[0])):
        c.set(56 + dx, 4 + dy, col)
    c.outline()
    return c


def pillar(seed):
    c = Canvas(16, 48)
    for y in range(4, 46):
        for x in range(4, 12):
            c.set(x, y, shade([STONE[2], CREAM[0], CREAM[0], CREAM[1]], 0.85 - (x - 4) / 8 * 0.7, x, y, dither=False))
    for x in range(2, 14):  # capital and base
        for y in (2, 3, 44, 45):
            c.set(x, y, CREAM[1] if y in (2, 44) else STONE[2])
    for y in range(8, 42, 6):  # ember band
        c.set(5, y, EMBER[1])
        c.set(6, y, EMBER[2])
    c.outline()
    return c


def shrine(seed):
    """32×32 pedestal holding the Crest's ember bowl."""
    c = Canvas(32, 32)
    for y in range(16, 30):
        w = 8 if y > 18 else 11
        for x in range(16 - w, 16 + w):
            c.set(x, y, shade(STONE[1:5], 0.85 - (x - 16 + w) / (2 * w) * 0.6 - (y - 16) / 14 * 0.2, x, y, dither=False))
    for x in range(4, 28):
        c.set(x, 16, STONE[4])
    for y in range(10, 16):  # bowl
        w = 9 - (y - 10) // 2
        for x in range(16 - w, 16 + w):
            c.set(x, y, BARK[1] if y > 11 else EMBER[1])
    flame = ["....a....", "...aba...", "..abcba..", "..bcdcb..", ".bcdddcb.", ".bcdddcb."]
    c.stamp(flame, {"a": EMBER[0], "b": EMBER[1], "c": EMBER[3], "d": P["white"][0]}, 12, 4)
    c.outline()
    return c


def lantern(seed):
    """16×32 lantern post."""
    c = Canvas(16, 32)
    for y in range(8, 31):
        c.set(7, y, BARK[2])
        c.set(8, y, BARK[1])
    for x in range(5, 11):
        c.set(x, 2, BARK[1])
    for x in range(4, 12):
        c.set(x, 3, BARK[2])
    for y in range(4, 10):
        for x in range(5, 11):
            edge = x in (5, 10) or y == 9
            c.set(x, y, BARK[0] if edge else EMBER[3] if (x, y) in ((6, 5), (7, 5), (6, 6)) else EMBER[2])
    c.set(7, 30, STONE[2])
    c.set(8, 30, STONE[1])
    c.outline()
    return c


def barrel(seed):
    c = Canvas(16, 20)
    for y in range(3, 18):
        bulge = 1 if 6 <= y <= 14 else 0
        for x in range(3 - bulge, 13 + bulge):
            t = 0.85 - (x - 2) / 12 * 0.6
            c.set(x, y, shade(BARK, t, x, y, dither=False))
    for y in (5, 15):  # iron hoops
        for x in range(2, 14):
            if c.get(x, y):
                c.set(x, y, STONE[2] if x < 8 else STONE[1])
    for x in range(4, 12):  # lid
        c.set(x, 3, BARK[3])
    c.outline()
    return c


def crate(seed):
    c = Canvas(16, 16)
    for y in range(3, 15):
        for x in range(2, 14):
            edge = x in (2, 13) or y in (3, 14) or x == y or x + y == 17
            c.set(x, y, BARK[1] if edge else shade(BARK[1:], 0.9 - (x - 2) / 12 * 0.5, x, y, dither=False))
    c.outline()
    return c


VILLAGE_CANOPY = [LEAF[1], LEAF[2], LEAF[3], LEAF[4], LEAF[5]]

# name: (sprite fn, collision box relative to the base point[, glow])
PROPS = {
    "house": (lambda s: house(s), (-37, -28, 74, 28)),
    "shop": (lambda s: house(s, shop=True), (-37, -28, 74, 28)),
    "temple_back": (temple_back, (-56, -12, 112, 12)),
    "pillar": (pillar, (-5, -6, 10, 6)),
    "shrine": (shrine, (-9, -8, 18, 8), {"dy": -22, "radius": 30, "color": "#FAD65A"}),
    "tree": (lambda s: ww.big_tree(s, VILLAGE_CANOPY), (-7, -8, 14, 8)),
    "tree_b": (lambda s: ww.big_tree_b(s, VILLAGE_CANOPY), (-7, -8, 14, 8)),
    "tree_small": (lambda s: ww.small_tree(s, VILLAGE_CANOPY), (-4, -6, 8, 6)),
    "bush": (ww.bush, (-12, -8, 24, 8)),
    "rock": (ww.rock, (-9, -8, 18, 8)),
    "signpost": (ww.signpost, (-3, -5, 6, 5)),
    "lantern": (lantern, (-3, -4, 6, 4), {"dy": -26, "radius": 22, "color": "#FAD65A"}),
    "barrel": (barrel, (-6, -5, 12, 5)),
    "crate": (crate, (-6, -5, 12, 5)),
}


if __name__ == "__main__":
    names = build_tiles("../../assets/maps/hollowmere_tiles.png", "../../assets/maps/hollowmere_tiles.json")
    frames = ww.build_props("../../assets/images/props/hollowmere_props.png", "../../assets/data/props_hollowmere.json",
                            PROPS)
    print(len(names), "tiles;", len(frames), "props")
