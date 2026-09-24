"""Note names, chords and small arranging helpers."""
import random

_STEPS = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}

# GM programs (0-based)
FLUTE, OBOE, CLARINET, HORN, TRUMPET, TROMBONE = 73, 68, 71, 60, 56, 57
HARP, STRINGS, SLOW_STRINGS, PIZZ, CONTRABASS, CELLO = 46, 48, 49, 45, 43, 42
GLOCK, CELESTA, TIMPANI, CHOIR, PAN_FLUTE, VIOLIN = 9, 8, 47, 52, 75, 40
ACOUSTIC_GUITAR, TREMOLO_STRINGS, BASSOON, PIANO = 24, 44, 70, 0


def n(name):
    """'F#5' -> 78, 'Bb3' -> 58, 'r' -> None."""
    if name in ("r", "-"):
        return None
    letter, rest = name[0].upper(), name[1:]
    acc = 0
    while rest and rest[0] in "#b":
        acc += 1 if rest[0] == "#" else -1
        rest = rest[1:]
    return 12 * (int(rest) + 1) + _STEPS[letter] + acc


_QUAL = {
    "": [0, 4, 7], "m": [0, 3, 7], "7": [0, 4, 7, 10], "m7": [0, 3, 7, 10],
    "maj7": [0, 4, 7, 11], "sus4": [0, 5, 7], "sus2": [0, 2, 7], "dim": [0, 3, 6],
    "add9": [0, 4, 7, 14], "m9": [0, 3, 7, 10, 14], "aug": [0, 4, 8],
}


def chord(symbol):
    """'D/F#' -> (root pc, [intervals], bass pc)."""
    body, _, bass = symbol.partition("/")
    root_len = 2 if len(body) > 1 and body[1] in "#b" else 1
    root = n(body[:root_len] + "0") % 12
    ivs = _QUAL[body[root_len:]]
    bass_pc = n(bass + "0") % 12 if bass else root
    return root, ivs, bass_pc


def voice(symbol, low, count):
    """`count` chord tones ascending from the first chord tone >= low."""
    root, ivs, _ = chord(symbol)
    pcs = sorted({(root + i) % 12 for i in ivs})
    out, p = [], low
    while len(out) < count:
        if p % 12 in pcs:
            out.append(p)
        p += 1
    return out


def bass_note(symbol, low):
    _, _, b = chord(symbol)
    p = low
    while p % 12 != b:
        p += 1
    return p


def melody(text):
    """'F#5:2 E5:.5 r:1' -> [(pitch|None, beats)]; '|' is ignored."""
    out = []
    for tok in text.split():
        if tok == "|":
            continue
        name, _, dur = tok.partition(":")
        out.append((n(name), float(dur)))
    return out


class Human:
    """Small deterministic velocity/timing variation."""

    def __init__(self, seed):
        self.r = random.Random(seed)

    def vel(self, v, spread=6):
        return v + self.r.randint(-spread, spread)

    def tick(self, t, spread=6):
        return max(0, t + self.r.randint(-spread, spread))
