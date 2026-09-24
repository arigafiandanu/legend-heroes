"""Legend Heroes — main/title theme. Heroic and nostalgic, Bb major, 80 bpm.

A flute over harp and soft strings (a memory of Hollowmere) · B horns take
the melody, timpani swells · C full tutti: trumpets, strings, snare march.
"""
from arrange import *
from theory import *

H = ("Bb F/A Gm Eb Bb/D Eb Cm9 F "
     "Eb F Dm Gm Eb F Bb Gm "
     "Cm F Bb Gm Eb F Eb F7")
p = Piece("main_theme", 80, 4, H, seed=5)

A = """F5:2 Bb5:1 C6:1 | D6:3 C6:1 | Bb5:2 A5:1 G5:1 | G5:3 F5:1 |
       F5:2 Bb5:1 C6:1 | Eb6:2 D6:1 C6:1 | D6:1.5 C6:.5 Bb5:1 G5:1 | C6:4"""
B = """Bb4:2 Eb5:1 F5:1 | G5:1.5 F5:.5 C5:2 | F5:2 D5:1 A4:1 | Bb4:4 |
       Bb4:1 Eb5:1 G5:1 Bb5:1 | A5:2 F5:1 C5:1 | D5:2 F5:1 Bb5:1 | Bb5:4"""
C = """C6:2 Eb6:1 D6:1 | C6:2 A5:2 | D6:1.5 C6:.5 Bb5:1 F5:1 | G5:2 Bb5:1 D6:1 |
       Eb6:2 D6:1 C6:1 | C6:2 F6:2 | Bb5:1 G5:1 Eb5:1 G5:1 | A5:2 C6:2"""

flute = p.track("flute", FLUTE, 98, 70, reverb=90)
horn = p.track("horns", HORN, 104, 50, reverb=85)
trumpet = p.track("trumpets", TRUMPET, 92, 60, reverb=80)
violins = p.track("violins", STRINGS, 90, 76, reverb=85)
strings = p.track("strings pad", SLOW_STRINGS, 80, 64, reverb=95)
harp = p.track("harp", HARP, 84, 40, reverb=85)
bass = p.track("contrabass", CONTRABASS, 86, 60, reverb=75)
timp = p.track("timpani", TIMPANI, 90, 64, reverb=85)
kit = p.track("percussion", ORCHESTRA_KIT, 80, 64, reverb=90, drums=True)
glock = p.track("glockenspiel", GLOCK, 56, 92, reverb=100)

p.mel(flute, A, 0, 90)
p.mel(horn, B, 8, 104)
p.mel(violins, B, 8, 70, octave=1, legato=1.0)
p.mel(trumpet, C, 16, 100)
p.mel(violins, C, 16, 94, legato=1.0)
p.mel(horn, C, 16, 86, octave=-1)

for i, sym in enumerate(p.harmony):
    sec = i // 8
    # Harp: flowing eighths (A, B), broader quarters in C.
    if sec < 2:
        p.arp(harp, sym, i, n("Bb2"), [0, 1, 2, 3, 4, 3, 2, 1], 0.5, 60, hold=1.8)
    else:
        p.arp(harp, sym, i, n("Bb3"), [0, 2, 3, 4], 1, 66, hold=1.5)
    p.pad(strings, sym, i, n("F3"), 4, (48, 60, 70)[sec])
    p.bass(bass, sym, i, n("Bb1"), [(0, 2), (2, 2)] if sec < 2 else [(0, 1.5), (1.5, 0.5), (2, 2)], (64, 76, 88)[sec])
    if sec == 1 and i % 4 == 3:  # timpani swell into each phrase
        for k in range(8):
            p.hit(timp, bass_note(sym, n("F2")), i, 2 + k * 0.25, 50 + 6 * k)
    if sec == 2:
        p.hit(timp, bass_note(sym, n("F2")), i, 0, 96, length=1)
        # Light march: snare on the "and" of 3 plus 4.
        for b, v in ((0, 70), (2.5, 62), (3, 76), (3.5, 60)):
            p.hit(kit, SNARE, i, b, v)
        if i % 4 == 0:
            p.hit(kit, CONCERT_CYMBAL, i, 0, 96, length=2)
    if sec == 0 and i % 2 == 1:
        top = voice(sym, n("F6"), 2)
        glock.note(p.t(i, 3), smf.TPQ, top[0], p.h.vel(56))
    if i == 15:  # cymbal roll into the tutti
        for k in range(8):
            p.hit(kit, CONCERT_CYMBAL, i, 2 + k * 0.25, 40 + 7 * k)

p.write()
