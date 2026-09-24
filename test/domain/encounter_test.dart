import 'package:ashen_crest/domain/encounter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixed_random.dart';

void main() {
  group('EncounterMeter', () {
    EncounterMeter meter({double roll = 0.5}) =>
        EncounterMeter(random: FixedRandom(doubles: [roll]), minDistance: 400, maxDistance: 800);

    test('triggers after walking the rolled distance, then re-rolls', () {
      final m = meter(); // threshold 600
      expect(m.advance(599, 0.1), isFalse);
      expect(m.advance(1, 0.1), isTrue);
      expect(m.traveled, 0);
    });

    test('danger rises green → yellow → red with progress', () {
      final m = meter(roll: 0); // threshold 400
      expect(m.danger, Danger.low);
      m.advance(220, 0.1);
      expect(m.danger, Danger.medium);
      m.advance(120, 0.1);
      expect(m.danger, Danger.high);
    });

    test('is paused during the safe period after a battle', () {
      final m = meter(roll: 0)..startSafePeriod(3);
      expect(m.advance(1000, 2.9), isFalse);
      expect(m.traveled, 0);
      expect(m.advance(1000, 0.2), isTrue); // safe time ran out mid-step
    });
  });

  group('EncounterTable', () {
    final table = EncounterTable.fromJson({
      'minDistance': 300,
      'maxDistance': 600,
      'groups': [
        {'weight': 3, 'enemies': ['ashen_rat', 'ashen_rat']},
        {'weight': 1, 'enemies': ['moss_wolf']},
      ],
    });

    test('picks groups by weight', () {
      expect(table.pick(FixedRandom(doubles: [0.0])), ['ashen_rat', 'ashen_rat']);
      expect(table.pick(FixedRandom(doubles: [0.74])), ['ashen_rat', 'ashen_rat']);
      expect(table.pick(FixedRandom(doubles: [0.76])), ['moss_wolf']);
    });

    test('reads distances', () {
      expect(table.minDistance, 300);
      expect(table.maxDistance, 600);
    });
  });
}
