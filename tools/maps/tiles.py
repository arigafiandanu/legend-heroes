"""Procedural 16×16 placeholder tileset (until final tile art exists).

Every tile is drawn with a small fixed palette + seeded noise so the look is
stable between runs. Tile ids are the index in TILES (row-major, 8 per row).
"""
import random

from PIL import Image, ImageDraw

T = 16
COLS = 8

PAL = {
    "grass": [(94, 140, 74), (88, 132, 74), (104, 150, 80), (75, 115, 64)],
    "dirt": [(176, 138, 90), (166, 128, 82), (188, 150, 100), (150, 114, 72)],
    "stone": [(150, 146, 140), (138, 134, 130), (164, 160, 152), (110, 106, 104)],
    "water": [(62, 116, 170), (72, 128, 182), (92, 150, 200), (48, 96, 146)],
    "wood": [(120, 82, 52), (104, 70, 44), (138, 96, 60), (78, 52, 34)],
    "leaf": [(58, 110, 62), (48, 96, 56), (74, 128, 70), (36, 74, 46)],
    "roof": [(160, 72, 56), (140, 60, 48), (178, 90, 66), (100, 42, 36)],
    "wall": [(222, 206, 176), (206, 190, 162), (236, 222, 194), (160, 142, 116)],
    "forest": [(60, 88, 62), (54, 80, 58), (68, 98, 68), (40, 62, 46)],
    "darkleaf": [(40, 76, 52), (32, 64, 46), (52, 92, 60), (22, 46, 34)],
    "temple": [(196, 186, 170), (182, 172, 158), (210, 200, 186), (140, 130, 120)],
    "ember": [(255, 170, 60), (240, 110, 40), (255, 220, 120), (170, 60, 30)],
}


def noise(img, pal, seed, density=0.35):
    r = random.Random(seed)
    px = img.load()
    for y in range(T):
        for x in range(T):
            px[x, y] = pal[0]
            v = r.random()
            if v < density * 0.5:
                px[x, y] = pal[1]
            elif v < density:
                px[x, y] = pal[2]


def outline(d, box, color):
    d.rectangle(box, outline=color)


def tile_grass(img, d, s):
    noise(img, PAL["grass"], s)
    r = random.Random(s)
    for _ in range(3):
        x, y = r.randint(1, 13), r.randint(2, 12)
        d.line([(x, y + 3), (x, y)], fill=PAL["grass"][3])
        d.line([(x + 2, y + 3), (x + 2, y + 1)], fill=PAL["grass"][3])


def tile_flowers(img, d, s):
    tile_grass(img, d, s)
    for x, y, c in ((3, 4, (240, 220, 90)), (11, 9, (230, 110, 120)), (6, 12, (250, 250, 240))):
        d.point([(x, y), (x + 1, y), (x, y + 1), (x + 1, y + 1)], fill=c)


def tile_dirt(img, d, s):
    noise(img, PAL["dirt"], s, 0.3)


def tile_plaza(img, d, s):
    noise(img, PAL["stone"], s, 0.25)
    for y in (0, 8):
        d.line([(0, y), (15, y)], fill=PAL["stone"][3])
    d.line([(8, 0), (8, 7)], fill=PAL["stone"][3])
    d.line([(4, 8), (4, 15)], fill=PAL["stone"][3])
    d.line([(12, 8), (12, 15)], fill=PAL["stone"][3])


def tile_water(img, d, s):
    noise(img, PAL["water"], s, 0.2)
    r = random.Random(s)
    for _ in range(2):
        x, y = r.randint(1, 10), r.randint(2, 13)
        d.line([(x, y), (x + 4, y)], fill=PAL["water"][2])


def tile_fence(img, d, s):
    tile_grass(img, d, s)
    w = PAL["wood"]
    d.rectangle([0, 6, 15, 7], fill=w[2])
    d.rectangle([0, 11, 15, 12], fill=w[0])
    for x in (2, 12):
        d.rectangle([x, 3, x + 2, 15], fill=w[0], outline=w[3])


def tile_bush(img, d, s):
    tile_grass(img, d, s)
    l = PAL["leaf"]
    d.ellipse([1, 3, 14, 15], fill=l[0], outline=l[3])
    d.ellipse([4, 5, 9, 9], fill=l[2])


