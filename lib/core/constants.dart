/// Global tuning constants. Numbers come from the Chapter 1 spec.
abstract final class Screen {
  /// Virtual resolution, integer-scaled to the device.
  static const double virtualWidth = 480;
  static const double virtualHeight = 270;
}

abstract final class Movement {
  static const double walkSpeed = 120; // px/s
  static const double runSpeed = 200; // px/s
}

abstract final class BattleRules {
  static const int startBp = 1;
  static const int maxBp = 5;
  static const int maxBoostPerAction = 3;

  /// Skill power multiplier indexed by BP spent.
  static const List<double> skillBoostMultipliers = [1.0, 1.6, 2.2, 3.0];

  static const double damageVarianceMin = 0.95;
  static const double damageVarianceMax = 1.05;
  static const double speedVarianceMin = 0.9;
  static const double speedVarianceMax = 1.1;

  static const double weaknessMultiplier = 1.3;
  static const double breakMultiplier = 2.0;
  static const double defendMultiplier = 0.5;

  /// Break at round N: skip rest of N and all of N+1, recover at N+2.
  static const int breakRecoverRounds = 2;

  static const double fleeChance = 0.6;
}
