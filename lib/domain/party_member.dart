import 'dart:math';

import 'character_def.dart';
import 'item.dart';
import 'progression.dart';
import 'stats.dart';

enum EquipSlot { weapon, armor, accessory }

/// Persistent state of one party member between battles.
class PartyMember implements Vitals {
  PartyMember({
    required this.def,
    this.level = 1,
    this.exp = 0,
    int? hp,
    int? sp,
    Map<EquipSlot, String>? equipment,
  }) : equipment = {...?equipment} {
    this.hp = hp ?? maxHp;
    this.sp = sp ?? maxSp;
  }

  factory PartyMember.fromJson(Map<String, dynamic> json, CharacterDef def) => PartyMember(
        def: def,
        level: json['level'] as int,
        exp: json['exp'] as int,
        hp: json['hp'] as int,
        sp: json['sp'] as int,
        equipment: {
          for (final e in (json['equipment'] as Map? ?? const {}).entries)
            EquipSlot.values.byName(e.key as String): e.value as String,
        },
      );

  final CharacterDef def;
  int level;
  int exp;
  @override
  late int hp;
  @override
  late int sp;

  /// Equipped item ids. Equipment effects arrive with the equip screen (M4).
  final Map<EquipSlot, String> equipment;

  String get id => def.id;
  Stats get stats => def.statsAt(level);
  @override
  int get maxHp => stats.hp;
  @override
  int get maxSp => stats.sp;
  bool get isKnockedOut => hp <= 0;
  int get expToNext => Progression.expToNext(level);

  /// Adds EXP and returns every level reached. A level up refills HP and
  /// SP, except that a knocked-out member stays at 0 HP.
  List<int> gainExp(int amount) {
    final reached = <int>[];
    if (level >= Progression.levelCap) return reached;
    exp += amount;
    while (level < Progression.levelCap && exp >= expToNext) {
      exp -= expToNext;
      level++;
      reached.add(level);
    }
    if (level >= Progression.levelCap) exp = 0;
    if (reached.isNotEmpty) {
      if (!isKnockedOut) hp = maxHp;
      sp = maxSp;
    }
    hp = min(hp, maxHp);
    sp = min(sp, maxSp);
    return reached;
  }

  void restore() {
    hp = maxHp;
    sp = maxSp;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'level': level,
        'exp': exp,
        'hp': hp,
        'sp': sp,
        'equipment': {for (final e in equipment.entries) e.key.name: e.value},
      };
}
