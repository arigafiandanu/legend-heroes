import '../attack_type.dart';
import '../skill.dart';

sealed class BattleAction {
  const BattleAction();
}

/// Basic weapon attack: hits 1 + [boost] times with [weapon] (default: the
/// unit's first weapon).
class AttackAction extends BattleAction {
  const AttackAction({required this.targetId, this.boost = 0, this.weapon});
  final String targetId;
  final int boost;
  final AttackType? weapon;
}

/// [targetId] is required for single-target skills, ignored otherwise.
class SkillAction extends BattleAction {
  const SkillAction({required this.skill, this.targetId, this.boost = 0});
  final Skill skill;
  final String? targetId;
  final int boost;
}

class DefendAction extends BattleAction {
  const DefendAction();
}

class FleeAction extends BattleAction {
  const FleeAction();
}
