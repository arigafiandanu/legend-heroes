"""Tiny pixel-art toolkit: palette-locked canvas, shaded blobs lit from the
top-left, 1px outline pass, 2×2 Bayer dithering and tileable value noise."""
import math
import random

from PIL import Image

import palette

BAYER2 = [[0.0, 0.5], [0.75, 0.25]]


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.px = [[None] * w for _ in range(h)]

    def inside(self, x, y):
        return 0 <= x < self.w and 0 <= y < self.h

    def set(self, x, y, c):
        if self.inside(x, y):
            assert c is None or c in palette.ALL, f"off-palette colour {c}"
            self.px[y][x] = c

    def get(self, x, y):
        return self.px[y][x] if self.inside(x, y) else None

    def fill(self, c):
        for y in range(self.h):
            for x in range(self.w):
                self.px[y][x] = c

    def stamp(self, rows, keys, ox, oy, flip=False):
        """Draw an ASCII sprite: each char maps to a colour via `keys` ('.' = skip)."""
        for y, row in enumerate(rows):
            for x, ch in enumerate(row[::-1] if flip else row):
                if ch != "." and ch in keys:
                    self.set(ox + x, oy + y, keys[ch])

    def blob(self, cx, cy, rx, ry, ramp, bias=0.0, rng=None, jitter=0.0, dither=True):
        """Filled ellipse shaded by facing the top-left light.

        `bias` shifts the whole blob lighter (+) or darker (−)."""
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
                d = dx * dx + dy * dy
                if d > 1.0 or not self.inside(x, y):
                    continue
                # light from top-left: -dx-dy high → lit; rim darker
                light = (-dx * 0.55 - dy * 0.75) * 0.5 + 0.5 - d * 0.18 + bias
                if rng is not None and jitter:
                    light += (rng.random() - 0.5) * jitter
                self.set(x, y, shade(ramp, light, x, y, dither))

    def outline(self, color=palette.OUTLINE, skip=None):
        """1px outline on transparent pixels that touch a filled pixel (4-neighbour)."""
        marks = []
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x] is not None:
                    continue
                if any(self.get(x + dx, y + dy) is not None and self.get(x + dx, y + dy) != color
                       for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    if skip is None or not skip(x, y):
                        marks.append((x, y))
        for x, y in marks:
            self.px[y][x] = color

    def paste(self, other, ox, oy):
        for y in range(other.h):
            for x in range(other.w):
                c = other.px[y][x]
                if c is not None:
                    self.set(ox + x, oy + y, c)

    def crop(self, x0, y0, w, h):
        c = Canvas(w, h)
        for y in range(h):
            for x in range(w):
                c.px[y][x] = self.get(x0 + x, y0 + y)
        return c

    def image(self):
        img = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        for y in range(self.h):
            for x in range(self.w):
                c = self.px[y][x]
                if c is not None:
                    img.putpixel((x, y), (*c, 255))
        return img


def shade(ramp, t, x=0, y=0, dither=True):
    """Pick a ramp colour for brightness t∈[0,1] with 2×2 ordered dither."""
    t = max(0.0, min(0.999, t))
    pos = t * len(ramp)
    i = int(pos)
    frac = pos - i
    if dither and i + 1 < len(ramp) and frac > 0.62 + 0.3 * BAYER2[y % 2][x % 2] - 0.15:
        return ramp[i + 1]
    return ramp[i]


class TileNoise:
    """Value noise that wraps every `period` pixels (seamless tiles)."""

    def __init__(self, seed, period=16, cell=4):
        r = random.Random(seed)
        self.n = period // cell
        self.cell = cell
        self.grid = [[r.random() for _ in range(self.n)] for _ in range(self.n)]

    def __call__(self, x, y):
        fx, fy = x / self.cell, y / self.cell
        x0, y0 = int(math.floor(fx)), int(math.floor(fy))
        tx, ty = fx - x0, fy - y0
        tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
        g = lambda i, j: self.grid[j % self.n][i % self.n]
        a = g(x0, y0) + (g(x0 + 1, y0) - g(x0, y0)) * tx
        b = g(x0, y0 + 1) + (g(x0 + 1, y0 + 1) - g(x0, y0 + 1)) * tx
        return a + (b - a) * ty
