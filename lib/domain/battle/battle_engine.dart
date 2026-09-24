import 'dart:math';

import '../../core/constants.dart';
import '../attack_type.dart';
import '../inventory.dart';
import '../item.dart';
import '../skill.dart';
import 'battle_action.dart';
import 'battle_event.dart';
import 'battle_unit.dart';
import 'damage_calculator.dart';
import 'enemy_ai.dart';
import 'turn_queue.dart';

enum BattlePhase { intro, playerTurn, enemyTurn, victory, defeat, escaped }

/// Pure-Dart Break & Boost battle rules.
///
/// Flow: [start] → (player: [submitAction]) → [nextTurn] → … Enemy turns are
/// resolved inside [nextTurn]. Every call returns the events that happened.
class BattleEngine {
  BattleEngine({
    required List<BattleUnit> party,
    required List<BattleUnit> enemies,
    Random? random,
    this.ai = const EnemyAi(),
    this.inventory,
    this.items = const {},
  })  : party = List.unmodifiable(party),
        enemies = List.unmodifiable(enemies),
        _random = random ?? Random() {
    _calc = DamageCalculator(_random);
    _queue = TurnQueue(_random);
    for (final u in party) {
      u.bp = BattleRules.startBp;
    }
  }

  final List<BattleUnit> party;
  final List<BattleUnit> enemies;
  final EnemyAi ai;

  /// Party inventory shared with the overworld; null disables items.
  final Inventory? inventory;
  final Map<String, ItemDef> items;
  final Random _random;
  late final DamageCalculator _calc;
  late final TurnQueue _queue;

  BattlePhase phase = BattlePhase.intro;
  int round = 0;
  BattleUnit? currentActor;
  bool _actorDone = false;

  List<BattleUnit> get units => [...party, ...enemies];
  bool get isOver =>
      phase == BattlePhase.victory ||
      phase == BattlePhase.defeat ||
      phase == BattlePhase.escaped;
  bool get awaitingPlayer => phase == BattlePhase.playerTurn && !_actorDone;
  bool get canFlee => !enemies.any((e) => e.isBoss);
  int get maxBoost =>
      min(BattleRules.maxBoostPerAction, currentActor?.bp ?? 0);

  /// Consumables the party holds that can be used in battle.
  List<ItemDef> get usableItems => [
        for (final id in inventory?.items.keys ?? const <String>[])
          if (items[id] case final def? when def.isConsumable && def.effect != ItemEffect.none) def,
      ];

  List<BattleUnit> get upcomingThisRound => _queue.remaining;
  List<BattleUnit> get nextRoundOrder => _queue.previewNextRound(units, round);

  BattleUnit unit(String id) => units.firstWhere((u) => u.id == id);

  List<BattleEvent> start() {
    if (phase != BattlePhase.intro) throw StateError('Battle already started');
    final events = <BattleEvent>[const BattleStarted()];
    _beginNextTurn(events);
    return events;
  }

  /// Advances to the next unit's turn (resolving it if it is an enemy).
  List<BattleEvent> nextTurn() {
    if (isOver) return const [];
    if (awaitingPlayer) throw StateError('Waiting for a party action');
    final events = <BattleEvent>[];
    _beginNextTurn(events);
    return events;
  }

  List<BattleEvent> submitAction(BattleAction action) {
    if (!awaitingPlayer) throw StateError('Not a party turn');
    final actor = currentActor!;
    _validate(actor, action);
    final events = <BattleEvent>[];
    _resolve(actor, action, events);
    _actorDone = true;
    _checkEnd(events);
    return events;
  }

  void _beginNextTurn(List<BattleEvent> events) {
    var next = _queue.next();
    if (next == null) {
      _startRound(events);
      next = _queue.next()!;
    }
    final actor = currentActor = next;
    _actorDone = false;
    actor.defending = false;
    events.add(TurnStarted(actor.id));

    if (actor.isParty) {
      if (actor.boostedLastTurn) {
        actor.boostedLastTurn = false;
      } else if (actor.bp < BattleRules.maxBp) {
        actor.bp++;
        events.add(BpChanged(actor.id, actor.bp));
      }
      phase = BattlePhase.playerTurn;
      return;
    }

    phase = BattlePhase.enemyTurn;
    _resolve(actor, ai.choose(actor, party, _random), events);
    _actorDone = true;
    _checkEnd(events);
  }

