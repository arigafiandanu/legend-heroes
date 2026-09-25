"""Builds the Tiled maps (.tmx).

Maps are generated so they stay consistent with their tileset; they can
also be opened and edited directly in Tiled (assets/maps/*.tmx).
Layers: ground, decor (below characters), foreground (above characters),
object groups `collision`, `objects` and `props`.

Each area has its final tileset: opaque base tiles + transparent decoration
tiles (tools/art/<area>.py) and y-sorted prop sprites placed as points in
the `props` group (kind = object name); the game reads their collision
boxes from assets/data/props_<area>.json.
"""
import json
import math
import os
import random
import sys
from xml.sax.saxutils import quoteattr

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "art"))
from autotile import clamped, clean, path_piece, stroke  # noqa: E402

T = 16
# Decor tiles that block movement (whole tile).
SOLID = {"fence"}


class Tileset:
    def __init__(self, name, image, names, cols):
        self.name, self.image, self.names, self.cols = name, image, list(names), cols
        self.id = {n: i for i, n in enumerate(self.names)}


def area_tileset(area):
    meta = json.load(open(f"../../assets/maps/{area}_tiles.json"))
    return Tileset(area, f"{area}_tiles.png", meta["tiles"], meta["columns"]), meta


def _prop(name, value):
    """Tiled property; ints/bools get their type so the game can read them."""
    kind = ' type="bool"' if isinstance(value, bool) else ' type="int"' if isinstance(value, int) else ""
    text = str(value).lower() if isinstance(value, bool) else str(value)
    return f'    <property name="{name}"{kind} value={quoteattr(text)}/>'


class MapBuilder:
    def __init__(self, name, w, h, props, seed, tileset):
        self.name, self.w, self.h, self.props = name, w, h, props
        self.tileset = tileset
        self.r = random.Random(seed)
        self.layers = {k: [[None] * w for _ in range(h)] for k in ("ground", "decor", "foreground")}
        self.objects = []
        self.prop_points = []  # (kind, x, y) in px, the sprite's bottom-centre base
        self.lights = []  # (kind, x, y, w, h) in px
        self.solids = []  # extra collision rects in px

    def inside(self, x, y):
        return 0 <= x < self.w and 0 <= y < self.h

    def set(self, layer, x, y, tile):
        if self.inside(x, y):
            self.layers[layer][y][x] = tile

    def get(self, layer, x, y):
        return self.layers[layer][y][x] if self.inside(x, y) else None

    def light(self, kind, x, y, w, h):
        """Light shape in px; `shaft` = warm light through the canopy (game: lighting.dart)."""
        self.lights.append((kind, round(x), round(y), round(w), round(h)))

    def prop(self, kind, x, y):
        self.prop_points.append((kind, round(x), round(y)))

    def obj(self, cls, name, x, y, w=0, h=0, **props):
        """Object in tile units; w=h=0 makes a point (feet position)."""
        self.objects.append((cls, name, x * T, y * T, w * T, h * T, props))

    def collision_rects(self):
        rects = []
        for y in range(self.h):
            x = 0
            while x < self.w:
                if self.get("decor", x, y) in SOLID:
                    x0 = x
                    while x < self.w and self.get("decor", x, y) in SOLID:
                        x += 1
                    rects.append((x0 * T, y * T, (x - x0) * T, T))
                    continue
                x += 1
        rects += self.solids
        # Map borders
        W, H = self.w * T, self.h * T
        rects += [(-T, -T, W + 2 * T, T), (-T, H, W + 2 * T, T), (-T, 0, T, H), (W, 0, T, H)]
        return rects

    def write(self, path):
        ts = self.tileset
        out = [
            '<?xml version="1.0" encoding="UTF-8"?>',
            f'<map version="1.10" tiledversion="1.10.2" orientation="orthogonal" renderorder="right-down" '
            f'width="{self.w}" height="{self.h}" tilewidth="{T}" tileheight="{T}" infinite="0" nextlayerid="8" '
            f'nextobjectid="{len(self.objects) + len(self.prop_points) + 400}">',
            " <properties>",
            *[f'  <property name="{k}" value={quoteattr(str(v))}/>' for k, v in self.props.items()],
            " </properties>",
            f' <tileset firstgid="1" name="{ts.name}" tilewidth="{T}" tileheight="{T}" tilecount="{len(ts.names)}" columns="{ts.cols}">',
            f'  <image source="{ts.image}" width="{ts.cols * T}" height="{((len(ts.names) + ts.cols - 1) // ts.cols) * T}"/>',
            " </tileset>",
        ]
        for lid, layer in enumerate(("ground", "decor", "foreground"), start=1):
            rows = [",".join(str(ts.id[t] + 1) if t else "0" for t in row) for row in self.layers[layer]]
            out += [f' <layer id="{lid}" name="{layer}" width="{self.w}" height="{self.h}">',
                    '  <data encoding="csv">', ",\n".join(rows), "  </data>", " </layer>"]
        oid = 1
        out.append(' <objectgroup id="4" name="collision">')
        for x, y, w, h in self.collision_rects():
            out.append(f'  <object id="{oid}" x="{x}" y="{y}" width="{w}" height="{h}"/>')
            oid += 1
        out.append(" </objectgroup>")
        out.append(' <objectgroup id="5" name="objects">')
        for cls, name, x, y, w, h, props in self.objects:
            size = f' width="{w}" height="{h}"' if w or h else ""
            out.append(f'  <object id="{oid}" name={quoteattr(name)} class="{cls}" x="{x}" y="{y}"{size}>')
            if props:
                out.append("   <properties>")
                out += [_prop(k, v) for k, v in props.items()]
                out.append("   </properties>")
            if not (w or h):
                out.append("   <point/>")
            out.append("  </object>")
            oid += 1
        out.append(" </objectgroup>")
        out.append(' <objectgroup id="6" name="props">')
        for kind, x, y in sorted(self.prop_points, key=lambda q: (q[2], q[1])):
            out += [f'  <object id="{oid}" name="{kind}" class="prop" x="{x}" y="{y}">', "   <point/>", "  </object>"]
            oid += 1
        out.append(" </objectgroup>")
        out.append(' <objectgroup id="7" name="lights">')
        for kind, x, y, w, h in self.lights:
            out.append(f'  <object id="{oid}" name="{kind}" class="light" x="{x}" y="{y}" width="{w}" height="{h}"/>')
            oid += 1
        out += [" </objectgroup>", "</map>", ""]
        with open(path, "w") as f:
            f.write("\n".join(out))


