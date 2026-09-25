"""Battle sprites for the Whisperwood enemies (LH-48, 48×48, facing right).

Each enemy is built from shaded primitives (ellipses and tapered tubes, lit
from the top-left) painted back to front, plus hand-placed details. A Pose
drives the drawing (idle phase, attack extension, eye state); lean and
squash are applied to the whole sprite afterwards, then the 1px outline.

Output per enemy (art bible §7, §10):
  assets/images/enemies/<id>_battle.png   one row per animation, one column per frame
  assets/images/enemies/<id>_battle.json  rows, per-frame ms and offsets for the engine
Sprite frames only hold the pose; how far the enemy lunges, recoils or
falls is the `offsets` list, applied to its position by the engine.
"""
import json
import math
from dataclasses import dataclass

import palette
from pixel import Canvas, shade

P = palette.RGB
LEAF, MOSS, STONE, BARK, ASH, EMBER = P["leaf"], P["moss"], P["stone"], P["bark"], P["ash"], P["ember"]
OUT = palette.OUTLINE


def _light(nx, ny, d, bias, soft=0.14):
    return 0.5 + (-nx * 0.45 - ny * 0.7) * 0.5 - d * soft + bias


def ellipse(c, cx, cy, rx, ry, ramp, bias=0.0, angle=0.0):
    """Shaded ellipse rotated by `angle` (radians)."""
    ca, sa = math.cos(angle), math.sin(angle)
    r = max(rx, ry)
    for y in range(math.floor(cy - r) - 1, math.ceil(cy + r) + 1):
        for x in range(math.floor(cx - r) - 1, math.ceil(cx + r) + 1):
            px, py = x + 0.5 - cx, y + 0.5 - cy
            u, v = (px * ca + py * sa) / rx, (-px * sa + py * ca) / ry
            d = u * u + v * v
            if d <= 1:
                nx, ny = u * ca - v * sa, u * sa + v * ca
                c.set(x, y, shade(ramp, _light(nx, ny, d, bias), x, y, dither=False))


def tube(c, pts, r0, r1, ramp, bias=0.0):
    """Tapered tube along a polyline (legs, tails, stems), shaded round."""
    segs = list(zip(pts, pts[1:]))
    lengths = [math.dist(a, b) for a, b in segs]
    total = sum(lengths)
    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
    rm = max(r0, r1)
    for y in range(math.floor(min(ys) - rm) - 1, math.ceil(max(ys) + rm) + 1):
        for x in range(math.floor(min(xs) - rm) - 1, math.ceil(max(xs) + rm) + 1):
            px, py = x + 0.5, y + 0.5
            best, run = None, 0.0
            for ((x0, y0), (x1, y1)), ln in zip(segs, lengths):
                dx, dy = x1 - x0, y1 - y0
                t = max(0.0, min(1.0, ((px - x0) * dx + (py - y0) * dy) / (dx * dx + dy * dy)))
                qx, qy = x0 + t * dx, y0 + t * dy
                dist = math.hypot(px - qx, py - qy)
                if best is None or dist < best[0]:
                    best = (dist, qx, qy, (run + t * ln) / total)
                run += ln
            dist, qx, qy, s = best
            rad = r0 + (r1 - r0) * s
            if dist <= rad:
                nx, ny = (px - qx) / rad, (py - qy) / rad
                c.set(x, y, shade(ramp, _light(nx, ny, nx * nx + ny * ny, bias, 0.08), x, y, dither=False))


def poly(c, pts, ramp, bias=0.0):
    """Flat-ish polygon (ears, spikes): lighter toward its top-left."""
    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
    w, h = max(xs) - min(xs) or 1, max(ys) - min(ys) or 1
    for y in range(math.floor(min(ys)), math.ceil(max(ys)) + 1):
        for x in range(math.floor(min(xs)), math.ceil(max(xs)) + 1):
            if _inside(pts, x + 0.5, y + 0.5):
                t = 0.75 - (x - min(xs)) / w * 0.35 - (y - min(ys)) / h * 0.35 + bias
                c.set(x, y, shade(ramp, t, x, y, dither=False))


