"""Renders a .tmx to PNG for review: tile layers, y-sorted props, chests and
NPCs as the game draws them (without lighting). `--debug` also outlines
collision boxes and objects.

Usage: python3 preview.py ../../assets/maps/hollowmere.tmx out.png [--debug]
"""
import json
import os
import sys
import xml.etree.ElementTree as ET

from PIL import Image, ImageDraw

T = 16
ASSETS = os.path.join(os.path.dirname(__file__), "..", "..", "assets")


def _img(*path):
    return Image.open(os.path.join(ASSETS, *path)).convert("RGBA")


def render(tmx, out, scale=2, debug=False):
    root = ET.parse(tmx).getroot()
    w, h = int(root.get("width")), int(root.get("height"))
    props = {p.get("name"): p.get("value") for p in root.find("properties")}
    ts = root.find("tileset")
    sheet = _img("maps", ts.find("image").get("source"))
    cols = int(ts.get("columns"))
    img = Image.new("RGBA", (w * T, h * T), (0, 0, 0, 255))
    for layer in root.findall("layer"):
        if layer.get("name") == "foreground":
            continue
        data = [int(v) for v in layer.find("data").text.replace("\n", "").split(",")]
        for i, gid in enumerate(data):
            if gid:
                tid = gid - 1
                tile = sheet.crop(((tid % cols) * T, (tid // cols) * T, (tid % cols + 1) * T, (tid // cols + 1) * T))
                img.alpha_composite(tile, ((i % w) * T, (i // w) * T))

    groups = {g.get("name"): g.findall("object") for g in root.findall("objectgroup")}
    drawables = []  # (base y, image, left, top)
    if "props" in props:
        frames = json.load(open(os.path.join(ASSETS, "data", f"props_{props['props']}.json")))
        psheet = _img("images", "props", f"{props['props']}_props.png")
        for o in groups.get("props", []):
            f = frames[o.get("name")]
            x, y = float(o.get("x")), float(o.get("y"))
            spr = psheet.crop((f["x"], f["y"], f["x"] + f["w"], f["y"] + f["h"]))
            drawables.append((y, spr, int(x - f["w"] / 2), int(y - f["h"])))
    chest = _img("images", "props", "chest.png").crop((0, 0, 16, 16))
    for o in groups.get("objects", []):
        x, y = float(o.get("x")), float(o.get("y"))
        cls = o.get("class")
        if cls == "chest":
            drawables.append((y + 16, chest, int(x), int(y)))
        elif cls == "npc":
            sheet_name = next(p.get("value") for p in o.iter("property") if p.get("name") == "sheet")
            spr = _img("images", sheet_name).crop((0, 0, 32, 48))
            drawables.append((y, spr, int(x - 16), int(y - 48)))
    for _, spr, left, top in sorted(drawables, key=lambda d: d[0]):
        if top < 0:
            spr, top = spr.crop((0, -top, spr.width, spr.height)), 0
        img.alpha_composite(spr, (left, top))

    if debug:
        d = ImageDraw.Draw(img)
        for o in groups.get("collision", []):
            x, y, ow, oh = (float(o.get(k)) for k in ("x", "y", "width", "height"))
            d.rectangle([x, y, x + ow - 1, y + oh - 1], outline=(255, 60, 60, 200))
        for o in groups.get("objects", []):
            x, y = float(o.get("x")), float(o.get("y"))
            ow, oh = float(o.get("width", 0)), float(o.get("height", 0))
            color = {"spawn": (80, 200, 255), "npc": (255, 230, 80), "chest": (255, 150, 40),
                     "exit": (200, 80, 255), "campfire": (255, 90, 40)}.get(o.get("class"), (255, 255, 255))
            if ow:
                d.rectangle([x, y, x + ow - 1, y + oh - 1], outline=color, width=1)
            else:
                d.ellipse([x - 3, y - 3, x + 3, y + 3], fill=color)
    img.resize((w * T * scale, h * T * scale), Image.NEAREST).save(out)


if __name__ == "__main__":
    render(sys.argv[1], sys.argv[2], debug="--debug" in sys.argv)