  void _startRound(List<BattleEvent> events) {
    round++;
    events.add(RoundStarted(round));
    for (final u in units) {
      final recover = u.breakRecoverRound;
      if (recover != null && recover <= round) {
        u.breakRecoverRound = null;
        u.shield = u.maxShield;
        if (u.isAlive) events.add(BreakRecovered(u.id, u.shield));
      }
    }
    _queue.startRound(units, round);
  }

  void _validate(BattleUnit actor, BattleAction action) {
    int boostOf(BattleAction a) => switch (a) {
          AttackAction(:final boost) || SkillAction(:final boost) => boost,
          _ => 0,
        };
    final boost = boostOf(action);
    if (boost < 0 || boost > maxBoost) {
      throw ArgumentError.value(boost, 'boost', 'max $maxBoost');
    }
    switch (action) {
      case AttackAction(:final targetId, :final weapon):
        _requireLiving(targetId, Side.enemy);
        if (weapon != null && !actor.weapons.contains(weapon)) {
          throw ArgumentError.value(weapon, 'weapon', 'not carried by ${actor.id}');
        }
      case SkillAction(:final skill, :final targetId):
        if (actor.sp < skill.spCost) {
          throw ArgumentError('Not enough SP for ${skill.id}');
        }
        switch (skill.target) {
          case SkillTarget.singleEnemy:
            _requireLiving(targetId, Side.enemy);
          case SkillTarget.singleAlly:
            _requireLiving(targetId, Side.party);
          case SkillTarget.allEnemies || SkillTarget.randomEnemies:
            break;
        }
      case FleeAction():
        if (!canFlee) throw ArgumentError('Cannot flee from a boss');
      case DefendAction():
        break;
      case ItemAction(:final itemId, :final targetId):
        final def = items[itemId];
        if (def == null || (inventory?.count(itemId) ?? 0) == 0) {
          throw ArgumentError.value(itemId, 'itemId', 'not in the inventory');
        }
        final target = party.where((u) => u.id == targetId).firstOrNull;
        if (target == null || !def.canUseOn(target)) {
          throw ArgumentError.value(targetId, 'targetId', '$itemId has no effect');
        }
    }
  }

  void _requireLiving(String? id, Side side) {
    final ok = id != null &&
        units.any((u) => u.id == id && u.side == side && u.isAlive);
    if (!ok) throw ArgumentError.value(id, 'targetId', 'no living $side');
  }

  void _resolve(BattleUnit actor, BattleAction action, List<BattleEvent> events) {
    events.add(ActionAnnounced(actor.id, action));
    switch (action) {
      case AttackAction(:final targetId, :final boost, :final weapon):
        _spendBoost(actor, boost, events);
        final target = unit(targetId);
        final type = weapon ?? actor.weapons.first;
        for (var i = 0; i < 1 + boost && target.isAlive; i++) {
          _hit(actor, target, [type], 1.0, true, events);
        }
      case SkillAction(:final skill, :final targetId, :final boost):
        actor.sp -= skill.spCost;
        events.add(SpChanged(actor.id, actor.sp));
        _spendBoost(actor, boost, events);
        final power = skill.power * DamageCalculator.boostMultiplier(boost);
        _useSkill(actor, skill, targetId, power, events);
      case DefendAction():
        actor.defending = true;
        actor.priorityNextRound = true;
        events.add(DefendStarted(actor.id));
      case ItemAction(:final itemId, :final targetId):
        final target = unit(targetId);
        inventory!.remove(itemId);
        events.add(ItemUsed(unitId: actor.id, itemId: itemId, targetId: targetId));
        final result = items[itemId]!.use(target)!;
        if (result.revived) {
          events.add(Revived(target.id, target.hp));
        } else if (result.hp > 0) {
          events.add(Healed(sourceId: actor.id, targetId: target.id, amount: result.hp, hpAfter: target.hp));
        }
        if (result.sp > 0) events.add(SpChanged(target.id, target.sp));
      case FleeAction():
        if (_random.nextDouble() < BattleRules.fleeChance) {
          phase = BattlePhase.escaped;
          events.add(const Escaped());
        } else {
          events.add(const EscapeFailed());
        }
    }
  }