def _inside(pts, x, y):
    inside = False
    for (x0, y0), (x1, y1) in zip(pts, pts[1:] + pts[:1]):
        if (y0 > y) != (y1 > y) and x < x0 + (y - y0) * (x1 - x0) / (y1 - y0):
            inside = not inside
    return inside


def dots(c, colour, *pts):
    for x, y in pts:
        c.set(x, y, colour)


@dataclass(frozen=True)
class Pose:
    f: int = 0            # idle phase (0/1)
    act: float = 0.0      # attack extension, 0 = rest, 1 = full strike
    eyes: str = "glow"    # glow | shut | ko
    lean: float = 0.0     # px the top of the sprite shears (+ = toward the party)
    squash: float = 0.0   # fraction of height removed, feet stay planted


def eye(c, x, y, p, dark=False):
    """2×2 eye. Hostile ember glow (or dark with a glint), a shut line, or KO cross."""
    if p.eyes == "shut":
        dots(c, OUT, (x - 1, y + 1), (x, y + 1), (x + 1, y + 1))
    elif p.eyes == "ko":
        dots(c, OUT, (x - 1, y - 1), (x + 1, y - 1), (x, y), (x - 1, y + 1), (x + 1, y + 1))
    elif dark:
        dots(c, P["night"][0], (x, y), (x + 1, y), (x, y + 1), (x + 1, y + 1))
        c.set(x, y, P["white"][0])
    else:
        c.set(x, y, EMBER[3])
        c.set(x + 1, y, EMBER[2])
        c.set(x, y + 1, EMBER[0])
        c.set(x + 1, y + 1, P["red"][1])


def mouth(c, x0, x1, y, open_, teeth=()):
    """Jagged mouth line; when open, a dark-red inside below it."""
    for i, x in enumerate(range(x0, x1 + 1)):
        c.set(x, y + (i % 2 if not open_ else 0), OUT)
        if open_:
            c.set(x, y + 1, P["red"][0] if x0 < x < x1 else OUT)
            if x0 < x < x1:
                c.set(x, y + 2, OUT)
    for x in teeth:
        c.set(x, y + (1 if open_ else 0), P["cream"][1])


def transform(c, lean, squash):
    """Shear the sprite by `lean` px at the top and squash it toward its feet."""
    filled = [y for y in range(c.h) if any(c.px[y])]
    if not filled or (not lean and not squash):
        return c
    top, bottom = min(filled), max(filled)
    out = Canvas(c.w, c.h)
    for y in range(c.h):
        sy = bottom - round((bottom - y) / (1 - squash)) if squash else y
        if not top <= sy <= bottom:
            continue
        shift = round(lean * (bottom - y) / (bottom - top + 1))
        for x in range(c.w):
            col = c.get(x - shift, sy)
            if col is not None:
                out.set(x, y, col)
    return out


# ------------------------------------------------------------ Ashen Rat

RAT_FUR = [ASH[0], ASH[1], STONE[2], P["cream"][0]]
RAT_PINK = [P["pink"][0], P["pink"][1]]


