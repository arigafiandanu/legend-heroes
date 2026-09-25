"""Battle sprites for the party (LH-48, 48×48, facing left toward the enemies).

The body comes from the character's overworld sheet (left-facing row: idle
and walk frames), snapped to LH-48. Weapons are drawn per pose on their
own layer and outlined, then laid over the body; slash smears and cast
glows are added on top. Lean and squash are applied to the whole frame
(enemies.transform), and the last KO frame lies the body down.

Output per character (same format as enemies.py):
  assets/images/party/<id>_battle.png   rows: idle, attack, cast, hit, ko
  assets/images/party/<id>_battle.json  per-frame ms, screen offsets, contact frame
"""
import json
import math
from dataclasses import dataclass, field

from PIL import Image

import palette
from enemies import transform
from pixel import Canvas

P = palette.RGB
STONE, BARK, EMBER, BLUE = P["stone"], P["bark"], P["ember"], P["blue"]
OUT = palette.OUTLINE
SIZE = 48
OX = 14  # body frame (32 wide) sits right of centre, leaving room for the weapon in front
SHOULDER = (OX + 9, 24)


def load_body_frames(sheet):
    """Left-facing row of an overworld sheet → palette-locked Canvases.
    Near-black shades collapse to the LH-48 outline colour."""
    img = Image.open(f"../../assets/images/{sheet}").convert("RGBA")
    frames = []
    for col in range(6):
        c = Canvas(32, 48)
        for y in range(48):
            for x in range(32):
                r, g, b, a = img.getpixel((col * 32 + x, 48 + y))
                if a < 128:
                    continue
                lum = 0.3 * r + 0.59 * g + 0.11 * b
                c.set(x, y, OUT if lum < 45 else palette.nearest((r, g, b)))
        frames.append(c)
    return frames


def _dir(angle):
    """Unit vector for `angle` degrees: 0 = toward the enemies (left), 90 = up."""
    a = math.radians(angle)
    return -math.cos(a), -math.sin(a)


def _line(c, x0, y0, dx, dy, length, colour, side=None, side_colour=None):
    """1px line from (x0, y0); optionally a second, darker line beside it."""
    t = 0.0
    while t <= length:
        x, y = round(x0 + dx * t), round(y0 + dy * t)
        c.set(x, y, colour)
        if side:
            c.set(x + side[0], y + side[1], side_colour)
        t += 0.4


def sword(c, hx, hy, angle, length=15):
    dx, dy = _dir(angle)
    _line(c, hx, hy, -dx, -dy, 2, BARK[1])  # grip behind the hand
    px, py = -dy, dx  # perpendicular
    for s in (-1, 1):  # crossguard
        c.set(round(hx + dx * 1.5 + px * s), round(hy + dy * 1.5 + py * s), EMBER[2])
    c.set(round(hx + dx * 1.5), round(hy + dy * 1.5), EMBER[1])
    # blade: bright edge on the lit (upper-left) side, darker edge beside it
    side = (0, 1) if abs(dx) > abs(dy) else (1, 0)
    _line(c, hx + dx * 2.5, hy + dy * 2.5, dx, dy, length - 3, STONE[3], side, STONE[2])
    c.set(round(hx + dx * length), round(hy + dy * length), P["white"][0])


def staff(c, hx, hy, angle, up=17, down=7):
    dx, dy = _dir(angle)
    side = (1, 0) if abs(dy) >= abs(dx) else (0, 1)
    _line(c, hx - dx * down, hy - dy * down, dx, dy, up + down, BARK[3], side, BARK[1])
    ox, oy = hx + dx * (up + 1.5), hy + dy * (up + 1.5)  # orb
    for yy in range(-2, 3):
        for xx in range(-2, 3):
            d = xx * xx + yy * yy
            if d <= 4:
                c.set(round(ox) + xx, round(oy) + yy, P["white"][0] if (xx, yy) == (-1, -1)
                      else BLUE[3] if d <= 2 and xx + yy <= 0 else BLUE[2])