def hollowmere():
    """The home village. Final art: dirt roads and a paved square autotiled
    against the grass, a pond, and houses, shrine, trees and lanterns as
    y-sorted props. Object positions are unchanged from the M2 layout."""
    W, H = 40, 24
    ts, meta = area_tileset("hollowmere")
    m = MapBuilder("hollowmere", W, H, {"bgm": "hollowmere", "nameKey": "mapHollowmere", "props": "hollowmere"},
                   seed=3, tileset=ts)

    def cells(x0, y0, x1, y1):
        return {(x, y) for x in range(x0, x1 + 1) for y in range(y0, y1 + 1)}

    houses = [("house", 4, 4), ("shop", 30, 4), ("house", 5, 16), ("house", 29, 16)]
    doors = [(x + 2, y + 4) for _, x, y in houses]  # tile just in front of each door
    road = cells(0, 12, 39, 13) | cells(19, 7, 20, 21)
    for x, y in doors:
        # north houses: a 3-wide lane down to the main road; south houses face
        # away from it, so they get a doorstep instead
        road |= cells(x - 1, y, x + 1, 11) if y <= 11 else cells(x - 1, y, x + 1, y + 1)
    plaza = cells(15, 10, 24, 15)
    temple_floor = cells(16, 4, 22, 6)
    walk = clean(road | plaza | temple_floor, W, H) | temple_floor
    water = clean(cells(9, 8, 12, 9), W, H)
    on_walk, on_water = clamped(walk, W, H), clamped(water, W, H)

    for y in range(H):
        for x in range(W):
            if (x, y) in temple_floor:
                m.set("ground", x, y, "temple_floor")
            elif (x, y) in walk:
                piece = path_piece(on_walk, x, y)
                surface = "plaza" if (x, y) in plaza else "road"
                name = surface + piece[len("path"):]
                m.set("ground", x, y, m.r.choice([name] * 3 + meta["variants"].get(name, [])))
            elif (x, y) in water:
                m.set("ground", x, y, "water" + path_piece(on_water, x, y)[len("path"):])
            else:
                m.set("ground", x, y, m.r.choices(["grass", "grass_b", "grass_sun", "grass_sun_b"], [8, 4, 2, 2])[0])
                if m.r.random() < 0.22:
                    m.set("decor", x, y, m.r.choices(["tuft", "tuft_b", "flowers_blue", "flowers_pink",
                                                       "flowers_white", "clover", "pebbles"], [6, 4, 2, 2, 2, 2, 1])[0])
    m.solids.append((9 * T + 2, 8 * T + 3, 4 * T - 4, 2 * T - 5))  # pond
    for x in range(14, 26):
        if x not in (19, 20):
            m.set("decor", x, 16, "fence")
            m.solids.append((x * T, 16 * T + 5, T, 7))
    for x, y in ((12, 15), (12, 17), (26, 9), (8, 10)):  # flower beds by the houses and square
        m.set("decor", x, y, "flower_bed")

    # Props. Occupied cells keep trees off roads, buildings and the pond.
    taken = set(walk) | water | cells(14, 16, 25, 16)
    for kind, x, y in houses:
        m.prop(kind, (x + 2.5) * T, (y + 4) * T)
        taken |= cells(x, y, x + 4, y + 3)
    m.prop("temple_back", 19.5 * T, 4.5 * T)
    m.prop("pillar", 16.5 * T, 7 * T)
    m.prop("pillar", 22.5 * T, 7 * T)
    m.prop("shrine", 19.5 * T, 6 * T)
    taken |= cells(16, 2, 22, 6)

    def tree(x, y, kinds=("tree", "tree_b", "tree", "tree_small")):
        """Tree whose trunk stands on cell (x, y), canopy over the two cells above."""
        if cells(x, y - 2, x + 1, y) & taken:
            return
        m.prop(m.r.choice(kinds), (x + 1) * T, (y + 1) * T)
        taken.update(cells(x, y - 2, x + 1, y))

    for x in range(0, 40, 2):  # border forest, gap on the east edge for the gate road
        if not 15 <= x <= 23:
            tree(x, 2)
        if x not in (18, 20):
            tree(x, 23)
    for y in range(5, 23, 3):
        tree(0, y)
        if not 9 <= y <= 15:
            tree(38, y)
    for x, y in ((14, 8), (26, 8), (13, 20), (25, 19), (35, 20)):
        tree(x, y)
    for kind, x, y in (("bush", 10, 10), ("bush", 27, 11), ("rock", 3, 13), ("bush", 36, 16)):
        m.prop(kind, (x + 0.5) * T, (y + 1) * T)
    m.prop("signpost", 24.5 * T, 12 * T - 1)
    for x, y in ((14, 10), (26, 10), (14, 15), (25, 15), (37, 10), (37, 15), (21, 8)):
        m.prop("lantern", (x + 0.5) * T, (y + 1) * T - 2)
    for kind, x, y in (("barrel", 35.5, 8), ("crate", 36.6, 8.2), ("barrel", 10.5, 20)):
        m.prop(kind, x * T, y * T)

    home = doors[2]
    m.obj("spawn", "start", home[0] + 0.5, home[1] + 0.9)
    m.obj("spawn", "east", 37, 13)
    shop = doors[1]
    m.obj("npc", "elder", 18.5, 9, dialog="Elder", sheet="npc/elder_sheet.png", facing="down")
    m.obj("npc", "merchant", shop[0] + 1.5, shop[1] + 1, dialog="Merchant", sheet="npc/merchant_sheet.png", facing="down")
    m.obj("npc", "child", 10.5, 14, dialog="Child", sheet="npc/child_sheet.png", facing="right", wander=1)
    m.obj("npc", "guard", 36.5, 11.5, dialog="Guard", sheet="npc/guard_sheet.png", facing="left")
    m.obj("campfire", "square_fire", 19, 12, 2, 2, dialog="Campfire")
    m.obj("chest", "chest_1", 3, 18, 1, 1, item="herbal", count=2)
    m.obj("sign", "sign_east", 24, 11, 1, 1, dialog="Sign_Whisperwood")
    m.obj("examine", "shrine", 19, 5, 1, 1, dialog="Shrine")
    m.obj("exit", "to_whisperwood", 39, 11, 1, 4, map="whisperwood_1", spawn="west",
          requiresFlag="quest_started", blockedDialog="Guard_Blocked")
    m.write("../../assets/maps/hollowmere.tmx")