def ashen_rat(p):
    """Ash-touched rat: hunched grey-purple body, spiky ember-cracked back."""
    c = Canvas(48, 48)
    b, a = p.f, p.act
    hx = 1.5 * a  # the head snaps forward to bite
    tube(c, [(12, 38), (5, 32), (4, 24), (8, 17 + p.f - 3 * a)], 2.6, 1.1, [ASH[1], ASH[2]])  # tail
    ellipse(c, 28, 20 + b, 3.8, 4.5, RAT_FUR, -0.3)  # far ear
    for x0, x1, y0 in ((11, 8, 24), (15.5, 14, 21), (20, 20, 20.5), (24, 25, 21.5)):  # back spikes
        tube(c, [(x0 + 2, y0 + 5 + b), (x1, y0 + b - a)], 2.4, 0.5, RAT_FUR, 0.05)
    ellipse(c, 12.5, 42, 3, 2.2, RAT_FUR, -0.35)  # far feet
    ellipse(c, 26, 42, 3, 2.2, RAT_FUR, -0.35)
    ellipse(c, 20, 33 + b * 0.5, 14, 9.8 - b * 0.5, RAT_FUR)  # body
    ellipse(c, 23, 39, 8, 3, [STONE[2], P["cream"][0]], 0.1)  # belly
    ellipse(c, 33.5 + hx, 28.5 + b, 10, 8.8, RAT_FUR, 0.05, angle=-0.2)  # head
    ellipse(c, 40 + hx, 31.5 + b, 4.8, 3.6, RAT_FUR, 0.12)  # snout
    ellipse(c, 31 + hx * 0.5, 19 + b, 4.5, 5.2, RAT_FUR, 0.1)  # near ear
    ellipse(c, 32 + hx * 0.5, 20.5 + b, 2.1, 3, RAT_PINK, -0.1)
    ellipse(c, 15.5, 43.5, 3.6, 2.1, RAT_PINK)  # near feet
    ellipse(c, 30.5 + a, 43.5, 3.6, 2.1, RAT_PINK)
    hx, y = round(hx), round(b)
    eye(c, 35 + hx, 25 + y, p)
    dots(c, P["pink"][1], (44 + hx, 30 + y), (44 + hx, 31 + y))  # nose
    dots(c, P["pink"][0], (43 + hx, 31 + y))
    mouth(c, 38 + hx, 42 + hx, 34 + y, a > 0.5, teeth=(40 + hx, 41 + hx))
    for x, yy in ((14, 27), (18, 25), (24, 25), (28, 26)):  # ember cracks
        dots(c, EMBER[1], (x, yy + y), (x + 1, yy + 1 + y))
        dots(c, EMBER[3], (x + 1, yy + y))
    return c


# ------------------------------------------------------------ Wisp Moth

WING = [P["blue"][1], P["blue"][2], P["blue"][3], P["cream"][1]]
MOTH = [STONE[1], STONE[2], P["cream"][0], P["cream"][1]]


