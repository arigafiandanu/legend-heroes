"""Cinder Warden — boss theme. Menacing C minor with phrygian Db, 138 bpm.

A brass fanfare over tremolo strings · B choir + strings melody · C breakdown
(timpani, low brass ostinato, lone horn) · D A with choir, trumpets on top.
"""
from arrange import *
from theory import *

H = ("Cm Db/C Cm Db/C Ab Bb Fm G "
     "Ab Eb Fm Cm Db Ab Fm G7 "
     "Cm G/B Bbm Ab Db Bb G G "
     "Cm Db/C Cm Db/C Ab Bb Fm G")
p = Piece("boss", 138, 4, H, seed=47)

A = """C5:1 Eb5:1 G5:1.5 F5:.5 | Ab5:2 G5:1 F5:1 | G5:1 Eb5:1 C5:2 | Db5:3 C5:1 |
       C5:1 Eb5:1 Ab5:2 | Bb5:1.5 Ab5:.5 G5:1 F5:1 | Ab5:2 F5:1 C5:1 | B4:2 D5:1 G5:1"""
B = """C6:2 Bb5:1 Ab5:1 | G5:4 | Ab5:1 C6:1 F6:2 | Eb6:2 D6:1 C6:1 |
       F6:2 Eb6:1 Db6:1 | C6:4 | Ab5:1 C6:1 Ab5:1 F5:1 | G5:2 B5:2"""
C = """G4:4 | D4:2 F4:2 | Db5:3 C5:1 | C5:4 | Ab4:2 F4:2 | D5:2 F5:2 | B4:2 D5:2 | G5:4"""

trumpet = p.track("trumpets", TRUMPET, 96, 60, reverb=70)
horn = p.track("horns", HORN, 100, 48, reverb=75)
choir = p.track("choir", CHOIR, 92, 64, reverb=100)
lead = p.track("violins", STRINGS, 96, 74, reverb=70)
trem = p.track("tremolo strings", TREMOLO_STRINGS, 80, 80, reverb=80)
low_brass = p.track("trombones", TROMBONE, 94, 44, reverb=70)
bass = p.track("contrabass", CONTRABASS, 100, 60, reverb=60)
timp = p.track("timpani", TIMPANI, 100, 64, reverb=80)
kit = p.track("percussion", ORCHESTRA_KIT, 90, 64, reverb=80, drums=True)

p.mel(horn, A, 0, 104)
p.mel(trumpet, A, 0, 88, octave=1, legato=0.9)
p.mel(lead, B, 8, 100)
p.mel(choir, B, 8, 88, octave=-1)
p.mel(horn, C, 16, 96)
p.mel(trumpet, A, 24, 104, octave=1, legato=0.9)
p.mel(horn, A, 24, 100)
p.mel(choir, A, 24, 84)

for i, sym in enumerate(p.harmony):
    sec = i // 8
    # Tremolo chord bed everywhere except the breakdown.
    if sec != 2:
        p.pad(trem, sym, i, n("G3"), 4, 64)
    if sec == 1:
        p.pad(choir, sym, i, n("C4"), 3, 60)
    # Ostinato: C pedal eighths with a phrygian Db kick at the bar end.
    root = bass_note(sym, n("C2"))
    for k in range(8):
        pitch = root + (1 if k == 7 and sec != 1 else 0)
        bass.note(p.t(i, k * 0.5), int(0.4 * smf.TPQ), pitch, p.h.vel(90 if k % 4 == 0 else 76))
    # Low brass: stabs in A/D, sustained ostinato figure in C.
    if sec == 2:
        for beat, off in ((0, 0), (1.5, 0), (2, 7), (3, 6)):
            low_brass.note(p.t(i, beat), int(0.45 * smf.TPQ), root + 12 + off, p.h.vel(88))
    else:
        for beat in (0, 2.5):
            for pitch in voice(sym, n("C3"), 3):
                low_brass.note(p.t(i, beat), int(0.6 * smf.TPQ), pitch, p.h.vel(84))
    # Timpani: 1 and 3, rolls at the end of each section.
    for b in (0, 2):
        p.hit(timp, bass_note(sym, n("F2")), i, b, 96, length=1)
    if i % 8 == 7:
        for k in range(16):
            p.hit(timp, n("G2"), i, 2 + k * 0.125, 60 + 2 * k)
        p.hit(kit, CONCERT_CYMBAL, i + 1 if i + 1 < len(p.harmony) else 0, 0, 100, length=2)
    # Concert bass drum + snare pulse (stronger in D).
    p.hit(kit, KICK, i, 0, 100)
    p.hit(kit, KICK, i, 2, 92)
    if sec in (0, 3):
        for b in (1, 3):
            p.hit(kit, SNARE, i, b, 84 if sec == 0 else 96)
    if sec == 3 and i % 2 == 1:
        p.hit(kit, CONCERT_CYMBAL, i, 3.5, 80, length=1)

p.write()
