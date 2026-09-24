"""Battle — regular encounter theme. Driving D minor, 150 bpm, 4/4.

A strings lead over staccato ostinato and kit · B horns legato, trumpets
answer · A2 trumpets lead, strings an octave up · C build back to A.
"""
from arrange import *
from theory import *

H = ("Dm Bb C A Dm Bb Gm A "
     "Bb C Am Dm Gm C F A "
     "Dm Bb C A Dm Bb Gm A "
     "Gm A Dm Dm/C Bb Gm E A")
p = Piece("battle", 150, 4, H, seed=31)

A = """D5:.5 D5:.5 F5:.5 A5:1 G5:.5 F5:1 | F5:.5 E5:.5 D5:1 F5:1 Bb5:1 |
       A5:1.5 G5:.5 E5:1 C5:1 | C#5:2 E5:1 A5:1 |
       D6:.5 D6:.5 C6:.5 A5:1 G5:.5 F5:1 | G5:.5 F5:.5 D5:1 F5:1 G5:1 |
       Bb5:1.5 A5:.5 G5:1 D5:1 | E5:2 C#5:2"""
B = """F5:2 D5:1 F5:1 | G5:3 E5:1 | A5:2 C6:1 E6:1 | D6:4 |
       D6:1 C6:1 Bb5:1 G5:1 | E5:1 G5:1 C6:2 | A5:1 G5:1 F5:1 C5:1 | E5:4"""
B_ANSWER = """r:4 | r:3 C5:.5 D5:.5 | r:4 | r:2 A4:.5 C5:.5 D5:.5 F5:.5 |
              r:4 | r:3 E5:.5 F5:.5 | r:4 | r:2 C#5:1 E5:1"""
C = """G5:1 Bb5:1 D6:2 | C#6:1 E6:1 A5:2 | F5:.5 E5:.5 F5:.5 A5:.5 D6:2 | C6:1 A5:1 F5:1 A5:1 |
       Bb5:2 F5:2 | G5:1 A5:1 Bb5:1 D6:1 | G#5:2 B5:2 | A5:1 C#6:1 E6:2"""

lead = p.track("violins", STRINGS, 104, 70, reverb=55)
trumpet = p.track("trumpets", TRUMPET, 92, 58, reverb=60)
horn = p.track("horns", HORN, 96, 48, reverb=65)
ostinato = p.track("staccato strings", STRINGS, 78, 80, reverb=45)
brass_stab = p.track("trombones", TROMBONE, 82, 40, reverb=55)
bass = p.track("bass", CONTRABASS, 100, 60, reverb=40)
timp = p.track("timpani", TIMPANI, 92, 64, reverb=60)
kit = p.track("drums", STANDARD_KIT, 88, 64, reverb=45, drums=True)

p.mel(lead, A, 0, 100, legato=0.85)
p.mel(horn, B, 8, 100, octave=-1)
p.mel(trumpet, B_ANSWER, 8, 88)
p.mel(trumpet, A, 16, 100, legato=0.8)
p.mel(lead, A, 16, 92, octave=1, legato=0.8)
p.mel(lead, C, 24, 102, legato=0.9)
p.mel(horn, C, 24, 88, octave=-1)

for i, sym in enumerate(p.harmony):
    sec = i // 8
    # Staccato eighth ostinato on chord tones.
    p.arp(ostinato, sym, i, n("D4"), [0, 1, 2, 1, 0, 1, 2, 3], 0.5, 70, hold=0.4)
    # Driving bass: root/octave eighths.
    p.bass(bass, sym, i, n("D2"), [(k * 0.5, 0.45) for k in range(8)], 86, octave_jump=True)
    # Brass stabs on the "and" of 2 and on 4 (A and A2).
    if sec in (0, 2):
        for beat in (1.5, 3):
            for pitch in voice(sym, n("A3"), 3):
                brass_stab.note(p.t(i, beat), int(0.35 * smf.TPQ), pitch, p.h.vel(78))
    if sec in (1, 3):
        p.pad(brass_stab, sym, i, n("A3"), 3, 60)
    # Drums: kick 1, 2.5, 3 · snare 2, 4 · hats eighths · crash on phrase heads.
    for b in (0, 1.5, 2):
        p.hit(kit, KICK, i, b, 96)
    for b in (1, 3):
        p.hit(kit, SNARE, i, b, 92)
    for k in range(8):
        p.hit(kit, HAT, i, k * 0.5, 62 if k % 2 else 74)
    if i % 8 == 0:
        p.hit(kit, CRASH, i, 0, 100, length=2)
    if i % 8 == 7:  # tom fill into the next section
        for k, tom in enumerate((TOM_HI, TOM_HI, TOM_MID, TOM_MID, TOM_LO, TOM_LO, SNARE, SNARE)):
            p.hit(kit, tom, i, 2 + k * 0.25, 80 + 3 * k)
    # Timpani on downbeats, doubling the root.
    p.hit(timp, bass_note(sym, n("F1") + 12), i, 0, 90, length=1)

p.write()