WHISPERWOOD_PROPS = {"bgm": "whisperwood", "encounters": "whisperwood", "nameKey": "mapWhisperwood",
                     "props": "whisperwood", "backdrop": "whisperwood"}


def forest_ground(m, meta, path, clearings):
    """Grass tones + decor, the autotiled path, sunnier clearings.
    Returns (on_path, in_clearing) for prop placement."""
    W, H = m.w, m.h
    on_path = clamped(path, W, H)

    def in_clearing(x, y, pad=0):
        return any(x0 - pad <= x <= x1 + pad and y0 - pad <= y <= y1 + pad for x0, y0, x1, y1 in clearings)

    floors = ["floor", "floor_b", "floor_sun", "floor_sun_b", "floor_shade", "floor_shade_b"]
    decor = ["grass", "grass_b", "grass_tall", "flowers_blue", "flowers_pink", "flowers_white", "clover", "ferns",
             "mushrooms", "litter", "pebbles", "twig"]
    for y in range(H):
        for x in range(W):
            if (x, y) in path:
                piece = path_piece(on_path, x, y)
                m.set("ground", x, y, m.r.choice([piece] * 2 + meta["variants"].get(piece, [])))
                continue
            sunny = in_clearing(x, y)
            weights = [6, 2, 4, 3, 0.3, 0.3] if sunny else [10, 4, 1.4, 1.2, 1.2, 1]
            m.set("ground", x, y, m.r.choices(floors, weights)[0])
            if m.r.random() < (0.4 if sunny else 0.28):
                m.set("decor", x, y, m.r.choices(decor, [8, 5, 3, 2 if sunny else 1.4, 1.5 if sunny else 1,
                                                         1.5 if sunny else 1, 2, 1.5, 0.6, 1.5, 1, 0.8])[0])
    return on_path, in_clearing