def tile_trunk(img, d, s, left):
    tile_grass(img, d, s) if s < 5000 else tile_forest(img, d, s)
    w = PAL["wood"]
    x0 = 9 if left else -1
    d.rectangle([x0, 0, x0 + 7, 12], fill=w[0], outline=w[3])
    d.line([(x0 + 3, 2), (x0 + 3, 10)], fill=w[1])
    d.ellipse([x0 - 2, 11, x0 + 9, 15], fill=(0, 0, 0, 0) if False else w[3])


def tile_canopy(img, d, s, part, pal="leaf"):
    img.paste((0, 0, 0, 0), [0, 0, T, T])
    l = PAL[pal]
    cx = 16 if part in ("tl", "bl") else 0
    cy = 16 if part in ("tl", "tr") else 0
    d.ellipse([cx - 15, cy - 15, cx + 15, cy + 13], fill=l[0], outline=l[3])
    r = random.Random(s)
    for _ in range(10):
        x, y = r.randint(0, 15), r.randint(0, 15)
        if (x - cx) ** 2 + (y - cy) ** 2 < 150:
            d.point([(x, y), (x + 1, y)], fill=l[2] if r.random() < 0.6 else l[1])


def tile_rock(img, d, s):
    tile_grass(img, d, s)
    st = PAL["stone"]
    d.polygon([(2, 14), (3, 6), (8, 3), (13, 6), (14, 14)], fill=st[0], outline=st[3])
    d.line([(5, 7), (8, 5)], fill=st[2])


def tile_sign(img, d, s):
    tile_grass(img, d, s)
    w = PAL["wood"]
    d.rectangle([7, 8, 8, 15], fill=w[3])
    d.rectangle([2, 3, 13, 9], fill=w[2], outline=w[3])
    d.line([(4, 5), (11, 5)], fill=w[3])
    d.line([(4, 7), (9, 7)], fill=w[3])


def tile_wall(img, d, s, window=False, door=False):
    noise(img, PAL["wall"], s, 0.2)
    w = PAL["wall"]
    d.line([(0, 15), (15, 15)], fill=w[3])
    d.line([(0, 0), (0, 15)], fill=w[1])
    if window:
        d.rectangle([4, 4, 11, 10], fill=(80, 110, 140), outline=PAL["wood"][3])
        d.line([(8, 4), (8, 10)], fill=PAL["wood"][3])
    if door:
        d.rectangle([3, 3, 12, 15], fill=PAL["wood"][0], outline=PAL["wood"][3])
        d.point([(10, 10)], fill=(230, 200, 90))


def tile_roof(img, d, s, edge):
    noise(img, PAL["roof"], s, 0.2)
    r = PAL["roof"]
    for y in (3, 7, 11, 15):
        d.line([(0, y), (15, y)], fill=r[3])
    if edge == "l":
        d.line([(0, 0), (0, 15)], fill=r[3])
    if edge == "r":
        d.line([(15, 0), (15, 15)], fill=r[3])


def tile_temple_floor(img, d, s):
    noise(img, PAL["temple"], s, 0.15)
    d.rectangle([0, 0, 15, 15], outline=PAL["temple"][3])


def tile_pillar(img, d, s):
    tile_temple_floor(img, d, s)
    t = PAL["temple"]
    d.rectangle([4, 0, 11, 15], fill=t[2], outline=t[3])
    d.line([(6, 1), (6, 14)], fill=t[0])


def tile_shrine(img, d, s):
    tile_temple_floor(img, d, s)
    e = PAL["ember"]
    d.rectangle([3, 9, 12, 15], fill=PAL["stone"][1], outline=PAL["stone"][3])
    d.polygon([(8, 1), (12, 8), (8, 10), (4, 8)], fill=e[1], outline=e[3])
    d.polygon([(8, 4), (10, 8), (8, 9), (6, 8)], fill=e[2])


def tile_forest(img, d, s):
    noise(img, PAL["forest"], s, 0.35)


def tile_moss(img, d, s):
    tile_forest(img, d, s)
    r = random.Random(s)
    for _ in range(6):
        x, y = r.randint(0, 14), r.randint(0, 14)
        d.point([(x, y), (x + 1, y)], fill=(90, 130, 70))


def tile_mushrooms(img, d, s):
    tile_forest(img, d, s)
    for x, y in ((4, 9), (10, 6)):
        d.rectangle([x, y, x + 1, y + 3], fill=(230, 220, 200))
        d.ellipse([x - 2, y - 2, x + 3, y + 1], fill=(200, 80, 70))


