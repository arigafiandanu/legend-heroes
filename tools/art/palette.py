"""LH-48: the locked Legend Heroes palette.

Built around the colours already used by the Kael/Lira sheets so new art
matches them. Every ramp runs dark → light; shadows lean purple/teal and
highlights lean warm (hue shifting), and there is no pure black.
"""


def _hex(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


RAMPS = {
    "outline": ["#140B12"],
    "night": ["#1E1828", "#2A2531"],
    "stone": ["#3E3A4A", "#5E5A6E", "#707688", "#B0B6C4", "#E4E8F0"],
    "bark": ["#3C261C", "#5C3A28", "#703E2A", "#A0623C"],
    "dirt": ["#5A3824", "#805434", "#A87848", "#C8A070"],
    "skin": ["#D4987A", "#F2C8A2"],
    "leaf": ["#16261F", "#1E3A2C", "#306242", "#4A885C", "#70AC76", "#A6D08A"],
    "moss": ["#4E6A2A", "#7A9A3A", "#B4C860"],
    "teal": ["#1C3238", "#2E5458"],
    "blue": ["#22386C", "#345496", "#547ABE", "#8FB8E6"],
    "red": ["#781824", "#B22630", "#DA4A48"],
    "ember": ["#CC7440", "#EEA664", "#E2B848", "#FAD65A"],
    "cream": ["#C8BCA4", "#F0E8D4"],
    "white": ["#FFFFFF"],
    "pink": ["#BE506E", "#EC7896"],
    "ash": ["#3A2A44", "#5E4A6E", "#8E7AA0"],
}

RGB = {name: [_hex(h) for h in ramp] for name, ramp in RAMPS.items()}
ALL = [c for ramp in RGB.values() for c in ramp]
OUTLINE = RGB["outline"][0]

assert len(ALL) == 48, len(ALL)
assert len(set(ALL)) == 48, "duplicate colour"


def nearest(rgb):
    """Snap any colour to the palette (used to verify exported art)."""
    return min(ALL, key=lambda c: sum((a - b) ** 2 for a, b in zip(c, rgb)))


def swatch(path, cell=24):
    from PIL import Image, ImageDraw

    rows = list(RGB.items())
    img = Image.new("RGB", (110 + cell * 6, cell * len(rows)), (24, 20, 30))
    d = ImageDraw.Draw(img)
    for r, (name, ramp) in enumerate(rows):
        d.text((6, r * cell + 6), name, fill=(230, 225, 214))
        for i, c in enumerate(ramp):
            d.rectangle([110 + i * cell, r * cell, 110 + (i + 1) * cell - 2, (r + 1) * cell - 2], fill=c)
    img.save(path)


if __name__ == "__main__":
    swatch("../../docs/art/palette_lh48.png")
    print("48 colours, swatch written")
