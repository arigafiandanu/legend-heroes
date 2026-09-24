import '../attack_type.dart';
import '../item.dart';
import '../skill.dart';
import '../stats.dart';

enum Side { party, enemy }

/// Mutable per-battle state of one combatant.
class BattleUnit implements Vitals {
  BattleUnit.party({
    required this.id,
    required this.name,
    required this.stats,
    required this.weapons,
    this.skills = const [],
    int? hp,
    int? sp,
  })  : assert(weapons.isNotEmpty),
        side = Side.party,
        maxShield = 0,
        weaknesses = const {},
        isBoss = false,
        exp = 0,
        keping = 0,
        hp = hp ?? stats.hp,
        sp = sp ?? stats.sp,
        shield = 0,
        revealed = {};

  BattleUnit.enemy({
    required this.id,
    required this.name,
    required this.stats,
    required this.shield,
    required this.weaknesses,
    AttackType attackType = AttackType.sword,
    this.isBoss = false,
    this.exp = 0,
    this.keping = 0,
    Set<AttackType> revealed = const {},
  })  : side = Side.enemy,
        revealed = {...revealed},
        weapons = [attackType],
        skills = const [],
        maxShield = shield,
        hp = stats.hp,
        sp = stats.sp;

  final String id;
  final String name;
  final Side side;
  final Stats stats;

  /// Weapon types usable by a basic attack; the first is the default.
  final List<AttackType> weapons;
  final List<Skill> skills;
  final int maxShield;
  final Set<AttackType> weaknesses;
  final bool isBoss;
  final int exp;
  final int keping;

  @override
  int hp;
  @override
  int sp;
  int shield;
  int bp = 0;

  /// Weaknesses the player has uncovered (pre-filled from the bestiary).
  final Set<AttackType> revealed;

  /// Boost was used on this unit's latest turn (no BP gain next turn).
  bool boostedLastTurn = false;

  /// Takes reduced damage until this unit's next turn starts.
  bool defending = false;

  /// Acts first next round (set by Defend).
  bool priorityNextRound = false;

  /// Round at whose start this unit recovers from Break; null = not broken.
  int? breakRecoverRound;

  @override
  int get maxHp => stats.hp;
  @override
  int get maxSp => stats.sp;

  bool get isParty => side == Side.party;
  bool get isAlive => hp > 0;
  bool get isBroken => breakRecoverRound != null;
}