def tile_log(img, d, s):
    tile_forest(img, d, s)
    w = PAL["wood"]
    d.rectangle([0, 6, 15, 12], fill=w[0], outline=w[3])
    d.line([(1, 8), (14, 8)], fill=w[2])


def tile_forest_path(img, d, s):
    noise(img, [(128, 104, 74), (118, 96, 68), (138, 112, 80), (96, 78, 56)], s, 0.3)


def tile_roots(img, d, s):
    tile_forest(img, d, s)
    w = PAL["wood"]
    d.line([(0, 12), (6, 9), (10, 11), (15, 7)], fill=w[3])


def tile_grass_edge(img, d, s):
    """Dirt with a grass fringe on top (path border)."""
    tile_dirt(img, d, s)
    g = PAL["grass"]
    for x in range(T):
        d.line([(x, 0), (x, 1 + (x * 7) % 3)], fill=g[0])


TILES = [
    # row 0: village ground
    ("grass", tile_grass), ("grass2", lambda i, d, s: tile_grass(i, d, s + 99)), ("flowers", tile_flowers),
    ("dirt", tile_dirt), ("plaza", tile_plaza), ("water", tile_water), ("fence", tile_fence), ("bush", tile_bush),
    # row 1: trees & props
    ("trunk_l", lambda i, d, s: tile_trunk(i, d, s, True)), ("trunk_r", lambda i, d, s: tile_trunk(i, d, s, False)),
    ("canopy_tl", lambda i, d, s: tile_canopy(i, d, s, "tl")), ("canopy_tr", lambda i, d, s: tile_canopy(i, d, s, "tr")),
    ("canopy_bl", lambda i, d, s: tile_canopy(i, d, s, "bl")), ("canopy_br", lambda i, d, s: tile_canopy(i, d, s, "br")),
    ("rock", tile_rock), ("sign", tile_sign),
    # row 2: buildings
    ("wall", tile_wall), ("wall_window", lambda i, d, s: tile_wall(i, d, s, window=True)),
    ("door", lambda i, d, s: tile_wall(i, d, s, door=True)),
    ("roof_l", lambda i, d, s: tile_roof(i, d, s, "l")), ("roof", lambda i, d, s: tile_roof(i, d, s, "")),
    ("roof_r", lambda i, d, s: tile_roof(i, d, s, "r")), ("temple_floor", tile_temple_floor), ("pillar", tile_pillar),
    # row 3: shrine + forest
    ("shrine", tile_shrine), ("forest", tile_forest), ("forest2", lambda i, d, s: tile_forest(i, d, s + 99)),
    ("moss", tile_moss), ("mushrooms", tile_mushrooms), ("log", tile_log), ("forest_path", tile_forest_path), ("roots", tile_roots),
    # row 4: dark forest trees + path edge
    ("dtrunk_l", lambda i, d, s: tile_trunk(i, d, s + 5000, True)), ("dtrunk_r", lambda i, d, s: tile_trunk(i, d, s + 5000, False)),
    ("dcanopy_tl", lambda i, d, s: tile_canopy(i, d, s, "tl", "darkleaf")), ("dcanopy_tr", lambda i, d, s: tile_canopy(i, d, s, "tr", "darkleaf")),
    ("dcanopy_bl", lambda i, d, s: tile_canopy(i, d, s, "bl", "darkleaf")), ("dcanopy_br", lambda i, d, s: tile_canopy(i, d, s, "br", "darkleaf")),
    ("grass_edge", tile_grass_edge), ("empty", lambda i, d, s: i.paste((0, 0, 0, 0), [0, 0, T, T])),
]
ID = {name: i for i, (name, _) in enumerate(TILES)}

# Tiles that block movement when placed on the decor layer.
SOLID = {"fence", "bush", "trunk_l", "trunk_r", "dtrunk_l", "dtrunk_r", "rock", "sign", "wall",
         "wall_window", "door", "pillar", "shrine", "water", "log"}


def build(path):
    rows = (len(TILES) + COLS - 1) // COLS
    sheet = Image.new("RGBA", (COLS * T, rows * T), (0, 0, 0, 0))
    for i, (name, fn) in enumerate(TILES):
        img = Image.new("RGBA", (T, T), (0, 0, 0, 0))
        fn(img, ImageDraw.Draw(img), 1000 + i * 17)
        sheet.paste(img, ((i % COLS) * T, (i // COLS) * T))
    sheet.save(path)
    return sheet.size