def smear(c, cx, cy, r0, r1, a0, a1, colours=(P["cream"][1], P["white"][0])):
    """Slash arc between angles a0 → a1 (degrees, 0 = left, 90 = up)."""
    steps = int(abs(a1 - a0) * r1 / 25) + 4
    for i in range(steps + 1):
        a = a0 + (a1 - a0) * i / steps
        dx, dy = _dir(a)
        w = r0 + (r1 - r0) * math.sin(math.pi * i / steps)
        for k, rr in enumerate((w, w - 1)):
            c.set(round(cx + dx * rr), round(cy + dy * rr), colours[k])


def glow(c, cx, cy, big, colours):
    """Cast sparkle: a ring of points (bigger on the contact frame) + a core."""
    n, r = (10, 6) if big else (6, 4)
    for i in range(n):
        a = i * 360 / n + (18 if big else 0)
        dx, dy = _dir(a)
        c.set(round(cx + dx * r), round(cy + dy * r), colours[i % len(colours)])
    core = P["white"][0]
    for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)) if big else ((0, 0),):
        c.set(cx + dx, cy + dy, core)


@dataclass
class Pose:
    body: int = 0                 # overworld frame: 0–1 idle, 2–5 walk
    hand: tuple = None            # hand point in the 48×48 frame
    angle: float = 0              # weapon direction, 0 = toward enemies, 90 = up
    lean: float = 0               # px the top shears (+ = away from the enemies)
    squash: float = 0
    fx: list = field(default_factory=list)  # extra draw calls (smears, glows)
    lying: bool = False           # last KO frame: body laid down
    weapon: bool = True


def render(body_frames, weapon, pose, hand_idle):
    c = Canvas(SIZE, SIZE)
    body = body_frames[pose.body]
    if pose.lying:
        return lie_down(body)
    c.paste(body, OX, 0)
    if pose.weapon:
        w = Canvas(SIZE, SIZE)
        hx, hy = pose.hand or hand_idle
        # forearm from the shoulder, only where it sticks out of the body
        sx, sy = SHOULDER
        n = max(abs(hx - sx), abs(hy - sy), 1)
        for i in range(n + 1):
            x, y = round(sx + (hx - sx) * i / n), round(sy + (hy - sy) * i / n)
            for ax, ay in ((x, y), (x, y + 1)):
                if c.get(ax, ay) is None:
                    w.set(ax, ay, P["skin"][1] if ay == y else P["skin"][0])
        weapon(w, hx, hy, pose.angle)
        w.outline()
        c.paste(w, 0, 0)
        c.set(hx, hy, P["skin"][1])  # the hand over the grip
        c.set(hx + 1, hy, P["skin"][0])
    for fx in pose.fx:
        fx(c)
    c = transform(c, pose.lean, pose.squash)
    c.outline()
    return c


def lie_down(body):
    """Body rotated a quarter turn (head away from the enemies), on the ground."""
    img = body.image().rotate(-90, expand=True)  # 48×32, head to the right
    c = Canvas(SIZE, SIZE)
    bbox = img.getbbox()
    img = img.crop(bbox)
    ox, oy = (SIZE - img.width) // 2, SIZE - img.height
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = img.getpixel((x, y))
            if a:
                c.set(ox + x, oy + y, (r, g, b))
    c.outline()
    return c


def tip(hx, hy, angle, length=15):
    dx, dy = _dir(angle)
    return round(hx + dx * (length + 2)), round(hy + dy * (length + 2))


def kael():
    h = (OX + 10, 30)  # hand, idle
    sword_fx = lambda c: smear(c, OX + 8, 26, 10, 17, 70, -45)
    ember = [EMBER[1], EMBER[2], EMBER[3]]
    return sword, h, {
        "idle": [(Pose(0, h, -35), 260), (Pose(1, (h[0], h[1] + 1), -35), 260)],
        "attack": [
            (Pose(0, (OX + 13, 22), 115, lean=2), 110),                      # wind-up
            (Pose(3, (OX + 9, 20), 80, lean=-2), 60),
            (Pose(2, (OX + 6, 28), -20, lean=-3, fx=[sword_fx]), 140),     # contact
            (Pose(0, (OX + 9, 31), -65, lean=-1), 80),
            (Pose(0, h, -35), 90),
        ],
        "cast": [
            (Pose(0, (OX + 4, 24), 45), 140),
            (Pose(1, (OX + 2, 22), 60, fx=[lambda c: glow(c, *tip(OX + 2, 22, 60), False, ember)]), 120),
            (Pose(1, (OX + 2, 22), 60, fx=[lambda c: glow(c, *tip(OX + 2, 22, 60), True, ember)]), 200),  # contact
            (Pose(0, h, 20), 120),
        ],
        "hit": [(Pose(0, h, -25, lean=3), 80), (Pose(0, h, -30, lean=1), 80)],
        "ko": [
            (Pose(0, (OX + 11, 33), -80, lean=3), 120),
            (Pose(0, (OX + 8, 38), -95, lean=2, squash=0.25), 120),
            (Pose(0, lying=True), 240),
        ],
    }


