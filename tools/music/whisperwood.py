"""Whisperwood — forest theme. Gentle but wary, E dorian, 88 bpm, 4/4.

A pan flute over a pizzicato walk · B flute + clarinet thirds, strings enter
(the Ashblight shadow: low drone) · A' flute an octave up, celesta light.
"""
from arrange import *
from theory import *

H = ("Em D A/C# C Em D Cmaj7 B7 "
     "Am Em D G C Em/B Am B "
     "Em D A/C# C Em D Cmaj7 B7")
p = Piece("whisperwood", 88, 4, H, seed=11)

A = """B4:1.5 E5:.5 G5:1 F#5:1 | E5:1 D5:1 A4:2 | C#5:1.5 D5:.5 E5:1 F#5:1 | G5:3 r:1 |
       B5:1.5 A5:.5 G5:1 F#5:1 | F#5:1 E5:1 D5:1 A4:1 | B4:1 C5:1 E5:1 G5:1 | F#5:3 D#5:1"""
B = """E5:1 A5:1 C6:1.5 B5:.5 | B5:2 G5:2 | A5:1 F#5:1 D5:1 E5:1 | D5:3 r:1 |
       E5:1 G5:1 C6:1.5 B5:.5 | B5:2 E5:2 | C5:1 E5:1 A5:1 G5:1 | F#5:3 r:1"""
B_LOW = """C5:1 E5:1 A5:1.5 G5:.5 | G5:2 E5:2 | F#5:1 D5:1 A4:1 C#5:1 | B4:3 r:1 |
           C5:1 E5:1 G5:1.5 G5:.5 | G5:2 B4:2 | A4:1 C5:1 E5:1 E5:1 | D#5:3 r:1"""

panflute = p.track("pan flute", PAN_FLUTE, 100, 60, reverb=80)
flute = p.track("flute", FLUTE, 96, 70, reverb=80)
clar = p.track("clarinet", CLARINET, 80, 50)
pizz = p.track("pizzicato", PIZZ, 86, 76)
harp = p.track("harp", HARP, 78, 40)
strings = p.track("strings", SLOW_STRINGS, 74, 64, reverb=90)
drone = p.track("low strings", CELLO, 70, 56, reverb=90)
bass = p.track("contrabass", CONTRABASS, 80, 60)
celesta = p.track("celesta", CELESTA, 62, 96, reverb=100)

p.mel(panflute, A, 0, 92)
p.mel(flute, B, 8, 94)
p.mel(clar, B_LOW, 8, 78, octave=-1)
p.mel(flute, A, 16, 90, octave=1, legato=0.9)

for i, sym in enumerate(p.harmony):
    sec = i // 8  # 0 A, 1 B, 2 A'
    # Pizzicato walk: root-5th-octave-5th eighths, lighter on off-beats.
    p.arp(pizz, sym, i, n("E3"), [0, 1, 2, 1, 0, 1, 2, 3], 0.5, 62, hold=0.8)
    # Harp roll on beats 1 and 3 (sixteenths up).
    for beat in (0, 2):
        tones = voice(sym, n("E4"), 4)
        for k, t in enumerate(tones):
            harp.note(p.t(i, beat + k * 0.25), smf.TPQ, t, p.h.vel(56 + 4 * k))
    p.bass(bass, sym, i, n("E2"), [(0, 2), (2, 2)], 70 + 6 * sec)
    if sec >= 1:
        p.pad(strings, sym, i, n("G3"), 4, 58 if sec == 1 else 54)
    if sec == 1:  # the blight's shadow: a low E drone under B
        drone.note(p.t(i), p.bar - 30, n("E2"), p.h.vel(56, 3))
    if sec == 2 and i % 2 == 0:  # light through the leaves
        for beat, idx in ((1.5, 2), (3.5, 3)):
            celesta.note(p.t(i, beat), smf.TPQ, voice(sym, n("E6"), 4)[idx], p.h.vel(58))

p.write()
