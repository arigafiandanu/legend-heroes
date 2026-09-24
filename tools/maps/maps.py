"""Builds the placeholder Tiled maps (.tmx) for M2.

Maps are generated so they stay consistent with the tileset; after M2 they
can be opened and edited directly in Tiled (assets/maps/*.tmx).
Layers: ground, decor (below characters), foreground (above characters),
object groups `collision` and `objects`.
"""
import random
from xml.sax.saxutils import quoteattr

import tiles

T = tiles.T
ID, SOLID = tiles.ID, tiles.SOLID


class MapBuilder:
    def __init__(self, name, w, h, props, seed):
        self.name, self.w, self.h, self.props = name, w, h, props
        self.r = random.Random(seed)
        self.layers = {k: [[None] * w for _ in range(h)] for k in ("ground", "decor", "foreground")}
        self.objects = []
        self.solids = []  # extra collision rects in px

    def inside(self, x, y):
        return 0 <= x < self.w and 0 <= y < self.h

    def set(self, layer, x, y, tile):
        if self.inside(x, y):
            self.layers[layer][y][x] = tile

    def get(self, layer, x, y):
        return self.layers[layer][y][x] if self.inside(x, y) else None

    def fill(self, choices):
        names, weights = zip(*choices)
        for y in range(self.h):
            for x in range(self.w):
                self.set("ground", x, y, self.r.choices(names, weights)[0])

    def rect(self, layer, x0, y0, x1, y1, tile):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.set(layer, x, y, tile)

    def free(self, x, y, w=1, h=1):
        return all(self.inside(x + i, y + j) and self.get("decor", x + i, y + j) is None
                   and self.get("ground", x + i, y + j) not in ("dirt", "plaza", "forest_path", "temple_floor")
                   for i in range(w) for j in range(h))

    def tree(self, x, y, dark=False):
        """2×3 tree: trunk base at row y, canopy on the two rows above."""
        p = "d" if dark else ""
        self.set("decor", x, y, p + "trunk_l")
        self.set("decor", x + 1, y, p + "trunk_r")
        for dx, dy, part in ((0, -2, "tl"), (1, -2, "tr"), (0, -1, "bl"), (1, -1, "br")):
            self.set("foreground", x + dx, y + dy, f"{p}canopy_{part}")

    def house(self, x, y):
        """5×4: roof (walkable, drawn above characters), front wall solid."""
        roof = ["roof_l", "roof", "roof", "roof", "roof_r"]
        for i, t in enumerate(roof):
            self.set("foreground", x + i, y, t)
            self.set("foreground", x + i, y + 1, t)
        for i, t in enumerate(["wall", "wall_window", "wall", "wall_window", "wall"]):
            self.set("decor", x + i, y + 2, t)
        for i, t in enumerate(["wall", "wall", "door", "wall", "wall"]):
            self.set("decor", x + i, y + 3, t)
        return (x + 2, y + 4)  # tile just in front of the door

    def temple(self, x, y):
        """7×5 Crest shrine: roof above, pillars and the ember shrine."""
        for j in (0, 1):
            for i in range(7):
                self.set("foreground", x + i, y + j, "roof_l" if i == 0 else "roof_r" if i == 6 else "roof")
        self.rect("ground", x, y + 2, x + 6, y + 4, "temple_floor")
        for j in (2, 3, 4):
            self.set("decor", x, y + j, "pillar")
            self.set("decor", x + 6, y + j, "pillar")
        self.set("decor", x + 3, y + 3, "shrine")

    def obj(self, cls, name, x, y, w=0, h=0, **props):
        """Object in tile units; w=h=0 makes a point (feet position)."""
        self.objects.append((cls, name, x * T, y * T, w * T, h * T, props))

    def collision_rects(self):
        rects = []
        for y in range(self.h):
            x = 0
            while x < self.w:
                t = self.get("decor", x, y)
                if t in SOLID and not t.endswith(("trunk_l", "trunk_r")):
                    x0 = x
                    while x < self.w and self.get("decor", x, y) in SOLID and not self.get("decor", x, y).endswith(("trunk_l", "trunk_r")):
                        x += 1
                    rects.append((x0 * T, y * T, (x - x0) * T, T))
                    continue
                if t and t.endswith("trunk_l"):
                    rects.append((x * T + 8, y * T + 4, 16, 10))  # narrow trunk box
                x += 1
        rects += self.solids
        # Map borders
        W, H = self.w * T, self.h * T
        rects += [(-T, -T, W + 2 * T, T), (-T, H, W + 2 * T, T), (-T, 0, T, H), (W, 0, T, H)]
        return rects

    def write(self, path):
        out = [
            '<?xml version="1.0" encoding="UTF-8"?>',
            f'<map version="1.10" tiledversion="1.10.2" orientation="orthogonal" renderorder="right-down" '
            f'width="{self.w}" height="{self.h}" tilewidth="{T}" tileheight="{T}" infinite="0" nextlayerid="6" nextobjectid="{len(self.objects) + 200}">',
            " <properties>",
            *[f'  <property name="{k}" value={quoteattr(str(v))}/>' for k, v in self.props.items()],
            " </properties>",
            f' <tileset firstgid="1" name="placeholder" tilewidth="{T}" tileheight="{T}" tilecount="{len(tiles.TILES)}" columns="{tiles.COLS}">',
            f'  <image source="placeholder_tiles.png" width="{tiles.COLS * T}" height="{((len(tiles.TILES) + tiles.COLS - 1) // tiles.COLS) * T}"/>',
            " </tileset>",
        ]
        for lid, layer in enumerate(("ground", "decor", "foreground"), start=1):
            rows = [",".join(str(ID[t] + 1) if t else "0" for t in row) for row in self.layers[layer]]
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
                out += [f'    <property name="{k}" value={quoteattr(str(v))}/>' for k, v in props.items()]
                out.append("   </properties>")
            if not (w or h):
                out.append("   <point/>")
            out.append("  </object>")
            oid += 1
        out += [" </objectgroup>", "</map>", ""]
        with open(path, "w") as f:
            f.write("\n".join(out))


