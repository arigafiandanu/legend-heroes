import 'dart:math';

import '../../core/constants.dart';
import 'battle_unit.dart';

/// Per-round turn order: SPD × random 0.9–1.1, Defend priority first.
///
/// Rolls for the next round are made at the start of the current one so the
/// timeline preview matches the real order unless Break/Defend change it.
class TurnQueue {
  TurnQueue(this._random);

  final Random _random;
  Map<BattleUnit, double> _nextRolls = {};
  List<BattleUnit> _order = [];
  int _cursor = 0;

  void startRound(List<BattleUnit> units, int round) {
    final rolls = {
      for (final u in units) u: _nextRolls[u] ?? _roll(),
    };
    _nextRolls = {for (final u in units) u: _roll()};
    _order = _sorted(units, rolls, round);
    for (final u in units) {
      u.priorityNextRound = false;
    }
    _cursor = 0;
  }

  /// Next unit to act this round, or null when the round is over.
  BattleUnit? next() {
    while (_cursor < _order.length) {
      final u = _order[_cursor++];
      if (u.isAlive && !u.isBroken) return u;
    }
    return null;
  }

  /// Units still waiting to act this round, in order.
  List<BattleUnit> get remaining => [
        for (final u in _order.skip(_cursor))
          if (u.isAlive && !u.isBroken) u,
      ];

  /// Expected order of round [currentRound] + 1 given current state.
  List<BattleUnit> previewNextRound(List<BattleUnit> units, int currentRound) =>
      _sorted(units, _nextRolls, currentRound + 1);

  double _roll() =>
      BattleRules.speedVarianceMin +
      _random.nextDouble() *
          (BattleRules.speedVarianceMax - BattleRules.speedVarianceMin);

  List<BattleUnit> _sorted(
    List<BattleUnit> units,
    Map<BattleUnit, double> rolls,
    int round,
  ) {
    bool actsIn(BattleUnit u) =>
        u.isAlive && (u.breakRecoverRound == null || u.breakRecoverRound! <= round);
    final eligible = units.where(actsIn).toList();
    int compare(BattleUnit a, BattleUnit b) {
      if (a.priorityNextRound != b.priorityNextRound) {
        return a.priorityNextRound ? -1 : 1;
      }
      final speed = (b.stats.spd * (rolls[b] ?? 1.0))
          .compareTo(a.stats.spd * (rolls[a] ?? 1.0));
      if (speed != 0) return speed;
      if (a.side != b.side) return a.isParty ? -1 : 1;
      return units.indexOf(a).compareTo(units.indexOf(b));
    }

    return eligible..sort(compare);
  }
}
