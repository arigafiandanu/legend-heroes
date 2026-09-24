import '../../domain/attack_type.dart';
import '../../domain/battle/battle_engine.dart';
import '../../domain/item.dart';
import '../../domain/skill.dart';

enum BattleMenu { root, weapons, skills, items, targets }

class BattleOutcome {
  const BattleOutcome({required this.phase, this.exp = 0, this.keping = 0, this.notes = const []});
  final BattlePhase phase;
  final int exp;
  final int keping;

  /// Extra result lines from the game (level ups).
  final List<String> notes;
}

class BattleViewState {
  const BattleViewState({
    this.busy = true,
    this.menu = BattleMenu.root,
    this.boost = 0,
    this.pendingWeapon,
    this.pendingSkill,
    this.pendingItem,
    this.announcement,
    this.outcome,
    this.revision = 0,
  });

  /// Events are playing back; the command menu is hidden.
  final bool busy;
  final BattleMenu menu;

  /// BP the current actor will spend on the next Attack/Skill.
  final int boost;
  final AttackType? pendingWeapon;
  final Skill? pendingSkill;
  final ItemDef? pendingItem;

  /// Short text shown while an action plays (skill name, "BREAK", …).
  final String? announcement;
  final BattleOutcome? outcome;

  /// Bumped whenever shown values change so widgets rebuild.
  final int revision;

  BattleViewState copyWith({
    bool? busy,
    BattleMenu? menu,
    int? boost,
    AttackType? Function()? pendingWeapon,
    Skill? Function()? pendingSkill,
    ItemDef? Function()? pendingItem,
    String? Function()? announcement,
    BattleOutcome? outcome,
    int? revision,
  }) =>
      BattleViewState(
        busy: busy ?? this.busy,
        menu: menu ?? this.menu,
        boost: boost ?? this.boost,
        pendingWeapon: pendingWeapon != null ? pendingWeapon() : this.pendingWeapon,
        pendingSkill: pendingSkill != null ? pendingSkill() : this.pendingSkill,
        pendingItem: pendingItem != null ? pendingItem() : this.pendingItem,
        announcement: announcement != null ? announcement() : this.announcement,
        outcome: outcome ?? this.outcome,
        revision: revision ?? this.revision,
      );
}
