"""Old Emberline Mine — dungeon theme. Dark and heavy, D phrygian, 76 bpm.

A mournful horn over a cello ostinato, pickaxe clinks echoing · B cold flute
over bassoon, timpani · C near-silence: celesta crystals and a low drone.
"""
from arrange import *
from theory import *

H = ("Dm Eb/D Dm Eb/D Bb C Dm A "
     "Gm Dm Bb F/A Gm Eb Asus4 A "
     "Dm Eb Bb A")
p = Piece("emberline_mine", 76, 4, H, seed=23)

A = """A4:4 | Bb4:2 G4:2 | F4:2 E4:1 D4:1 | Eb4:4 |
       D4:1 F4:1 Bb4:2 | C5:2 Bb4:1 A4:1 | A4:3 F4:1 | E4:4"""
B = """D5:2 Bb4:2 | A4:4 | D5:1 F5:1 Bb5:2 | A5:2 C5:2 |
       Bb4:1 D5:1 G5:2 | G5:2 Eb5:2 | D5:4 | C#5:4"""
B_BASSOON = """G3:4 | F3:4 | D3:2 F3:2 | C3:4 | Bb2:4 | G3:4 | E3:4 | E3:4"""

horn = p.track("horn", HORN, 96, 58, reverb=95)
flute = p.track("flute", FLUTE, 84, 76, reverb=100)
bassoon = p.track("bassoon", BASSOON, 88, 50)
cello = p.track("cello ostinato", CELLO, 92, 44, reverb=80)
bass = p.track("contrabass", CONTRABASS, 90, 60, reverb=80)
strings = p.track("tremolo strings", TREMOLO_STRINGS, 64, 70, reverb=95)
timp = p.track("timpani", TIMPANI, 90, 64, reverb=90)
celesta = p.track("celesta", CELESTA, 70, 90, reverb=110)
kit = p.track("clinks", STANDARD_KIT, 70, 84, reverb=110, drums=True)

p.mel(horn, A, 0, 90)
p.mel(flute, B, 8, 86)
p.mel(bassoon, B_BASSOON, 8, 80)

for i, sym in enumerate(p.harmony):
    sec = 0 if i < 8 else 1 if i < 16 else 2
    if sec < 2:
        # Cello ostinato: root, root, 5th, root, b2-ish neighbour, root, 5th, octave
        root = bass_note(sym, n("D2"))
        fifth = voice(sym, root + 5, 1)[0]
        for k, pitch in enumerate([root, root, fifth, root, root + 1 if sym.startswith("Dm") else root, root, fifth, root + 12]):
            cello.note(p.t(i, k * 0.5), int(0.42 * smf.TPQ), pitch, p.h.vel(70 if k % 2 else 80))
        p.bass(bass, sym, i, n("D1") + 12, [(0, 4)], 74)
    else:
        bass.note(p.t(i), p.bar - 30, n("D2"), p.h.vel(58, 2))
    if sec == 1:
        p.pad(strings, sym, i, n("D4"), 3, 52)
    # Timpani at the head of each 4-bar phrase, roll into B.
    if i % 4 == 0 and sec < 2:
        p.hit(timp, n("D2"), i, 0, 92, length=2)
    if i == 7:
        for k in range(8):
            p.hit(timp, n("A1"), i, 2 + k * 0.25, 60 + 5 * k)
    # Pickaxe clinks far away (irregular, sparse).
    for beat in ((1.5, 3.25), (2.75,), (1.25, 3.5), (3.0,))[i % 4]:
        if sec < 2:
            p.hit(kit, RIDE_BELL, i, beat, 42 + (i * 7) % 18)
    # Crystal glow.
    if sec == 2 or (sec == 0 and i % 4 == 3):
        for beat, idx in ((0, 0), (1.5, 2), (2.5, 1), (3.5, 3)):
            celesta.note(p.t(i, beat), smf.TPQ * 2, voice(sym, n("D6"), 4)[idx], p.h.vel(54))

p.write()
