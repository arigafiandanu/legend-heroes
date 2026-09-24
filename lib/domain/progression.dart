import 'dart:math';

abstract final class Progression {
  static const levelCap = 15;

  /// EXP needed to go from [level] to level + 1: 20 × L^1.8 (spec).
  static int expToNext(int level) =>
      level >= levelCap ? 0 : (20 * pow(level, 1.8)).round();
}
