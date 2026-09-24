"""Minimal Standard MIDI File (type 1) writer, no dependencies."""
import struct

TPQ = 480  # ticks per quarter note


def _vlq(n):
    out = [n & 0x7F]
    n >>= 7
    while n:
        out.append((n & 0x7F) | 0x80)
        n >>= 7
    return bytes(reversed(out))


class Track:
    def __init__(self, name, channel=0):
        self.name = name
        self.channel = channel
        self.events = []  # (tick, order, bytes)

    def meta(self, tick, kind, data):
        self.events.append((tick, 0, bytes([0xFF, kind]) + _vlq(len(data)) + data))

    def program(self, tick, program):
        self.events.append((tick, 1, bytes([0xC0 | self.channel, program])))

    def cc(self, tick, controller, value):
        self.events.append((tick, 1, bytes([0xB0 | self.channel, controller, value])))

    def note(self, tick, length, pitch, velocity):
        vel = max(1, min(127, int(velocity)))
        self.events.append((tick, 3, bytes([0x90 | self.channel, pitch, vel])))
        # note-offs sort before note-ons at the same tick (order 2 < 3)
        self.events.append((tick + max(1, length), 2, bytes([0x80 | self.channel, pitch, 0])))

    def encode(self):
        body = bytearray()
        body += _vlq(0) + bytes([0xFF, 0x03]) + _vlq(len(self.name)) + self.name.encode()
        last = 0
        for tick, _, data in sorted(self.events, key=lambda e: (e[0], e[1])):
            body += _vlq(tick - last) + data
            last = tick
        body += _vlq(0) + bytes([0xFF, 0x2F, 0x00])
        return b"MTrk" + struct.pack(">I", len(body)) + bytes(body)


def write(path, tracks, bpm, beats_per_bar=4, end_tick=None):
    """`end_tick` extends the file (silence) so renderers keep reverb tails."""
    conductor = Track("conductor")
    if end_tick is not None:
        conductor.meta(end_tick, 0x01, b"end")
    conductor.meta(0, 0x51, struct.pack(">I", round(60_000_000 / bpm))[1:])
    conductor.meta(0, 0x58, bytes([beats_per_bar, 2, 24, 8]))
    data = b"MThd" + struct.pack(">IHHH", 6, 1, len(tracks) + 1, TPQ)
    data += conductor.encode() + b"".join(t.encode() for t in tracks)
    with open(path, "wb") as f:
        f.write(data)
