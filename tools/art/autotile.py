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
