import 'package:ashen_crest/domain/battle/damage_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_random.dart';

void main() {
  group('DamageCalculator.damage', () {
    final calc = DamageCalculator(FixedRandom());

    int dmg({
      int attack = 34,
      int defense = 20,
      double power = 1.0,
      bool weakness = false,
      bool broken = false,
      bool defending = false,
    }) =>
        calc.damage(
          attack: attack,
          defense: defense,
          power: power,
          weakness: weakness,
          broken: broken,
          defending: defending,
        );

    test('base formula is ATK·P − DEF/2 with neutral variance', () {
      // 34·1.0 − 20/2 = 24
      expect(dmg(), 24);
      // 34·1.5 − 10 = 41
      expect(dmg(power: 1.5), 41);
    });

    test('never deals less than 1', () {
      expect(dmg(attack: 5, defense: 200), 1);
    });

    test('weakness multiplies by 1.3', () {
      expect(dmg(weakness: true), (24 * 1.3).round());
    });

    test('break multiplies by 2.0', () {
      expect(dmg(broken: true), 48);
    });

    test('weakness and break stack', () {
      expect(dmg(weakness: true, broken: true), (24 * 1.3 * 2).round());
    });

    test('defending target takes half damage', () {
      expect(dmg(defending: true), 12);
    });

    test('variance spans 0.95–1.05', () {
      final low = DamageCalculator(FixedRandom(doubles: [0.0]));
      final high = DamageCalculator(FixedRandom(doubles: [1.0]));
      int roll(DamageCalculator c) => c.damage(
            attack: 120,
            defense: 0,
            power: 1.0,
            weakness: false,
            broken: false,
            defending: false,
          );
      expect(roll(low), 114); // 120 · 0.95
      expect(roll(high), 126); // 120 · 1.05
    });
  });

  group('DamageCalculator.heal', () {
    test('heal is EATK · power with neutral variance', () {
      final calc = DamageCalculator(FixedRandom());
      expect(calc.heal(eatk: 32, power: 2.0), 64);
    });
  });

  group('boost multiplier', () {
    test('matches spec table 1.0 / 1.6 / 2.2 / 3.0', () {
      expect(DamageCalculator.boostMultiplier(0), 1.0);
      expect(DamageCalculator.boostMultiplier(1), 1.6);
      expect(DamageCalculator.boostMultiplier(2), 2.2);
      expect(DamageCalculator.boostMultiplier(3), 3.0);
    });
  });
}