def forest_props(m, on_path, in_clearing, blight, placed=()):
    """Undergrowth, Ashblight (`blight(x_fraction)` = chance per try) and
    trees, kept off the path and clearings, clear of every object, and no
    canopy over a chest or sign. `placed` are (x, y, spacing) already taken."""
    W, H = m.w, m.h
    keep_out = [(x + max(w, T) / 2, y + max(h, T) / 2, 30) for _, _, x, y, w, h, _ in m.objects]
    placed = list(placed)

    def blocked(px, py, trunk=10):
        tx, ty = int(px // T), int(py // T)
        if any(on_path(tx + dx, ty + dy) for dx in (-1, 0, 1) for dy in (-1, 0)):
            return True
        if in_clearing(tx, ty, pad=0):
            return True
        return any(math.hypot(px - cx, py - cy) < r + trunk for cx, cy, r in keep_out)

    def hides_object(px, py):
        """A tree whose canopy would cover a chest or sign."""
        return any(abs(px - cx) < 34 and 0 < py - cy < 72 for cx, cy, _ in keep_out)

    def try_place(kind, px, py, spacing):
        if px < 8 or px > W * T - 8 or py < 20 or py > H * T + 30 or blocked(px, py):
            return False
        if "tree" in kind or kind == "pine":
            if hides_object(px, py):
                return False
        if any(math.hypot(px - x, py - y) < max(spacing, s) for x, y, s in placed):
            return False
        placed.append((px, py, spacing))
        m.prop(kind, px, py)
        return True

    # Undergrowth and the spreading Ashblight first, then trees fill the rest.
    for kind, n, spacing in (("bush", 14, 22), ("rock", 6, 22), ("rock_small", 8, 16), ("log", 3, 30),
                             ("stump", 5, 18)):
        for _ in range(n * 30):
            if try_place(kind, m.r.uniform(0, W * T), m.r.uniform(0, H * T), spacing):
                n -= 1
                if n == 0:
                    break
    for _ in range(400):
        x = m.r.uniform(0, W * T)
        if m.r.random() < blight(x / (W * T)):
            try_place("ashblight", x, m.r.uniform(0, H * T), 20)
    for _ in range(1600):
        try_place(m.r.choices(["big_tree", "big_tree_b", "pine", "small_tree"], [3, 3, 3, 2])[0],
                  m.r.uniform(0, W * T), m.r.uniform(0, H * T + 24), 32)


def canopy_light(m, clearings, gaps):
    """Light shafts over each clearing and at a few gaps (tile coords)."""
    for x0, y0, x1, y1 in clearings:
        m.light("shaft", (x0 + 1) * T, (y0 - 3) * T, (x1 - x0 - 2) * T * 0.6, (y1 - y0 + 3) * T)
    for tx, ty in gaps:
        m.light("shaft", tx * T, ty * T, 28, 72)


def whisperwood_1():
    """Forest path west → east with two clearings. Final art: the path is a
    3-wide autotiled trail, trees and rocks are y-sorted props."""
    W, H = 48, 28
    ts, meta = area_tileset("whisperwood")
    m = MapBuilder("whisperwood_1", W, H, {**WHISPERWOOD_PROPS, "ambient": "#B8CCC8"}, seed=9, tileset=ts)
    path = clean(stroke([(-1, 14.5), (10.5, 14.5), (10.5, 9.5), (22.5, 9.5), (22.5, 17.5), (34.5, 17.5), (34.5, 12.5),
                         (49, 12.5)], 1.45, W, H), W, H)
    clearings = [(15, 19, 22, 25), (37, 2, 44, 8)]
    on_path, in_clearing = forest_ground(m, meta, path, clearings)

    m.obj("spawn", "west", 1, 14)
    m.obj("spawn", "east", 44.5, 12.8)
    m.obj("chest", "chest_a", 18, 22, 1, 1, item="herbal", count=2)
    m.obj("chest", "chest_b", 40, 5, 1, 1, item="tonik", count=1)
    m.obj("chest", "chest_c", 29, 20, 1, 1, item="bulu_bara", count=1)
    m.obj("sign", "sign_post", 45, 10, 1, 1, dialog="Sign_Post")
    m.obj("exit", "to_hollowmere", 0, 12, 1, 4, map="hollowmere", spawn="east")
    m.obj("exit", "to_whisperwood_2", 47, 11, 1, 4, map="whisperwood_2", spawn="west")
    m.prop("signpost", 45.5 * T, 11 * T - 1)

    # blight thickens toward the east (the mine)
    forest_props(m, on_path, in_clearing, lambda f: f ** 2 * 0.5, placed=[(45.5 * T, 11 * T, 10)])
    canopy_light(m, clearings, ((5, 11), (16, 6), (28, 14), (41, 9)))
    m.write("../../assets/maps/whisperwood_1.tmx")


def whisperwood_2():
    """Deeper forest toward the Post: darker, thick Ashblight, a hunter's camp.
    The hunter answers Lira's "Tanya" with the way to a hidden chest."""
    W, H = 48, 28
    ts, meta = area_tileset("whisperwood")
    m = MapBuilder("whisperwood_2", W, H, {**WHISPERWOOD_PROPS, "ambient": "#AABFBB"}, seed=21, tileset=ts)
    path = clean(stroke([(-1, 12.5), (8.5, 12.5), (8.5, 20.5), (24.5, 20.5), (24.5, 8.5), (40.5, 8.5), (40.5, 14.5),
                         (49, 14.5)], 1.45, W, H), W, H)
    clearings = [(28, 11, 35, 17), (12, 2, 18, 6), (30, 22, 36, 25)]
    on_path, in_clearing = forest_ground(m, meta, path, clearings)

    m.obj("spawn", "west", 2, 13)
    m.obj("spawn", "east", 45, 15)
    m.obj("npc", "hunter", 31.5, 14.5, dialog="Hunter", sheet="npc/hunter_sheet.png", facing="left")
    m.obj("chest", "chest_d", 33, 23, 1, 1, item="penawar", count=2)
    m.obj("chest", "chest_secret", 15, 3, 1, 1, item="bulu_bara", count=2, requiresFlag="ww_secret")
    m.obj("exit", "to_whisperwood_1", 0, 11, 1, 4, map="whisperwood_1", spawn="east")
    m.obj("exit", "to_post", 47, 13, 1, 4, blockedDialog="Path_Closed")

    forest_props(m, on_path, in_clearing, lambda f: 0.1 + f * 0.25)
    canopy_light(m, clearings, ((4, 9), (19, 17), (36, 5), (44, 11)))
    m.write("../../assets/maps/whisperwood_2.tmx")


if __name__ == "__main__":
    hollowmere()
    whisperwood_1()
    whisperwood_2()
    print("maps written")
