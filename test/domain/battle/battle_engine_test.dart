import 'package:ashen_crest/domain/attack_type.dart';
import 'package:ashen_crest/domain/battle/battle_action.dart';
import 'package:ashen_crest/domain/battle/battle_engine.dart';
import 'package:ashen_crest/domain/battle/battle_event.dart';
import 'package:ashen_crest/domain/battle/battle_unit.dart';
import 'package:ashen_crest/domain/skill.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixed_random.dart';
import '../../helpers/units.dart';

const emberSlash = Skill(
  id: 'ember_slash',
  names: {'en': 'Ember Slash'},
  spCost: 8,
  types: [AttackType.sword, AttackType.fire],
  target: SkillTarget.singleEnemy,
  effect: SkillEffect.damage,
  power: 1.5,
);
const frostNeedle = Skill(
  id: 'frost_needle',
  names: {'en': 'Frost Needle'},
  spCost: 7,
  types: [AttackType.ice],
  target: SkillTarget.singleEnemy,
  effect: SkillEffect.damage,
  power: 1.3,
);
const crossThrust = Skill(
  id: 'cross_thrust',
  names: {'en': 'Cross Thrust'},
  spCost: 10,
  types: [AttackType.spear],
  target: SkillTarget.singleEnemy,
  effect: SkillEffect.damage,
  power: 0.8,
  hits: 2,
);
const thunderEdge = Skill(
  id: 'thunder_edge',
  names: {'en': 'Thunder Edge'},
  spCost: 14,
  types: [AttackType.lightning],
  target: SkillTarget.allEnemies,
  effect: SkillEffect.damage,
  power: 1.2,
);
const galeDance = Skill(
  id: 'gale_dance',
  names: {'en': 'Gale Dance'},
  spCost: 12,
  types: [AttackType.wind],
  target: SkillTarget.randomEnemies,
  effect: SkillEffect.damage,
  power: 1.0,
  hits: 2,
);
const heal = Skill(
  id: 'heal',
  names: {'en': 'Heal'},
  spCost: 6,
  types: [],
  target: SkillTarget.singleAlly,
  effect: SkillEffect.heal,
  power: 2.0,
);

/// Hero (SPD 30) always acts before foes (SPD ≤ 20) with neutral rolls.
BattleUnit kael({List<Skill> skills = const [emberSlash, crossThrust, thunderEdge]}) =>
    hero('kael', s: stats(atk: 34, def: 28, eatk: 18, edef: 18, spd: 30), skills: skills);

BattleEngine engineWith({
  List<BattleUnit>? party,
  required List<BattleUnit> enemies,
  FixedRandom? random,
}) =>
    BattleEngine(party: party ?? [kael()], enemies: enemies, random: random ?? FixedRandom());

List<T> ofType<T>(List<BattleEvent> events) => events.whereType<T>().toList();

/// Plays enemy turns until it is a party member's turn again.
List<BattleEvent> skipToPartyTurn(BattleEngine e) {
  final all = <BattleEvent>[];
  do {
    all.addAll(e.nextTurn());
  } while (e.phase == BattlePhase.enemyTurn);
  return all;
}

