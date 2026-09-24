"""Hollowmere — village theme. Warm pastoral waltz in D major, 96 bpm, 3/4.

Form (32 bars, loops): A1 flute · A2 flute + clarinet, glockenspiel embers ·
B1 oboe over horns · B2 oboe + flute answer, turnaround on A7.
"""
import smf
from theory import *

BPM, BEATS = 96, 3
BAR = smf.TPQ * BEATS
TAIL_SECONDS = 4  # rendered after the loop; render.sh folds it into the start

HARMONY = (
    "D G D A Bm G Em A "          # A1
    "D G D A Bm G A D "           # A2
    "G A F#m Bm G D/F# Em A "     # B1
    "G A Bm G Em A Em7 A7"        # B2
).split()

A1 = """F#5:2 E5:.5 D5:.5 | E5:1 D5:1 B4:1 | A4:2 D5:1 | E5:3 |
        F#5:2 G5:.5 F#5:.5 | E5:1 D5:1 E5:1 | G5:1.5 F#5:.5 E5:1 | E5:2 C#5:1"""
A2 = """F#5:2 E5:.5 D5:.5 | E5:1 D5:1 B4:1 | A4:2 D5:1 | E5:3 |
        B5:2 A5:.5 G5:.5 | F#5:1 E5:1 D5:1 | E5:1.5 D5:.5 C#5:1 | D5:3"""
B1 = """B4:1 D5:1 G5:1 | A5:2 G5:.5 F#5:.5 | F#5:1 A5:1 C#6:1 | B5:3 |
        G5:1 B5:1 D6:1 | A5:2 F#5:1 | G5:1.5 F#5:.5 E5:1 | E5:2 A4:1"""
B2 = """B4:1 D5:1 G5:1 | A5:2 B5:.5 A5:.5 | F#5:1 D5:1 B4:1 | D5:1 E5:1 F#5:1 |
        G5:2 F#5:.5 E5:.5 | E5:1 F#5:1 G5:1 | G5:2 E5:1 | E5:1 C#5:1 A4:1"""
# Flute answers the oboe in B2 (bars 25–32), mostly on the held notes.
B2_ANSWER = """r:3 | r:2 D6:.5 C#6:.5 | r:3 | r:1.5 A5:.5 B5:.5 C#6:.5 |
               r:3 | r:3 | r:2 B5:1 | C#6:3"""


def lay_melody(track, text, bar0, vel, human, octave=0, legato=0.95):
    t = bar0 * BAR
    for pitch, beats in melody(text):
        ln = int(beats * smf.TPQ)
        if pitch is not None:
            track.note(human.tick(t, 4), int(ln * legato), pitch + 12 * octave, human.vel(vel, 5))
        t += ln


def main():
    ch = iter(range(16))

    def track(name, program, volume, pan, reverb=70, chorus=10):
        c = next(ch)
        tr = smf.Track(name, c)
        tr.program(0, program)
        for cc, v in ((7, volume), (10, pan), (91, reverb), (93, chorus)):
            tr.cc(0, cc, v)
        return tr

    flute = track("flute", FLUTE, 100, 70)
    oboe = track("oboe", OBOE, 96, 58)
    clar = track("clarinet", CLARINET, 72, 50)
    harp = track("harp", HARP, 80, 40)
    strings = track("strings", STRINGS, 78, 64, reverb=85)
    bass = track("contrabass", CONTRABASS, 84, 60)
    pizz = track("pizzicato", PIZZ, 74, 84)
    horn = track("horn", HORN, 72, 76, reverb=90)
    glock = track("glockenspiel", GLOCK, 50, 90, reverb=95)
    tracks = [flute, oboe, clar, harp, strings, bass, pizz, horn, glock]

    h = Human(7)
    for base in (0,):
        # Melody
        lay_melody(flute, A1, base + 0, 86, h)
        lay_melody(flute, A2, base + 8, 96, h)
        lay_melody(clar, A2, base + 8, 70, h, octave=-1)
        lay_melody(oboe, B1, base + 16, 100, h)
        lay_melody(oboe, B2, base + 24, 104, h)
        lay_melody(flute, B2_ANSWER, base + 24, 78, h)

        for i, sym in enumerate(HARMONY):
            bar = base + i
            t0 = bar * BAR
            section = i // 8  # 0 A1, 1 A2, 2 B1, 3 B2
            eighth = smf.TPQ // 2

            # Harp: rolling eighth-note arpeggio, up then down.
            low = voice(sym, n("D3"), 5)
            pattern = [low[0], low[1], low[2], low[4], low[3], low[1]]
            for k, p in enumerate(pattern):
                harp.note(h.tick(t0 + k * eighth, 3), eighth * 2, p, h.vel(62 if k else 72))

            # Bass: root on the downbeat (A sections), pizz on 2 & 3 later.
            bass.note(t0, BAR - 40, bass_note(sym, n("D2")), h.vel((64, 74, 80, 84)[section]))
            if section >= 1:
                chord_hi = voice(sym, n("F#3"), 3)
                for beat in (1, 2):
                    for p in chord_hi[:2]:
                        pizz.note(h.tick(t0 + beat * smf.TPQ, 3), smf.TPQ // 2, p, h.vel(58))

            # String pad from A2 on, swelling in B.
            if section >= 1:
                for p in voice(sym, n("A3"), 4):
                    strings.note(t0, BAR - 20, p, h.vel(56 if section == 1 else 66, 3))
                strings.cc(t0, 11, 90 if section == 1 else 110)

            # Horns hold the 3rd and 5th in B.
            if section >= 2:
                for p in voice(sym, n("F3"), 3)[1:]:
                    horn.note(t0 + 10, BAR - 60, p, h.vel(60, 4))

            # Glockenspiel embers on A2 downbeats (festival sparkle).
            if section == 1 and i % 2 == 0:
                top = voice(sym, n("A5"), 2)
                glock.note(t0, smf.TPQ, top[0], h.vel(64))
                glock.note(t0 + smf.TPQ * 2, smf.TPQ, top[1], h.vel(54))

    end = len(HARMONY) * BAR + int(TAIL_SECONDS * BPM / 60 * smf.TPQ)
    smf.write("out/hollowmere.mid", tracks, BPM, BEATS, end_tick=end)
    print(f"loop length: {len(HARMONY) * BEATS * 60 / BPM:.3f}s")


if __name__ == "__main__":
    main()