def hollowmere():
    m = MapBuilder("hollowmere", 40, 24, {"bgm": "hollowmere", "nameKey": "mapHollowmere"}, seed=3)
    m.fill([("grass", 10), ("grass2", 6), ("flowers", 1)])
    m.rect("ground", 0, 12, 39, 13, "dirt")          # main road to the east gate
    m.rect("ground", 19, 7, 20, 21, "dirt")          # north–south road
    m.rect("ground", 15, 10, 24, 15, "plaza")        # village square
    m.temple(16, 2)
    m.rect("ground", 19, 7, 20, 9, "dirt")
    elder_door = m.house(4, 4)
    shop_door = m.house(30, 4)
    home_door = m.house(5, 16)
    m.house(29, 16)
    for dx, dy in ((elder_door, 0), (shop_door, 0), (home_door, 0)):
        x, y = dx
        m.rect("ground", x, y, x, 11, "dirt") if y <= 11 else m.rect("ground", x, 14, x, y, "dirt")
    m.rect("ground", 31, 14, 31, 19, "dirt")
    m.rect("ground", 9, 8, 12, 9, "water")            # small pond by the elder's house
    m.rect("decor", 9, 8, 12, 9, "water")
    for x in range(14, 26):
        if x not in (19, 20):
            m.set("decor", x, 16, "fence")
    # Border forest (gap on the east edge for the gate road).
    for x in range(0, 40, 2):
        if not 15 <= x <= 23:
            m.tree(x, 2)
        if x not in (18, 20):
            m.tree(x, 23)
    for y in range(5, 23, 3):
        m.tree(0, y)
        if not 9 <= y <= 15:
            m.tree(38, y)
    for x, y in ((14, 8), (26, 8), (13, 20), (25, 19), (35, 20)):
        if m.free(x, y - 2, 2, 3):
            m.tree(x, y)
    for x, y, t in ((10, 10, "bush"), (27, 11, "bush"), (3, 13, "rock"), (36, 16, "bush"), (24, 11, "sign")):
        m.set("decor", x, y, t)

    m.obj("spawn", "start", home_door[0] + 0.5, home_door[1] + 0.9)
    m.obj("spawn", "east", 37, 13)
    m.obj("npc", "elder", 18.5, 9, dialog="Elder", sheet="kael_sheet.png", tint="#9A9AA6", facing="down")
    m.obj("npc", "merchant", shop_door[0] + 1.5, shop_door[1] + 1, dialog="Merchant", sheet="lira_sheet.png", tint="#C9A05A", facing="down")
    m.obj("npc", "child", 10.5, 14, dialog="Child", sheet="lira_sheet.png", tint="#8FB0E0", facing="right", wander=1)
    m.obj("npc", "guard", 36.5, 11.5, dialog="Guard", sheet="kael_sheet.png", tint="#7A8A6A", facing="left")
    m.obj("campfire", "square_fire", 19, 12, 2, 2, dialog="Campfire")
    m.obj("chest", "chest_1", 3, 18, 1, 1, item="herbal", count=2)
    m.obj("sign", "sign_east", 24, 11, 1, 1, dialog="Sign_Whisperwood")
    m.obj("examine", "shrine", 19, 5, 1, 1, dialog="Shrine")
    m.obj("exit", "to_whisperwood", 39, 11, 1, 4, map="whisperwood_1", spawn="west",
          requiresFlag="quest_started", blockedDialog="Guard_Blocked")
    m.write("../../assets/maps/hollowmere.tmx")