void main() {
  group('start', () {
    test('emits round 1 and gives the first turn to the fastest unit', () {
      final e = engineWith(enemies: [foe('rat', s: stats(spd: 10))]);
      final events = e.start();

      expect(events.first, isA<BattleStarted>());
      expect(ofType<RoundStarted>(events).single.round, 1);
      expect(ofType<TurnStarted>(events).single.unitId, 'kael');
      expect(e.phase, BattlePhase.playerTurn);
      expect(e.currentActor!.id, 'kael');
    });
  });

  group('Boost Points', () {
    test('party starts with 1 BP and gains 1 at the start of each turn', () {
      final e = engineWith(enemies: [foe('rat', s: stats(hp: 9999, spd: 10))]);
      final events = e.start();
      expect(e.currentActor!.bp, 2);
      expect(ofType<BpChanged>(events).single.bp, 2);

      e.submitAction(const DefendAction());
      skipToPartyTurn(e);
      expect(e.currentActor!.bp, 3);
    });

    test('no BP gain on the turn after boosting', () {
      final e = engineWith(enemies: [foe('rat', s: stats(hp: 9999, spd: 10))])..start();
      e.submitAction(const AttackAction(targetId: 'rat', boost: 2)); // 2 → 0
      skipToPartyTurn(e);
      expect(e.currentActor!.bp, 0);

      e.submitAction(const DefendAction());
      skipToPartyTurn(e);
      expect(e.currentActor!.bp, 1);
    });

    test('BP caps at 5', () {
      final e = engineWith(enemies: [foe('rat', s: stats(hp: 9999, spd: 10))])..start();
      for (var i = 0; i < 6; i++) {
        e.submitAction(const DefendAction());
        skipToPartyTurn(e);
      }
      expect(e.currentActor!.bp, 5);
    });

    test('boost above current BP or above 3 is rejected', () {
      final e = engineWith(enemies: [foe('rat', s: stats(hp: 9999, spd: 10))])..start();
      expect(() => e.submitAction(const AttackAction(targetId: 'rat', boost: 3)),
          throwsArgumentError); // only 2 BP
      e.currentActor!.bp = 5;
      expect(() => e.submitAction(const AttackAction(targetId: 'rat', boost: 4)),
          throwsArgumentError);
      expect(e.maxBoost, 3);
    });

    test('basic attack hits 1 + BP spent times', () {
      final e = engineWith(enemies: [foe('rat', s: stats(hp: 9999, spd: 10))])..start();
      final events = e.submitAction(const AttackAction(targetId: 'rat', boost: 2));
      expect(ofType<DamageDealt>(events), hasLength(3));
    });

    test('skill boost multiplies power by 1.6 at 1 BP', () {
      final e = engineWith(
        enemies: [foe('rat', s: stats(hp: 9999, def: 20, spd: 10))],
      )..start();
      final events =
          e.submitAction(const SkillAction(skill: emberSlash, targetId: 'rat', boost: 1));
      // ATK 34 · 1.5 · 1.6 − 20/2 = 71.6 → 72
      expect(ofType<DamageDealt>(events).single.amount, 72);
    });
  });

  group('attack weapon', () {
    test('defaults to the first weapon and can use any weapon the unit carries', () {
      final lira = hero('lira',
          s: stats(spd: 30), weapons: const [AttackType.staff, AttackType.dagger]);
      final rat = foe('rat', s: stats(hp: 9999, spd: 10), shield: 3, weak: {AttackType.dagger});
      final e = engineWith(party: [lira], enemies: [rat])..start();

      final staffHit = e.submitAction(const AttackAction(targetId: 'rat'));
      expect(ofType<ShieldReduced>(staffHit), isEmpty);

      skipToPartyTurn(e);
      final daggerHit = e.submitAction(
          const AttackAction(targetId: 'rat', weapon: AttackType.dagger));
      expect(ofType<ShieldReduced>(daggerHit).single.shield, 2);
    });

    test('rejects a weapon the unit does not carry', () {
      final e = engineWith(enemies: [foe('rat', s: stats(spd: 10))])..start();
      expect(
          () => e.submitAction(
              const AttackAction(targetId: 'rat', weapon: AttackType.dagger)),
          throwsArgumentError);
    });
  });

  group('skills', () {
    test('spend SP', () {
      final e = engineWith(enemies: [foe('rat', s: stats(hp: 9999, spd: 10))])..start();
      final events =
          e.submitAction(const SkillAction(skill: emberSlash, targetId: 'rat'));
      expect(e.party.single.sp, 50 - 8);
      expect(ofType<SpChanged>(events).single.sp, 42);
    });

    test('are rejected without enough SP', () {
      final e = engineWith(enemies: [foe('rat', s: stats(hp: 9999, spd: 10))])..start();
      e.currentActor!.sp = 3;
      expect(() => e.submitAction(const SkillAction(skill: emberSlash, targetId: 'rat')),
          throwsArgumentError);
    });

    test('pure element skills use EATK and EDEF', () {
      final lira = hero('lira',
          s: stats(atk: 10, eatk: 32, spd: 30), skills: const [frostNeedle]);
      final e = engineWith(
        party: [lira],
        enemies: [foe('rat', s: stats(hp: 9999, def: 90, edef: 20, spd: 10))],
      )..start();
      final events =
          e.submitAction(const SkillAction(skill: frostNeedle, targetId: 'rat'));
      // 32 · 1.3 − 20/2 = 31.6 → 32
      expect(ofType<DamageDealt>(events).single.amount, 32);
    });

    test('all-enemy skills hit every living enemy', () {
      final e = engineWith(enemies: [
        foe('a', s: stats(hp: 9999, spd: 10)),
        foe('b', s: stats(hp: 9999, spd: 10)),
        foe('c', s: stats(hp: 0, spd: 10)),
      ])..start();
      final events = e.submitAction(const SkillAction(skill: thunderEdge));
      expect(ofType<DamageDealt>(events).map((d) => d.targetId), ['a', 'b']);
    });

    test('random-target skills hit N times among living enemies', () {
      final lira = hero('lira', s: stats(spd: 30), skills: const [galeDance]);
      final e = engineWith(
        party: [lira],
        enemies: [foe('a', s: stats(hp: 9999, spd: 10)), foe('b', s: stats(hp: 9999, spd: 10))],
        random: FixedRandom(ints: [1, 0]),
      )..start();
      final events = e.submitAction(const SkillAction(skill: galeDance));
      expect(ofType<DamageDealt>(events).map((d) => d.targetId), ['b', 'a']);
    });

    test('heal restores HP up to max', () {
      final lira = hero('lira', s: stats(hp: 170, eatk: 32, spd: 30), skills: const [heal]);
      final ally = hero('kael', s: stats(hp: 220, spd: 25));
      final e = engineWith(
        party: [lira, ally],
        enemies: [foe('rat', s: stats(hp: 9999, spd: 10))],
      )..start();
      ally.hp = 200;
      final events = e.submitAction(const SkillAction(skill: heal, targetId: 'kael'));
      expect(ally.hp, 220);
      expect(ofType<Healed>(events).single.amount, 20);
    });
  });

  group('shield, weakness and Break', () {
    test('each weakness hit removes 1 shield and reveals the weakness', () {
      final e = engineWith(enemies: [
        foe('rat', s: stats(hp: 9999, spd: 10), shield: 4, weak: {AttackType.spear}),
      ])..start();
      final events =
          e.submitAction(const SkillAction(skill: crossThrust, targetId: 'rat'));

      expect(e.enemies.single.shield, 2);
      expect(ofType<ShieldReduced>(events).map((s) => s.shield), [3, 2]);
      expect(ofType<WeaknessRevealed>(events).single.type, AttackType.spear);
      expect(e.enemies.single.revealed, {AttackType.spear});
      expect(ofType<DamageDealt>(events).every((d) => d.weakness), isTrue);
    });

    test('non-weakness hits leave the shield alone', () {
      final e = engineWith(enemies: [
        foe('rat', s: stats(hp: 9999, spd: 10), shield: 2, weak: {AttackType.dagger}),
      ])..start();
      final events = e.submitAction(const AttackAction(targetId: 'rat'));
      expect(e.enemies.single.shield, 2);
      expect(ofType<ShieldReduced>(events), isEmpty);
    });

    test('shield 0 breaks: enemy loses this and next round, recovers after', () {
      final rat = foe('rat', s: stats(hp: 9999, spd: 10), shield: 2, weak: {AttackType.sword});
      final e = engineWith(enemies: [rat])..start();

      final events = e.submitAction(const AttackAction(targetId: 'rat', boost: 1));
      expect(ofType<BreakStarted>(events).single.unitId, 'rat');
      expect(rat.isBroken, isTrue);

      // Rest of round 1 and all of round 2: only kael acts.
      final r1 = e.nextTurn();
      expect(ofType<RoundStarted>(r1).single.round, 2);
      expect(e.currentActor!.id, 'kael');
      e.submitAction(const DefendAction());

      // Round 3: rat recovers with a full shield and acts again.
      final r3 = skipToPartyTurn(e);
      expect(ofType<RoundStarted>(r3).single.round, 3);
      expect(ofType<BreakRecovered>(r3).single.unitId, 'rat');
      expect(rat.shield, 2);
      expect(rat.isBroken, isFalse);
      e.submitAction(const DefendAction());
      final after = e.nextTurn();
      expect(ofType<TurnStarted>(after).single.unitId, 'rat');
    });

    test('broken enemies take double damage', () {
      final rat = foe('rat', s: stats(hp: 9999, def: 20, spd: 10), shield: 1, weak: {AttackType.fire});
      final e = engineWith(enemies: [rat])..start();
      e.submitAction(const SkillAction(skill: emberSlash, targetId: 'rat')); // breaks
      e.nextTurn();
      final events = e.submitAction(const AttackAction(targetId: 'rat'));
      // (34 − 10) · 2.0 = 48 (sword is not a weakness)
      expect(ofType<DamageDealt>(events).single.amount, 48);
    });
  });

  group('defend', () {
    test('halves damage until own next turn and grants priority', () {
      final slowHero = hero('kael', s: stats(hp: 500, def: 20, spd: 5));
      final rat = foe('rat', s: stats(atk: 50, spd: 30));
      final e = engineWith(party: [slowHero], enemies: [rat]);

      final opening = e.start(); // rat first
      final hit1 = ofType<DamageDealt>(opening).single.amount; // 50 − 10 = 40
      expect(hit1, 40);

      e.nextTurn(); // kael's turn
      e.submitAction(const DefendAction());
      final round2 = skipToPartyTurn(e);
      // Kael has priority in round 2, so he acts before the rat.
      expect(ofType<TurnStarted>(round2).single.unitId, 'kael');
      expect(ofType<DamageDealt>(round2), isEmpty);
      expect(slowHero.defending, isFalse);

      e.submitAction(const DefendAction());
      final rat2 = e.nextTurn();
      expect(ofType<DamageDealt>(rat2).single.amount, 20);
    });
  });

  group('flee', () {
    test('succeeds under 60%', () {
      final e = engineWith(enemies: [foe('rat', s: stats(spd: 10))])..start();
      final events = e.submitAction(const FleeAction());
      expect(events.last, isA<Escaped>());
      expect(e.phase, BattlePhase.escaped);
    });

    test('fails at or above 60%', () {
      final e = engineWith(
        enemies: [foe('rat', s: stats(spd: 10))],
        random: FixedRandom(doubles: [0.7]),
      )..start();
      final events = e.submitAction(const FleeAction());
      expect(events.last, isA<EscapeFailed>());
      expect(e.phase, BattlePhase.playerTurn);
    });

    test('is not allowed against a boss', () {
      final e = engineWith(enemies: [foe('boss', s: stats(spd: 10), boss: true)])..start();
      expect(e.canFlee, isFalse);
      expect(() => e.submitAction(const FleeAction()), throwsArgumentError);
    });
  });

  group('turn flow and outcome', () {
    test('enemy turns resolve inside nextTurn()', () {
      final e = engineWith(enemies: [foe('rat', s: stats(atk: 40, spd: 10))])..start();
      e.submitAction(const DefendAction());
      final events = e.nextTurn();
      expect(ofType<TurnStarted>(events).single.unitId, 'rat');
      expect(ofType<DamageDealt>(events).single.sourceId, 'rat');
    });

    test('nextTurn() while a party member still has to act is an error', () {
      final e = engineWith(enemies: [foe('rat', s: stats(spd: 10))])..start();
      expect(e.nextTurn, throwsStateError);
    });

    test('defeating every enemy is a victory with summed rewards', () {
      final e = engineWith(enemies: [
        foe('a', s: stats(hp: 1, spd: 10), exp: 12, keping: 4),
        foe('b', s: stats(hp: 1, spd: 10), exp: 8, keping: 6),
      ])..start();
      final events = e.submitAction(const SkillAction(skill: thunderEdge));
      expect(ofType<UnitDefeated>(events).map((u) => u.unitId), ['a', 'b']);
      final victory = events.last as Victory;
      expect(victory.exp, 20);
      expect(victory.keping, 10);
      expect(e.phase, BattlePhase.victory);
      expect(e.nextTurn(), isEmpty);
    });

    test('losing the whole party is a defeat', () {
      final e = engineWith(
        party: [hero('kael', s: stats(hp: 10, spd: 5))],
        enemies: [foe('rat', s: stats(atk: 99, spd: 30))],
      );
      final events = e.start();
      expect(events.last, isA<Defeat>());
      expect(e.phase, BattlePhase.defeat);
    });

    test('timeline lists who is still to act and next round', () {
      final e = engineWith(
        party: [kael(), hero('lira', s: stats(spd: 25))],
        enemies: [foe('rat', s: stats(spd: 10))],
      )..start();
      expect(e.upcomingThisRound.map((u) => u.id), ['lira', 'rat']);
      expect(e.nextRoundOrder.map((u) => u.id), ['kael', 'lira', 'rat']);
    });
  });
}
