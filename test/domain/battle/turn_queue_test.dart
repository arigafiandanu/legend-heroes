import 'package:ashen_crest/domain/battle/turn_queue.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_random.dart';
import '../../helpers/units.dart';

void main() {
  test('orders by SPD, fastest first', () {
    final slow = hero('slow', s: stats(spd: 10));
    final fast = foe('fast', s: stats(spd: 30));
    final mid = hero('mid', s: stats(spd: 20));
    final q = TurnQueue(FixedRandom())..startRound([slow, fast, mid], 1);

    expect(q.remaining.map((u) => u.id), ['fast', 'mid', 'slow']);
  });

  test('SPD is scaled by a 0.9–1.1 roll', () {
    // a: 24 · 1.1 = 26.4, b: 25 · 0.9 = 22.5 → a first.
    final a = hero('a', s: stats(spd: 24));
    final b = hero('b', s: stats(spd: 25));
    final q = TurnQueue(FixedRandom(doubles: [1.0, 0.0]))..startRound([a, b], 1);

    expect(q.remaining.map((u) => u.id), ['a', 'b']);
  });

  test('next() pops units in order and returns null when round is over', () {
    final a = hero('a', s: stats(spd: 30));
    final b = foe('b', s: stats(spd: 10));
    final q = TurnQueue(FixedRandom())..startRound([a, b], 1);

    expect(q.next()?.id, 'a');
    expect(q.next()?.id, 'b');
    expect(q.next(), isNull);
  });

  test('unit with priority acts first and the flag is consumed', () {
    final fast = foe('fast', s: stats(spd: 50));
    final slow = hero('slow', s: stats(spd: 5))..priorityNextRound = true;
    final q = TurnQueue(FixedRandom())..startRound([fast, slow], 1);

    expect(q.remaining.map((u) => u.id), ['slow', 'fast']);
    expect(slow.priorityNextRound, isFalse);
  });

  test('broken units are left out of the round', () {
    final a = hero('a');
    final broken = foe('broken')..breakRecoverRound = 3;
    final q = TurnQueue(FixedRandom())..startRound([a, broken], 2);

    expect(q.remaining.map((u) => u.id), ['a']);
  });

  test('units that die or break mid-round are skipped by next()', () {
    final a = hero('a', s: stats(spd: 30));
    final b = foe('b', s: stats(spd: 20));
    final c = foe('c', s: stats(spd: 10));
    final q = TurnQueue(FixedRandom())..startRound([a, b, c], 1);

    expect(q.next()?.id, 'a');
    b.hp = 0;
    c.breakRecoverRound = 3;
    expect(q.next(), isNull);
  });

  test('next-round preview includes units that recover by then', () {
    final a = hero('a', s: stats(spd: 10));
    final recovering = foe('r', s: stats(spd: 30))..breakRecoverRound = 2;
    final stillBroken = foe('s', s: stats(spd: 40))..breakRecoverRound = 3;
    final q = TurnQueue(FixedRandom())..startRound([a, recovering, stillBroken], 1);

    expect(q.remaining.map((u) => u.id), ['a']);
    expect(q.previewNextRound([a, recovering, stillBroken], 1).map((u) => u.id),
        ['r', 'a']);
  });

  test('preview uses the rolls the next round will actually use', () {
    // Round 1 rolls: a 1.0 / b 1.0; round 2 rolls: a 1.1 / b 0.9.
    final a = hero('a', s: stats(spd: 20));
    final b = hero('b', s: stats(spd: 21));
    final q = TurnQueue(FixedRandom(doubles: [0.5, 0.5, 1.0, 0.0]))
      ..startRound([a, b], 1);
    expect(q.remaining.map((u) => u.id), ['b', 'a']);

    final preview = q.previewNextRound([a, b], 1).map((u) => u.id).toList();
    expect(preview, ['a', 'b']);

    q.startRound([a, b], 2);
    expect(q.remaining.map((u) => u.id), preview);
  });

  test('preview puts units that defended this round first', () {
    final fast = foe('fast', s: stats(spd: 50));
    final slow = hero('slow', s: stats(spd: 5));
    final q = TurnQueue(FixedRandom())..startRound([fast, slow], 1);
    slow.priorityNextRound = true;

    expect(q.previewNextRound([fast, slow], 1).map((u) => u.id),
        ['slow', 'fast']);
  });
}