def wing(c, root, pts, bias=0.0, lift=0.0):
    """Moth wing: dark blue at the root fading to a pale rim, lit top-left.
    `lift` folds the wing toward its root vertically (negative spreads it)."""
    rx, ry = root
    pts = [(x, ry + (y - ry) * (1 - lift)) for x, y in pts]
    mask = {(x, y) for y in range(c.h) for x in range(c.w) if _inside(pts, x + 0.5, y + 0.5)}
    far = max(math.dist(root, q) for q in pts)
    for x, y in mask:
        t = 0.15 + math.dist(root, (x, y)) / far * 0.75 + bias - (y - ry) / far * 0.12
        rim = any((x + dx, y + dy) not in mask for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        c.set(x, y, P["cream"][1] if rim and t > 0.78 else shade(WING, t - (0.12 if rim else 0), x, y, dither=False))
    return mask


def wisp_moth(p):
    """Pale glowing moth: banded wings with an eyespot, fuzzy body, lantern antennae."""
    c = Canvas(48, 48)
    up = -p.f  # the moth rises a pixel while its wings fold
    lift = 0.14 * p.f - 0.12 * p.act  # wings flare wide to cast
    if p.eyes == "ko":
        lift = 0.35  # wings folded as it drops
    sh = lambda pts: [(x, y + up) for x, y in pts]
    wing(c, (29, 22 + up), sh([(28, 21), (30, 10), (36, 4), (42, 5), (43, 11), (39, 18), (31, 24)]), -0.3, lift)
    wing(c, (28, 27 + up), sh([(28, 26), (35, 29), (37, 35), (34, 40), (28, 35)]), -0.3, lift * 0.5)
    tube(c, [(19, 33 + up), (27, 24 + up)], 3.2, 4, MOTH)  # abdomen
    for i in range(3):  # abdomen bands
        dots(c, STONE[1], (20 + i * 2, 32 - i * 2 + up), (21 + i * 2, 32 - i * 2 + up))
    ellipse(c, 31, 20 + up, 4.2, 4, MOTH, 0.1)  # head
    wing(c, (25, 24 + up), sh([(26, 23), (21, 14), (13, 5), (5, 4), (3, 9), (5, 17), (12, 24), (21, 27)]), 0.05, lift)
    wing(c, (22, 28 + up), sh([(23, 27), (13, 27), (7, 32), (8, 39), (14, 42), (20, 37), (24, 31)]), 0.0, lift * 0.5)
    ex, ey = 11, round(11 + up + (24 - 11) * lift * 0.6)  # eyespot rides with the wing
    ellipse(c, ex, ey, 2.8, 2.8, [P["blue"][0]])
    ellipse(c, ex, ey, 1.7, 1.7, [EMBER[2] if p.act < 0.5 else EMBER[3]])
    dots(c, P["cream"][1], (ex - 1, ey - 1))
    ellipse(c, 13, 34 + up, 1.6, 1.6, [P["blue"][0]])  # lower wing spot
    dots(c, P["cream"][1], (27, 17 + up), (28, 16 + up), (29, 17 + up), (26, 18 + up))  # fuzzy collar
    tube(c, [(32, 17 + up), (35, 12 + up), (38, 9 + up)], 0.6, 0.5, [STONE[1], STONE[2]])  # antennae
    tube(c, [(30, 17 + up), (31, 11 + up), (33, 7 + up)], 0.6, 0.5, [STONE[0], STONE[1]])
    dots(c, EMBER[3], (38, 8 + up), (33, 6 + up))
    dots(c, P["cream"][1], (39, 8 + up), (34, 6 + up))
    if p.act > 0.5:  # lanterns flare while casting
        dots(c, EMBER[2], (39, 7 + up), (37, 8 + up), (34, 5 + up), (32, 6 + up))
        dots(c, P["white"][0], (38, 8 + up), (33, 6 + up))
    eye(c, 33, 19 + up, p, dark=True)
    dots(c, STONE[0], (24, 35 + up), (25, 36 + up), (28, 34 + up), (29, 35 + up))  # legs
    return c


# ------------------------------------------------------------ Blight Sprout

SPROUT = [LEAF[1], MOSS[0], MOSS[1], MOSS[2]]
ROOT = [BARK[0], BARK[1], BARK[2], BARK[3]]
LEAVES = [LEAF[1], LEAF[2], LEAF[3], LEAF[4]]


def blight_sprout(p):
    """Walking bulb half-eaten by Ashblight: leaf crown, root legs, angry face."""
    c = Canvas(48, 48)
    b, a = p.f, p.act
    sway = 0.12 * (1 if p.f else -1) - 0.45 * a  # leaves whip forward to strike
    tube(c, [(23, 39), (23, 46)], 2, 1.4, ROOT, -0.3)  # far root
    ellipse(c, 30 + 2 * a, 14 + b + 3 * a, 7.5, 3, ASH, -0.1, angle=-0.55 + sway)  # blighted back leaf
    dots(c, EMBER[1], (29 + round(2 * a), 14 + b + round(3 * a)), (32 + round(2 * a), 12 + b + round(3 * a)))
    tube(c, [(22, 26 + b), (22 + a, 18 + b)], 2.6, 1.6, [LEAF[1], LEAF[2], LEAF[3]])  # stem
    ellipse(c, 15 + 3 * a, 16 + b - a, 7.5, 3.2, LEAVES, 0.05, angle=0.55 + sway)  # left leaf
    ellipse(c, 22.5 + 2 * a, 10 + b, 2.6, 5.5, LEAVES, 0.1, angle=0.25 + sway)  # top leaf
    if a < 0.5:
        for i in range(4):  # leaf midribs
            dots(c, LEAF[1], (12 + i * 2, 13 + i + b))
    tube(c, [(17, 38), (13, 46)], 2.4, 1.5, ROOT)  # roots
    tube(c, [(27, 38), (31 + a, 46)], 2.4, 1.5, ROOT)
    ellipse(c, 22, 32 + b * 0.5, 10.5, 9 - b * 0.5, SPROUT)  # bulb
    ellipse(c, 15.5, 36, 5.5, 3.8, ASH, -0.05)  # Ashblight patch
    dots(c, EMBER[1], (13, 35), (14, 36), (16, 37), (17, 36))
    dots(c, EMBER[3], (15, 36))
    dots(c, MOSS[2], (16, 25 + b), (17, 24 + b), (18, 24 + b))  # rim light
    dots(c, OUT, (24, 28 + b), (25, 29 + b), (30, 29 + b), (31, 28 + b))  # angry brows
    eye(c, 25, 30 + b, p)
    eye(c, 29, 30 + b, p)
    mouth(c, 24, 31, 35 + b, a > 0.5, teeth=(25, 29))
    return c


# ------------------------------------------------------------ Moss Wolf

WOLF = [P["night"][0], P["teal"][0], P["teal"][1], STONE[2]]
MANE = [LEAF[1], MOSS[0], MOSS[1], MOSS[2]]


def moss_wolf(p):
    """Teal-grey wolf wearing a mane of moss: big head, stocky legs."""
    c = Canvas(48, 48)
    b, a = p.f, p.act
    hx = 1.5 * a  # head thrusts forward, jaw drops, front paw lifts
    tube(c, [(29, 36), (29, 45)], 2.4, 2, WOLF, -0.3)  # far front leg
    tube(c, [(13, 36), (12, 45)], 2.4, 2, WOLF, -0.3)  # far back leg
    ellipse(c, 6, 28 + p.f * 0.5 - 2 * a, 6, 3.4, WOLF, 0.02, angle=0.75 - p.f * 0.1 + 0.3 * a)  # bushy tail
    ellipse(c, 3, 24 + p.f - 2 * a, 2.6, 2.2, MANE, 0.1)
    ellipse(c, 20, 33, 11, 7, WOLF)  # torso
    ellipse(c, 30, 31 + b * 0.5, 7, 8, WOLF, 0.02)  # chest
    ellipse(c, 14, 34, 6, 6, WOLF, 0.05)  # haunch
    tube(c, [(16, 37), (16, 45)], 3, 2.4, WOLF, 0.05)  # near back leg
    tube(c, [(33, 36), (34 + 2 * a, 45 - 3 * a)], 2.8, 2.3, WOLF, 0.05)  # near front leg
    for x, y in ((12, 45.5), (16, 45.5), (29, 45.5), (34 + 2 * a, 45.5 - 3 * a)):  # paws
        ellipse(c, x + 1, y, 2.6, 1.3, WOLF, -0.1)
    poly(c, [(30 + hx, 16 + b), (32 + hx, 7 + b), (36 + hx, 13 + b)], WOLF, -0.3)  # far ear
    ellipse(c, 36 + hx, 21 + b, 7.5, 7, WOLF, 0.05)  # head
    if a > 0.3:
        ellipse(c, 41.5 + hx, 27.5 + b + a, 3.4, 1.4 + a, [P["red"][0]])  # open mouth
    ellipse(c, 42.5 + hx, 25 + b, 4, 3, WOLF, 0.1)  # snout
    ellipse(c, 41.5 + hx, 28 + b + 2 * a, 3, 1.3, WOLF, -0.25)  # jaw
    poly(c, [(34 + hx, 16 + b), (38 + hx, 6 + b), (41 + hx, 15 + b)], WOLF, 0.05)  # near ear
    hx = round(hx)
    dots(c, P["pink"][0], (38 + hx, 11 + b), (38 + hx, 12 + b), (38 + hx, 13 + b))
    # moss mane over neck and back, clumps lit from the top-left
    for x, y, r in ((29, 23, 3.8), (26, 26, 3.6), (31, 27, 3.2), (21, 27, 3.4), (16, 28, 3.2), (11, 29, 2.8),
                    (32, 17, 3.0), (29, 19, 3.0), (25, 29, 2.8)):
        ellipse(c, x + (hx if x > 28 else 0), y + (b if x > 22 else 0), r, r * 0.85, MANE, 0.05)
    dots(c, MOSS[0], (28, 32 + b), (30, 32 + b), (23, 31), (19, 31))  # hanging moss
    dots(c, LEAF[1], (28, 33 + b), (23, 32))
    dots(c, OUT, (38 + hx, 18 + b), (39 + hx, 18 + b), (40 + hx, 17 + b))  # brow
    eye(c, 39 + hx, 19 + b, p)
    dots(c, P["night"][0], (46 + min(hx, 0), 24 + b))  # nose
    fy = 27 + b + (1 if a > 0.3 else 0)
    dots(c, P["cream"][1], (41 + hx, fy), (44 + hx, fy))  # fangs
    if a > 0.3:
        dots(c, P["cream"][1], (42 + hx, 28 + b + round(2 * a)))  # lower fang
    return c


ENEMIES = {
    "ashen_rat": ashen_rat,
    "wisp_moth": wisp_moth,
    "blight_sprout": blight_sprout,
    "moss_wolf": moss_wolf,
}
SIZE = 48

# name, loops?, frames: (pose, ms, engine offset (dx, dy) in px; +dx = toward the party)
ANIMS = [
    ("idle", True, [(Pose(f=0), 260, (0, 0)), (Pose(f=1), 260, (0, 0))]),
    ("attack", False, [
        (Pose(act=0, lean=-2, squash=0.03), 110, (-2, 0)),  # anticipation
        (Pose(act=0.6, lean=2), 60, (8, 0)),
        (Pose(act=1, lean=3), 140, (14, 0)),  # contact, held 2×
        (Pose(act=0.5, lean=1), 80, (8, 0)),
        (Pose(act=0), 90, (2, 0)),
    ]),
    ("hit", False, [(Pose(eyes="shut", lean=-3), 80, (-4, 0)), (Pose(eyes="shut", lean=-1), 80, (-2, 0))]),
    ("ko", False, [
        (Pose(eyes="shut", lean=-3), 120, (-3, 0)),
        (Pose(eyes="ko", lean=-2, squash=0.2), 120, (-4, 0)),
        (Pose(eyes="ko", squash=0.4), 240, (-4, 0)),  # last frame is held; the engine fades it
    ]),
]
# A flyer drops to the ground instead of slumping in place.
OFFSET_OVERRIDES = {"wisp_moth": {"ko": [(-3, 2), (-4, 6), (-4, 9)]}}


def frame(draw, pose):
    c = transform(draw(pose), pose.lean, pose.squash)
    c.outline()
    return c


def build(out_dir):
    import os
    os.makedirs(out_dir, exist_ok=True)
    cols = max(len(frames) for _, _, frames in ANIMS)
    for name, draw in ENEMIES.items():
        sheet = Canvas(SIZE * cols, SIZE * len(ANIMS))
        meta = {"size": SIZE, "anchor": "bottomCenter", "anims": {}}
        for row, (anim, loop, frames) in enumerate(ANIMS):
            for col, (pose, _, _) in enumerate(frames):
                sheet.paste(frame(draw, pose), col * SIZE, row * SIZE)
            offsets = OFFSET_OVERRIDES.get(name, {}).get(anim, [o for _, _, o in frames])
            meta["anims"][anim] = {"row": row, "frames": len(frames), "loop": loop,
                                   "ms": [ms for _, ms, _ in frames], "offsets": [list(o) for o in offsets]}
        sheet.image().save(f"{out_dir}/{name}_battle.png")
        with open(f"{out_dir}/{name}_battle.json", "w") as f:
            json.dump(meta, f, indent=1)
    return list(ENEMIES)


if __name__ == "__main__":
    print(build("../../assets/images/enemies"), "written")
