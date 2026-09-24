"""Renders a .tmx to PNG (layers + collision boxes + objects) for review."""
import sys
import xml.etree.ElementTree as ET

from PIL import Image, ImageDraw

T = 16


def render(tmx, out, scale=2):
    root = ET.parse(tmx).getroot()
    w, h = int(root.get("width")), int(root.get("height"))
    sheet = Image.open(tmx.rsplit("/", 1)[0] + "/placeholder_tiles.png").convert("RGBA")
    cols = sheet.width // T
    img = Image.new("RGBA", (w * T, h * T), (0, 0, 0, 255))
    for layer in root.findall("layer"):
        data = [int(v) for v in layer.find("data").text.replace("\n", "").split(",")]
        for i, gid in enumerate(data):
            if gid:
                tid = gid - 1
                tile = sheet.crop(((tid % cols) * T, (tid // cols) * T, (tid % cols + 1) * T, (tid // cols + 1) * T))
                img.alpha_composite(tile, ((i % w) * T, (i // w) * T))
    d = ImageDraw.Draw(img)
    for group in root.findall("objectgroup"):
        for o in group.findall("object"):
            x, y = float(o.get("x")), float(o.get("y"))
            ow, oh = float(o.get("width", 0)), float(o.get("height", 0))
            if group.get("name") == "collision":
                d.rectangle([x, y, x + ow - 1, y + oh - 1], outline=(255, 60, 60, 160))
            else:
                color = {"spawn": (80, 200, 255), "npc": (255, 230, 80), "chest": (255, 150, 40),
                         "exit": (200, 80, 255), "campfire": (255, 90, 40)}.get(o.get("class"), (255, 255, 255))
                if ow:
                    d.rectangle([x, y, x + ow - 1, y + oh - 1], outline=color, width=2)
                else:
                    d.ellipse([x - 4, y - 4, x + 4, y + 4], fill=color)
                d.text((x + 2, y - 10), o.get("name"), fill=color)
    img.resize((w * T * scale // 2, h * T * scale // 2), Image.NEAREST).save(out)


if __name__ == "__main__":
    render(sys.argv[1], sys.argv[2])
