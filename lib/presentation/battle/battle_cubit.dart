import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/attack_type.dart';
import '../../domain/battle/battle_action.dart';
import '../../domain/battle/battle_engine.dart';
import '../../domain/battle/battle_event.dart';
import '../../domain/battle/battle_unit.dart';
import '../../domain/skill.dart';
import 'battle_state.dart';

/// Bridges [BattleEngine] and the view.
///
/// Engine results are pushed to [playback]; the battle world animates them,
/// reports each one via [onEventPlayed], then calls [playbackDone]. HUD
/// numbers follow playback ([shownHp] …), not the engine's final state.
class BattleCubit extends Cubit<BattleViewState> {
  BattleCubit(this.engine) : super(const BattleViewState()) {
    for (final u in engine.units) {
      _hp[u.id] = u.hp;
      _sp[u.id] = u.sp;
      _bp[u.id] = u.bp;
    }
  }

  final BattleEngine engine;
  final _playback = StreamController<List<BattleEvent>>.broadcast();
  final Map<String, int> _hp = {};
  final Map<String, int> _sp = {};
  final Map<String, int> _bp = {};

  Stream<List<BattleEvent>> get playback => _playback.stream;

  BattleUnit? get actor => engine.currentActor;
  int shownHp(String id) => _hp[id] ?? 0;
  int shownSp(String id) => _sp[id] ?? 0;
  int shownBp(String id) => _bp[id] ?? 0;

  void start() => _play(engine.start());

  void onEventPlayed(BattleEvent e) {
    switch (e) {
      case DamageDealt(:final targetId, :final hpAfter):
        _hp[targetId] = hpAfter;
      case Healed(:final targetId, :final hpAfter):
        _hp[targetId] = hpAfter;
      case SpChanged(:final unitId, :final sp):
        _sp[unitId] = sp;
      case BpChanged(:final unitId, :final bp):
        _bp[unitId] = bp;
      default:
        break;
    }
    if (!isClosed) emit(state.copyWith(revision: state.revision + 1));
  }

  void announce(String? text) {
    if (!isClosed) emit(state.copyWith(announcement: () => text));
  }

  void playbackDone() {
    if (isClosed) return;
    if (engine.isOver) {
      final victory = _lastVictory;
      emit(state.copyWith(
        busy: false,
        announcement: () => null,
        outcome: BattleOutcome(
          phase: engine.phase,
          exp: victory?.exp ?? 0,
          keping: victory?.keping ?? 0,
        ),
      ));
    } else if (engine.awaitingPlayer) {
      emit(BattleViewState(busy: false, revision: state.revision + 1));
    } else {
      _play(engine.nextTurn());
    }
  }

  // ---- Command menu ----

  bool get canFlee => engine.canFlee;
  int get maxBoost => engine.maxBoost;

  bool canUse(Skill skill) => (actor?.sp ?? 0) >= skill.spCost;

  /// Valid targets for the pending Attack/Skill.
  List<BattleUnit> get targets {
    final allies = state.pendingSkill?.target == SkillTarget.singleAlly;
    return [
      for (final u in allies ? engine.party : engine.enemies)
        if (u.isAlive) u,
    ];
  }

  void changeBoost(int delta) {
    if (state.busy) return;
    emit(state.copyWith(boost: (state.boost + delta).clamp(0, maxBoost)));
  }

  void openAttack() {
    final weapons = actor!.weapons;
    if (weapons.length > 1) {
      emit(state.copyWith(menu: BattleMenu.weapons, pendingSkill: () => null));
    } else {
      chooseWeapon(weapons.single);
    }
  }

  void chooseWeapon(AttackType weapon) => emit(state.copyWith(
        menu: BattleMenu.targets,
        pendingWeapon: () => weapon,
        pendingSkill: () => null,
      ));

  void openSkills() => emit(state.copyWith(menu: BattleMenu.skills));

  void chooseSkill(Skill skill) {
    if (!canUse(skill)) return;
    switch (skill.target) {
      case SkillTarget.singleEnemy || SkillTarget.singleAlly:
        emit(state.copyWith(
          menu: BattleMenu.targets,
          pendingSkill: () => skill,
          pendingWeapon: () => null,
        ));
      case SkillTarget.allEnemies || SkillTarget.randomEnemies:
        _submit(SkillAction(skill: skill, boost: state.boost));
    }
  }

  void chooseTarget(String id) {
    final skill = state.pendingSkill;
    _submit(skill != null
        ? SkillAction(skill: skill, targetId: id, boost: state.boost)
        : AttackAction(targetId: id, boost: state.boost, weapon: state.pendingWeapon));
  }

  void defend() => _submit(const DefendAction());

  void flee() {
    if (canFlee) _submit(const FleeAction());
  }

  void back() {
    final menu = switch (state.menu) {
      BattleMenu.targets when state.pendingSkill != null => BattleMenu.skills,
      BattleMenu.targets when (actor?.weapons.length ?? 0) > 1 => BattleMenu.weapons,
      _ => BattleMenu.root,
    };
    emit(state.copyWith(menu: menu));
  }

  // ---- Internals ----

  Victory? _lastVictory;

  void _submit(BattleAction action) {
    if (state.busy || !engine.awaitingPlayer) return;
    _play(engine.submitAction(action));
  }

  void _play(List<BattleEvent> events) {
    for (final e in events) {
      if (e is Victory) _lastVictory = e;
    }
    emit(state.copyWith(busy: true));
    _playback.add(events);
  }

  @override
  Future<void> close() async {
    await _playback.close();
    return super.close();
  }
}
