"""Interactive map objects shared by every area (LH-48).

Output:
  assets/images/props/chest.png   16×16 frames: closed, open
"""
import palette
from pixel import Canvas, shade

P = palette.RGB
BARK, EMBER = P["bark"], P["ember"]
T = 16


def chest(opened):
    """Wooden chest with gold trim, lit from the top-left; feet on row 15."""
    c = Canvas(T, T)
    for y in range(8, 15):  # box
        for x in range(1, 15):
            t = 0.85 - (x - 1) / 14 * 0.5 - (y - 8) / 7 * 0.25
            c.set(x, y, shade(BARK, t, x, y, dither=False))
    for x in range(1, 15):
        c.set(x, 11, BARK[0])  # plank seam
    for x in (3, 12):  # gold bands
        for y in range(8, 15):
            c.set(x, y, EMBER[2] if x == 3 else EMBER[0])
    if opened:
        for y in range(2, 7):  # lid tipped back, showing its dark underside
            for x in range(2, 14):
                c.set(x, y, BARK[1] if y < 4 else BARK[0])
        for x in range(2, 14):
            c.set(x, 2, BARK[3])
        for x in range(2, 14):  # inside
            c.set(x, 7, P["night"][0])
            c.set(x, 8, P["night"][1])
        c.set(7, 7, EMBER[3])  # glint of what was inside
    else:
        for y in range(4, 8):  # rounded lid
            for x in range(1 + (y == 4), 15 - (y == 4)):
                t = 0.95 - (x - 1) / 14 * 0.45 - (y - 4) / 4 * 0.2
                c.set(x, y, shade(BARK, t, x, y, dither=False))
        for x in (3, 12):
            for y in range(4, 8):
                c.set(x, y, EMBER[3] if x == 3 else EMBER[1])
        for x in range(1, 15):
            c.set(x, 7, BARK[0])  # lid edge
        for dx, dy, col in ((0, 0, EMBER[3]), (1, 0, EMBER[2]), (0, 1, EMBER[1]), (1, 1, EMBER[0])):
            c.set(7 + dx, 8 + dy, col)  # lock plate
        c.set(7, 10, P["night"][0])  # keyhole
        c.set(8, 10, EMBER[0])
    c.outline()
    return c


def build(path):
    sheet = Canvas(T * 2, T)
    sheet.paste(chest(False), 0, 0)
    sheet.paste(chest(True), T, 0)
    sheet.image().save(path)


if __name__ == "__main__":
    build("../../assets/images/props/chest.png")
    print("chest written")