  void _spendBoost(BattleUnit actor, int boost, List<BattleEvent> events) {
    if (boost == 0) return;
    actor.bp -= boost;
    actor.boostedLastTurn = true;
    events.add(BpChanged(actor.id, actor.bp));
  }

  void _useSkill(
    BattleUnit actor,
    Skill skill,
    String? targetId,
    double power,
    List<BattleEvent> events,
  ) {
    List<BattleUnit> livingFoes() =>
        (actor.isParty ? enemies : party).where((u) => u.isAlive).toList();

    switch (skill.target) {
      case SkillTarget.singleAlly:
        final target = unit(targetId!);
        final before = target.hp;
        target.hp = min(target.stats.hp,
            target.hp + _calc.heal(eatk: actor.stats.eatk, power: power));
        events.add(Healed(
          sourceId: actor.id,
          targetId: target.id,
          amount: target.hp - before,
          hpAfter: target.hp,
        ));
      case SkillTarget.singleEnemy:
        final target = unit(targetId!);
        for (var i = 0; i < skill.hits && target.isAlive; i++) {
          _hit(actor, target, skill.types, power, skill.isPhysical, events);
        }
      case SkillTarget.allEnemies:
        for (final target in livingFoes()) {
          for (var i = 0; i < skill.hits && target.isAlive; i++) {
            _hit(actor, target, skill.types, power, skill.isPhysical, events);
          }
        }
      case SkillTarget.randomEnemies:
        for (var i = 0; i < skill.hits; i++) {
          final foes = livingFoes();
          if (foes.isEmpty) break;
          final target = foes[_random.nextInt(foes.length)];
          _hit(actor, target, skill.types, power, skill.isPhysical, events);
        }
    }
  }

  void _hit(
    BattleUnit attacker,
    BattleUnit target,
    List<AttackType> types,
    double power,
    bool physical,
    List<BattleEvent> events,
  ) {
    final matched = types.where(target.weaknesses.contains).toList();
    final weakness = matched.isNotEmpty;
    for (final t in matched) {
      if (target.revealed.add(t)) events.add(WeaknessRevealed(target.id, t));
    }

    final wasBroken = target.isBroken;
    final amount = _calc.damage(
      attack: physical ? attacker.stats.atk : attacker.stats.eatk,
      defense: physical ? target.stats.def : target.stats.edef,
      power: power,
      weakness: weakness,
      broken: wasBroken,
      defending: target.defending,
    );
    target.hp = max(0, target.hp - amount);
    events.add(DamageDealt(
      sourceId: attacker.id,
      targetId: target.id,
      amount: amount,
      hpAfter: target.hp,
      weakness: weakness,
    ));

    if (weakness && !wasBroken && target.shield > 0) {
      target.shield--;
      events.add(ShieldReduced(target.id, target.shield));
      if (target.shield == 0) {
        target.breakRecoverRound = round + BattleRules.breakRecoverRounds;
        events.add(BreakStarted(target.id));
      }
    }

    if (!target.isAlive) events.add(UnitDefeated(target.id));
  }

  void _checkEnd(List<BattleEvent> events) {
    if (isOver) return;
    if (enemies.every((e) => !e.isAlive)) {
      phase = BattlePhase.victory;
      events.add(Victory(
        exp: enemies.fold(0, (sum, e) => sum + e.exp),
        keping: enemies.fold(0, (sum, e) => sum + e.keping),
      ));
    } else if (party.every((p) => !p.isAlive)) {
      phase = BattlePhase.defeat;
      events.add(const Defeat());
    }
  }
}
