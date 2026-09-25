"""Composes a 480×270 Whisperwood battle screen to judge the battle art in
context: the area backdrop, enemies on the left facing right, the party
on the right. Engine effects (shadows, forest overlay) are faked as in
mock_scene.py."""
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

import palette

T = 16
W, H = 480, 270

img = Image.open("../../assets/images/backdrops/whisperwood.png").convert("RGBA")

enemies = [("moss_wolf", 48, 120, 196), ("ashen_rat", 48, 70, 150), ("blight_sprout", 48, 170, 150),
           ("wisp_moth", 48, 60, 232)]
frame = int(next((a[2:] for a in sys.argv[1:] if a.startswith("-f")), "0"))
shadows = Image.new("L", (W, H), 0)
d = ImageDraw.Draw(shadows)
for name, size, bx, by in enemies:
    rx = size * 0.38
    lift = 8 if name == "wisp_moth" else 0
    d.ellipse([bx - rx, by + lift - 3, bx + rx, by + lift + 3], fill=120)
party = [Image.open(f"../../assets/images/party/{n}_battle.png").convert("RGBA").crop((0, 0, 48, 48))
         for n in ("kael", "lira")]
party_pos = [(380, 170), (420, 214)]
for bx, by in party_pos:
    d.ellipse([bx - 9, by - 3, bx + 9, by + 2], fill=120)
img = Image.composite(Image.new("RGBA", (W, H), (*palette.RGB["night"][0], 255)), img, shadows.point(lambda a: a // 2))

for name, size, bx, by in sorted(enemies, key=lambda e: e[3]):
    sheet = Image.open(f"../../assets/images/enemies/{name}_battle.png").convert("RGBA")
    img.alpha_composite(sheet.crop((frame * size, 0, (frame + 1) * size, size)), (bx - size // 2, by - size))
for im, (bx, by) in zip(party, party_pos):
    img.alpha_composite(im, (bx - 24, by - 48))

tint = Image.new("RGB", (W, H))
td = ImageDraw.Draw(tint)
for y in range(H):
    k = 0.74 + 0.2 * min(1, y / (H * 0.6))  # darker under the canopy at the back
    td.line([(0, y), (W, y)], fill=(int(205 * k), int(225 * k), int(222 * k)))
rgb = ImageChops.multiply(img.convert("RGB"), tint)
light = Image.new("L", (W, H), 0)
ImageDraw.Draw(light).ellipse([150, 120, 360, 250], fill=34)
light = light.filter(ImageFilter.GaussianBlur(30))
rgb = ImageChops.add(rgb, ImageChops.multiply(Image.new("RGB", (W, H), palette.RGB["ember"][3]),
                                              Image.merge("RGB", [light] * 3)))
out = next((a for a in sys.argv[1:] if not a.startswith("-")), "battle_mock.png")
rgb.resize((W * 3, H * 3), Image.NEAREST).save(out)
print("battle mock written", out)
