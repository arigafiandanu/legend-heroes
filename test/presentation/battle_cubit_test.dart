import 'package:ashen_crest/domain/attack_type.dart';
import 'package:ashen_crest/domain/battle/battle_engine.dart';
import 'package:ashen_crest/domain/battle/battle_event.dart';
import 'package:ashen_crest/domain/battle/battle_unit.dart';
import 'package:ashen_crest/domain/skill.dart';
import 'package:ashen_crest/presentation/battle/battle_cubit.dart';
import 'package:ashen_crest/presentation/battle/battle_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixed_random.dart';
import '../helpers/units.dart';

const frostNeedle = Skill(
  id: 'frost_needle',
  names: {'en': 'Frost Needle'},
  spCost: 7,
  types: [AttackType.ice],
  target: SkillTarget.singleEnemy,
  effect: SkillEffect.damage,
  power: 1.3,
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

class Harness {
  Harness({List<BattleUnit>? party, List<BattleUnit>? enemies})
      : cubit = BattleCubit(BattleEngine(
          party: party ??
              [
                hero('kael',
                    s: stats(spd: 30),
                    skills: const [thunderEdge, frostNeedle]),
              ],
          enemies: enemies ?? [foe('rat', s: stats(hp: 9999, spd: 10))],
          random: FixedRandom(),
        )) {
    cubit.playback.listen(played.add);
  }

  final BattleCubit cubit;
  final List<List<BattleEvent>> played = [];

  List<BattleEvent> get lastPlayed => played.last;

  /// Plays back every pending batch (as BattleWorld would) until input is
  /// needed or the battle ends.
  Future<void> settle() async {
    await pumpEventQueue();
    while (cubit.state.busy && cubit.state.outcome == null) {
      for (final e in played.last) {
        cubit.onEventPlayed(e);
      }
      cubit.playbackDone();
      await pumpEventQueue();
    }
  }
}

void main() {
  test('start plays the opening, then waits for the first party action', () async {
    final h = Harness();
    h.cubit.start();
    await pumpEventQueue();
    expect(h.cubit.state.busy, isTrue);
    expect(h.lastPlayed.whereType<TurnStarted>().single.unitId, 'kael');

    await h.settle();
    expect(h.cubit.state.busy, isFalse);
    expect(h.cubit.state.menu, BattleMenu.root);
    expect(h.cubit.actor?.id, 'kael');
  });

  test('attack with one weapon goes straight to targets; picking one submits', () async {
    final h = Harness()..cubit.start();
    await h.settle();

    h.cubit.openAttack();
    expect(h.cubit.state.menu, BattleMenu.targets);
    expect(h.cubit.targets.map((u) => u.id), ['rat']);

    h.cubit.chooseTarget('rat');
    await pumpEventQueue();
    expect(h.cubit.state.busy, isTrue);
    expect(h.lastPlayed.whereType<DamageDealt>(), hasLength(1));
  });

  test('attack with two weapons asks for the weapon first', () async {
    final h = Harness(party: [
      hero('lira', s: stats(spd: 30), weapons: const [AttackType.staff, AttackType.dagger]),
    ])
      ..cubit.start();
    await h.settle();

    h.cubit.openAttack();
    expect(h.cubit.state.menu, BattleMenu.weapons);
    h.cubit.chooseWeapon(AttackType.dagger);
    expect(h.cubit.state.menu, BattleMenu.targets);
    expect(h.cubit.state.pendingWeapon, AttackType.dagger);

    h.cubit.back();
    expect(h.cubit.state.menu, BattleMenu.weapons);
    h.cubit.back();
    expect(h.cubit.state.menu, BattleMenu.root);
  });

  test('boost is clamped to what the actor can spend and resets next turn', () async {
    final h = Harness()..cubit.start();
    await h.settle(); // kael has 2 BP

    h.cubit.changeBoost(1);
    h.cubit.changeBoost(1);
    h.cubit.changeBoost(1);
    expect(h.cubit.state.boost, 2);
    h.cubit.changeBoost(-5);
    expect(h.cubit.state.boost, 0);

    h.cubit.changeBoost(1);
    h.cubit.openAttack();
    h.cubit.chooseTarget('rat');
    await pumpEventQueue();
    expect(h.lastPlayed.whereType<DamageDealt>(), hasLength(2));

    await h.settle();
    expect(h.cubit.state.boost, 0);
  });

  test('enemy turns play back until the next party turn', () async {
    final h = Harness()..cubit.start();
    await h.settle();
    h.cubit.defend();
    await h.settle();

    final enemyBatch = h.played.firstWhere(
        (b) => b.whereType<TurnStarted>().any((t) => t.unitId == 'rat'));
    expect(enemyBatch.whereType<DamageDealt>().single.sourceId, 'rat');
    expect(h.cubit.state.busy, isFalse);
    expect(h.cubit.actor?.id, 'kael');
  });

  test('shown HP only changes as events are played back', () async {
    final h = Harness(enemies: [foe('rat', s: stats(atk: 40, spd: 10))])..cubit.start();
    await h.settle();
    h.cubit.defend();
    await pumpEventQueue();
    for (final e in h.lastPlayed) {
      h.cubit.onEventPlayed(e);
    }
    h.cubit.playbackDone(); // rat's turn is now queued but not played
    await pumpEventQueue();

    expect(h.cubit.shownHp('kael'), 200);
    for (final e in h.lastPlayed) {
      h.cubit.onEventPlayed(e);
    }
    expect(h.cubit.shownHp('kael'), 200 - 15); // (40 − 10) · 0.5
  });

  test('all-enemy skills submit without choosing a target', () async {
    final h = Harness()..cubit.start();
    await h.settle();
    h.cubit.openSkills();
    expect(h.cubit.state.menu, BattleMenu.skills);
    h.cubit.chooseSkill(thunderEdge);
    await pumpEventQueue();
    expect(h.lastPlayed.whereType<DamageDealt>(), isNotEmpty);
  });

  test('skills without enough SP cannot be used', () async {
    final h = Harness()..cubit.start();
    await h.settle();
    h.cubit.actor!.sp = 10;
    expect(h.cubit.canUse(frostNeedle), isTrue);
    expect(h.cubit.canUse(thunderEdge), isFalse);
  });

  test('victory ends with an outcome carrying the rewards', () async {
    final h = Harness(enemies: [foe('rat', s: stats(hp: 1, spd: 10), exp: 8, keping: 6)])
      ..cubit.start();
    await h.settle();
    h.cubit.openAttack();
    h.cubit.chooseTarget('rat');
    await h.settle();
    h.cubit.playbackDone();

    final outcome = h.cubit.state.outcome!;
    expect(outcome.phase, BattlePhase.victory);
    expect(outcome.exp, 8);
    expect(outcome.keping, 6);
  });
}
