"""Chooses the 13-piece path tile for each path cell from its neighbours."""


def path_piece(is_path, x, y):
    """`is_path(x, y)` → bool. Returns a tile name from whisperwood.PATH_PIECES."""
    n, s, w, e = (not is_path(x, y - 1), not is_path(x, y + 1), not is_path(x - 1, y), not is_path(x + 1, y))
    sides = "".join(k for k, v in (("n", n), ("s", s), ("w", w), ("e", e)) if v)
    if sides in ("", ):
        for corner, (dx, dy) in (("nw", (-1, -1)), ("ne", (1, -1)), ("sw", (-1, 1)), ("se", (1, 1))):
            if not is_path(x + dx, y + dy):
                return f"path_in_{corner}"
        return "path"
    order = {"n": 0, "s": 1, "w": 2, "e": 3}
    key = "".join(sorted(sides, key=order.get))
    return {"n": "path_n", "s": "path_s", "w": "path_w", "e": "path_e",
            "nw": "path_nw", "ne": "path_ne", "sw": "path_sw", "se": "path_se"}.get(key, "path")


def supported(is_path, x, y):
    """True if the 13-piece set has a piece for this path cell."""
    n, s, w, e = not is_path(x, y - 1), not is_path(x, y + 1), not is_path(x - 1, y), not is_path(x + 1, y)
    if (n and s) or (w and e):
        return False
    gaps = {(dx, dy) for dx in (-1, 1) for dy in (-1, 1) if not is_path(x + dx, y + dy)}
    # a diagonal gap is fine only on a corner the side piece already covers
    covered = {(dx, dy) for dx, dy in gaps if (n and dy == -1) or (s and dy == 1) or (w and dx == -1) or (e and dx == 1)}
    return len(gaps - covered) <= (0 if (n or s or w or e) else 1)


def stroke(points, radius, w, h):
    """Grid cells whose centre lies within `radius` cells of the polyline."""
    import math
    out = set()
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        dx, dy = x1 - x0, y1 - y0
        for y in range(h):
            for x in range(w):
                px, py = x + 0.5, y + 0.5
                t = max(0, min(1, ((px - x0) * dx + (py - y0) * dy) / (dx * dx + dy * dy)))
                if math.hypot(px - x0 - t * dx, py - y0 - t * dy) <= radius:
                    out.add((x, y))
    return out


def clamped(cells, w, h):
    """is_path over `cells` where the path continues past the map edge."""
    return lambda x, y: (min(max(x, 0), w - 1), min(max(y, 0), h - 1)) in cells


def clean(cells, w, h):
    """Drop cells the autotile can't draw until the shape is stable."""
    cells = set(cells)
    while True:
        p = clamped(cells, w, h)
        bad = {c for c in cells if not supported(p, *c)}
        if not bad:
            return cells
        cells -= bad


if __name__ == "__main__":
    # 2-wide horizontal path with a turn
    cells = {(x, y) for x in range(0, 6) for y in (2, 3)} | {(x, y) for x in (4, 5) for y in range(0, 4)}
    p = lambda x, y: (x, y) in cells
    assert path_piece(p, 1, 2) == "path_n"
    assert path_piece(p, 1, 3) == "path_s"
    assert path_piece(p, 4, 0) == "path_nw"
    assert path_piece(p, 4, 1) == "path_w"
    assert path_piece(p, 4, 2) == "path_in_nw"
    assert path_piece(p, 5, 3) == "path_se"
    print("autotile ok")