def whisperwood_1():
    m = MapBuilder("whisperwood_1", 48, 28, {"bgm": "whisperwood", "encounters": "whisperwood", "nameKey": "mapWhisperwood"}, seed=9)
    m.fill([("forest", 10), ("forest2", 6), ("moss", 2), ("mushrooms", 0.4)])
    # Winding path west → east.
    y = 13
    for x in range(0, 48):
        if x in (10, 22, 34):
            y = {10: 8, 22: 17, 34: 12}[x]
        m.rect("ground", x, y, x, y + 1, "forest_path")
        if x in (10, 22, 34):
            prev = {10: 13, 22: 8, 34: 17}[x]
            m.rect("ground", x, min(prev, y), x + 1, max(prev, y) + 1, "forest_path")
    clearings = [(15, 19, 22, 25), (37, 2, 44, 8)]
    for x0, y0, x1, y1 in clearings:
        m.rect("ground", x0, y0, x1, y1, "moss")

    def near_path(x, y):
        return any(m.get("ground", x + dx, y + dy) == "forest_path" for dx in (-1, 0, 1, 2) for dy in (-1, 0, 1))

    def in_clearing(x, y):
        return any(x0 - 1 <= x <= x1 and y0 <= y <= y1 + 2 for x0, y0, x1, y1 in clearings)

    # Loose forest: jittered 3×3 grid, canopies never stacked on trunks.
    for gy in range(2, 28, 3):
        for gx in range(-1, 48, 3):
            x, y = gx + m.r.randint(0, 1), gy + m.r.randint(0, 1)
            area_free = m.free(x, y - 2, 2, 3) and all(
                m.get("foreground", x + i, y + j) is None for i in (0, 1) for j in (-2, -1, 0))
            if area_free and not near_path(x, y) and not in_clearing(x, y) and m.r.random() < 0.85:
                m.tree(x, y, dark=True)
    for x, yy in ((6, 16), (27, 10), (41, 20)):
        if m.free(x, yy):
            m.set("decor", x, yy, "log")
    m.set("decor", 45, 11, "sign")
    m.obj("spawn", "west", 1, 14)
    m.obj("chest", "chest_a", 18, 22, 1, 1, item="herbal", count=2)
    m.obj("chest", "chest_b", 40, 5, 1, 1, item="tonik", count=1)
    m.obj("chest", "chest_c", 29, 18, 1, 1, item="bulu_bara", count=1)
    m.obj("sign", "sign_post", 45, 11, 1, 1, dialog="Sign_Post")
    m.obj("exit", "to_hollowmere", 0, 12, 1, 4, map="hollowmere", spawn="east")
    m.obj("exit", "to_post", 47, 11, 1, 4, blockedDialog="Path_Closed")
    # Keep chests and the sign reachable: clear decor on/around them.
    for cls, name, x, yy, w, h, props in m.objects:
        tx, ty = int(x // T), int(yy // T)
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                if (tx + dx, ty + dy) != (45, 11):
                    t = m.get("decor", tx + dx, ty + dy)
                    if t and "trunk" in t:
                        m.set("decor", tx + dx, ty + dy, None)
                        m.set("decor", tx + dx + (1 if t.endswith("_l") else -1), ty + dy, None)
                        for fy in (ty + dy - 1, ty + dy - 2):
                            for fx in (tx + dx - 1, tx + dx, tx + dx + 1):
                                if (m.get("foreground", fx, fy) or "").startswith("dcanopy"):
                                    m.set("foreground", fx, fy, None)
    m.write("../../assets/maps/whisperwood_1.tmx")


if __name__ == "__main__":
    tiles.build("../../assets/maps/placeholder_tiles.png")
    hollowmere()
    whisperwood_1()
    print("maps written")
