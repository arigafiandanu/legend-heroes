import 'dart:math';

import '../../core/constants.dart';

/// Damage & heal formulas from the spec:
/// `Dmg = max(1, ATK·P − DEF/2) · R · W · B`.
class DamageCalculator {
  DamageCalculator(this._random);

  final Random _random;

  /// Skill power multiplier for BP spent on a skill (0–3 BP).
  static double boostMultiplier(int bp) => BattleRules.skillBoostMultipliers[bp];

  /// R: random 0.95–1.05.
  double _variance() =>
      BattleRules.damageVarianceMin +
      _random.nextDouble() *
          (BattleRules.damageVarianceMax - BattleRules.damageVarianceMin);

  int damage({
    required int attack,
    required int defense,
    required double power,
    required bool weakness,
    required bool broken,
    required bool defending,
  }) {
    final base = max(1.0, attack * power - defense / 2);
    final value = base *
        _variance() *
        (weakness ? BattleRules.weaknessMultiplier : 1.0) *
        (broken ? BattleRules.breakMultiplier : 1.0) *
        (defending ? BattleRules.defendMultiplier : 1.0);
    return max(1, value.round());
  }

  int heal({required int eatk, required double power}) =>
      max(1, (eatk * power * _variance()).round());
}
