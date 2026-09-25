"""Villager sheets by palette swap (LH-48) until NPCs get their own art.

Each NPC is a hero's overworld sheet (same 192×192 layout, 32×48 frames)
with some colour ramps swapped for others, index for index. A rule can be
limited to the head (the top rows of each frame) so e.g. Kael's hair
changes but his boots, which use the same browns, do not.

Output: assets/images/npc/<name>_sheet.png
"""
from PIL import Image

import palette
from pixel import Canvas

RAMP_OF = {c: (name, i) for name, ramp in palette.RGB.items() for i, c in enumerate(ramp)}
FRAME_H = 48
HEAD_ROWS = 21

# name: (base sheet, {(region, source ramp): target ramp}); region is head, body or * (both).
NPCS = {
    "elder": ("kael_sheet.png", {("head", "bark"): "stone", ("body", "blue"): "bark", ("*", "red"): "dirt"}),
    "guard": ("kael_sheet.png", {("head", "bark"): "night", ("body", "blue"): "stone", ("*", "red"): "blue"}),
    "hunter": ("kael_sheet.png", {("head", "bark"): "dirt", ("body", "blue"): "moss", ("*", "red"): "bark"}),
    "merchant": ("lira_sheet.png", {("*", "ember"): "bark", ("*", "dirt"): "bark", ("body", "leaf"): "ember"}),
    "child": ("lira_sheet.png", {("body", "leaf"): "blue"}),
}


def swap(col, rules, head):
    name, i = RAMP_OF[col]
    target = rules.get(("head" if head else "body", name)) or rules.get(("*", name))
    if not target:
        return col
    src, dst = palette.RGB[name], palette.RGB[target]
    j = round(i * (len(dst) - 1) / max(1, len(src) - 1))
    return dst[j]


def recolour(sheet, rules):
    img = Image.open(f"../../assets/images/{sheet}").convert("RGBA")
    c = Canvas(img.width, img.height)
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = img.getpixel((x, y))
            if a < 128:
                continue
            lum = 0.3 * r + 0.59 * g + 0.11 * b
            col = palette.OUTLINE if lum < 45 else palette.nearest((r, g, b))
            c.set(x, y, swap(col, rules, y % FRAME_H < HEAD_ROWS))
    return c


if __name__ == "__main__":
    import os
    os.makedirs("../../assets/images/npc", exist_ok=True)
    for name, (sheet, rules) in NPCS.items():
        recolour(sheet, rules).image().save(f"../../assets/images/npc/{name}_sheet.png")
    print(list(NPCS), "written")