def lira():
    h = (OX + 2, 30)  # staff held out in front, clear of her face
    light = [BLUE[3], P["cream"][1], BLUE[2]]
    orb_at = lambda hx, hy, angle: (round(hx + _dir(angle)[0] * 18.5), round(hy + _dir(angle)[1] * 18.5))
    return staff, h, {
        "idle": [(Pose(0, h, 95), 260), (Pose(1, (h[0], h[1] + 1), 95), 260)],
        "attack": [
            (Pose(0, (OX + 12, 26), 120, lean=2), 110),
            (Pose(3, (OX + 9, 24), 80, lean=-2), 60),
            (Pose(2, (OX + 7, 29), 15, lean=-3,
                  fx=[lambda c: smear(c, OX + 7, 29, 14, 20, 60, 5)]), 140),  # contact
            (Pose(0, (OX + 9, 30), -20, lean=-1), 80),
            (Pose(0, h, 95), 90),
        ],
        "cast": [
            (Pose(0, (OX + 3, 27), 75), 140),
            (Pose(1, (OX + 2, 25), 65, fx=[lambda c: glow(c, *orb_at(OX + 2, 25, 65), False, light)]), 120),
            (Pose(1, (OX + 2, 25), 65, fx=[lambda c: glow(c, *orb_at(OX + 2, 25, 65), True, light)]), 200),
            (Pose(0, h, 95), 120),
        ],
        "hit": [(Pose(0, h, 100, lean=3), 80), (Pose(0, h, 97, lean=1), 80)],
        "ko": [
            (Pose(0, (OX + 11, 32), 130, lean=3), 120),
            (Pose(0, (OX + 9, 38), 160, lean=2, squash=0.25), 120),
            (Pose(0, lying=True), 240),
        ],
    }


# Screen offsets per frame (−x = toward the enemies); the same for everyone.
OFFSETS = {
    "idle": [(0, 0), (0, 0)],
    "attack": [(3, 0), (-8, 0), (-16, 0), (-8, 0), (-2, 0)],
    "cast": [(0, 0)] * 4,
    "hit": [(4, 0), (2, 0)],
    "ko": [(3, 0), (4, 0), (4, 0)],
}
CONTACT = {"attack": 2, "cast": 2}
ROWS = ["idle", "attack", "cast", "hit", "ko"]
PARTY = {"kael": ("kael_sheet.png", kael), "lira": ("lira_sheet.png", lira)}


def build(out_dir):
    import os
    os.makedirs(out_dir, exist_ok=True)
    for cid, (sheet, spec) in PARTY.items():
        body = load_body_frames(sheet)
        weapon, hand, anims = spec()
        cols = max(len(anims[r]) for r in ROWS)
        out = Canvas(SIZE * cols, SIZE * len(ROWS))
        meta = {"size": SIZE, "anchor": "bottomCenter", "shadowX": OX + 16, "anims": {}}
        for row, name in enumerate(ROWS):
            for col, (pose, _) in enumerate(anims[name]):
                out.paste(render(body, weapon, pose, hand), col * SIZE, row * SIZE)
            meta["anims"][name] = {"row": row, "frames": len(anims[name]), "loop": name == "idle",
                                   "ms": [ms for _, ms in anims[name]],
                                   "offsets": [list(o) for o in OFFSETS[name]]}
            if name in CONTACT:
                meta["anims"][name]["contact"] = CONTACT[name]
        out.image().save(f"{out_dir}/{cid}_battle.png")
        with open(f"{out_dir}/{cid}_battle.json", "w") as f:
            json.dump(meta, f, indent=1)
    return list(PARTY)


if __name__ == "__main__":
    print(build("../../assets/images/party"), "written")
