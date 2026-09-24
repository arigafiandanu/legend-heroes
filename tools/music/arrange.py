"""Shared arranging helpers for BGM pieces (Hollowmere predates this)."""
import smf
from theory import Human, bass_note, chord, melody, voice

TAIL_SECONDS = 4

# General MIDI percussion (channel 10)
KICK, SNARE, RIM, CLAP, HAT, OPEN_HAT, CRASH, RIDE, RIDE_BELL = 36, 38, 37, 39, 42, 46, 49, 51, 53
TOM_LO, TOM_MID, TOM_HI, SPLASH, CHINA, COWBELL, TRIANGLE = 45, 47, 50, 55, 52, 56, 81
STANDARD_KIT, ORCHESTRA_KIT = 0, 48
# GS orchestra kit: 35/36 concert bass drum, 38/40 concert snare, 41–53 are
# chromatic timpani (NOT cymbals/toms), 57/59 concert cymbals.
CONCERT_CYMBAL, CONCERT_CYMBAL_2 = 57, 59


class Piece:
    def __init__(self, name, bpm, beats, harmony, seed=1):
        self.name, self.bpm, self.beats = name, bpm, beats
        self.harmony = harmony.split() if isinstance(harmony, str) else harmony
        self.bar = smf.TPQ * beats
        self.h = Human(seed)
        self.tracks = []
        self._channels = iter([c for c in range(16) if c != 9])

    @property
    def loop_seconds(self):
        return len(self.harmony) * self.beats * 60 / self.bpm

    def t(self, bar, beat=0.0):
        return int(bar * self.bar + beat * smf.TPQ)

    def track(self, name, program, volume=100, pan=64, reverb=70, drums=False):
        tr = smf.Track(name, 9 if drums else next(self._channels))
        tr.program(0, program)
        for cc, v in ((7, volume), (10, pan), (91, reverb), (93, 0)):
            tr.cc(0, cc, v)
        self.tracks.append(tr)
        return tr

    def mel(self, tr, text, bar, vel, octave=0, legato=0.95, jitter=4):
        """Lay a melody string; bars separated by '|' must fill the meter."""
        for k, seg in enumerate(text.split("|")):
            total = sum(d for _, d in melody(seg))
            if seg.strip() and abs(total - self.beats) > 1e-6:
                raise ValueError(f"{self.name}: bar {bar + k} has {total} beats: {seg.strip()}")
        t = self.t(bar)
        for pitch, beats in melody(text.replace("|", " ")):
            ln = int(beats * smf.TPQ)
            if pitch is not None and beats >= 1.5:
                self._check_clash(tr.name, pitch + 12 * octave, t)
            if pitch is not None:
                tr.note(self.h.tick(t, jitter), int(ln * legato), pitch + 12 * octave, self.h.vel(vel, 5))
            t += ln

    def _check_clash(self, part, pitch, tick):
        """Warn on long melody notes a semitone off the bar's chord tones."""
        bar = tick // self.bar
        if bar >= len(self.harmony):
            return
        sym = self.harmony[bar]
        root, ivs, bass = chord(sym)
        tones = {(root + i) % 12 for i in ivs} | {bass}
        pc = pitch % 12
        if pc not in tones and any((pc - t) % 12 in (1, 11) for t in tones):
            print(f"  warn {self.name} bar {bar + 1} {part}: pitch class {pc} rubs against {sym}")

    def pad(self, tr, sym, bar, low, count, vel, beats=None, start=0.0):
        ln = int((beats or self.beats - start) * smf.TPQ) - 20
        for p in voice(sym, low, count):
            tr.note(self.t(bar, start), ln, p, self.h.vel(vel, 3))

    def arp(self, tr, sym, bar, low, pattern, step, vel, hold=1.0, accent=8):
        """Chord-tone arpeggio; `pattern` indexes voice(sym, low, …)."""
        tones = voice(sym, low, max(pattern) + 1)
        for k, idx in enumerate(pattern):
            beat = k * step
            if beat >= self.beats:
                break
            v = vel + (accent if k == 0 else 0)
            tr.note(self.h.tick(self.t(bar, beat), 3), int(step * hold * smf.TPQ), tones[idx], self.h.vel(v, 4))

    def bass(self, tr, sym, bar, low, rhythm, vel, octave_jump=False):
        """rhythm: [(beat, length)]; octave_jump alternates root and octave."""
        root = bass_note(sym, low)
        for k, (beat, length) in enumerate(rhythm):
            p = root + (12 if octave_jump and k % 2 else 0)
            tr.note(self.t(bar, beat), int(length * smf.TPQ) - 10, p, self.h.vel(vel, 4))

    def hit(self, tr, pitch, bar, beat, vel, length=0.25):
        tr.note(self.h.tick(self.t(bar, beat), 2), int(length * smf.TPQ), pitch, self.h.vel(vel, 5))

    def write(self):
        end = len(self.harmony) * self.bar + int(TAIL_SECONDS * self.bpm / 60 * smf.TPQ)
        smf.write(f"out/{self.name}.mid", self.tracks, self.bpm, self.beats, end_tick=end)
        with open(f"out/{self.name}.len", "w") as f:
            f.write(f"{self.loop_seconds:.6f}\n")
        print(f"{self.name}: {len(self.harmony)} bars, loop {self.loop_seconds:.3f}s")
