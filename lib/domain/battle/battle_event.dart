import '../attack_type.dart';
import 'battle_action.dart';

/// What happened during a turn, in order. The presentation layer plays these
/// back as animations; the engine state is already final when they arrive.
sealed class BattleEvent {
  const BattleEvent();
}

class BattleStarted extends BattleEvent {
  const BattleStarted();
}

class RoundStarted extends BattleEvent {
  const RoundStarted(this.round);
  final int round;
}

class TurnStarted extends BattleEvent {
  const TurnStarted(this.unitId);
  final String unitId;
}

class ActionAnnounced extends BattleEvent {
  const ActionAnnounced(this.unitId, this.action);
  final String unitId;
  final BattleAction action;
}

class BpChanged extends BattleEvent {
  const BpChanged(this.unitId, this.bp);
  final String unitId;
  final int bp;
}

class SpChanged extends BattleEvent {
  const SpChanged(this.unitId, this.sp);
  final String unitId;
  final int sp;
}

class DamageDealt extends BattleEvent {
  const DamageDealt({
    required this.sourceId,
    required this.targetId,
    required this.amount,
    required this.hpAfter,
    this.weakness = false,
  });
  final String sourceId;
  final String targetId;
  final int amount;
  final int hpAfter;
  final bool weakness;
}

class Healed extends BattleEvent {
  const Healed({
    required this.sourceId,
    required this.targetId,
    required this.amount,
    required this.hpAfter,
  });
  final String sourceId;
  final String targetId;
  final int amount;
  final int hpAfter;
}

class WeaknessRevealed extends BattleEvent {
  const WeaknessRevealed(this.unitId, this.type);
  final String unitId;
  final AttackType type;
}

class ShieldReduced extends BattleEvent {
  const ShieldReduced(this.unitId, this.shield);
  final String unitId;
  final int shield;
}

class BreakStarted extends BattleEvent {
  const BreakStarted(this.unitId);
  final String unitId;
}

class BreakRecovered extends BattleEvent {
  const BreakRecovered(this.unitId, this.shield);
  final String unitId;
  final int shield;
}

class DefendStarted extends BattleEvent {
  const DefendStarted(this.unitId);
  final String unitId;
}

class UnitDefeated extends BattleEvent {
  const UnitDefeated(this.unitId);
  final String unitId;
}

class EscapeFailed extends BattleEvent {
  const EscapeFailed();
}

class Escaped extends BattleEvent {
  const Escaped();
}

class Victory extends BattleEvent {
  const Victory({required this.exp, required this.keping});
  final int exp;
  final int keping;
}

class Defeat extends BattleEvent {
  const Defeat();
}
