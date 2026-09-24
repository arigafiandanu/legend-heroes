import 'dart:math';

import 'battle_action.dart';
import 'battle_unit.dart';

/// Placeholder AI: basic attack on a random living party member.
class EnemyAi {
  const EnemyAi();

  BattleAction choose(BattleUnit actor, List<BattleUnit> party, Random random) {
    final targets = party.where((u) => u.isAlive).toList();
    return AttackAction(targetId: targets[random.nextInt(targets.length)].id);
  }
}
