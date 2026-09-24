import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/battle/battle_unit.dart';
import '../domain/character_def.dart';
import '../domain/enemy_def.dart';
import '../domain/skill.dart';

/// Static game content loaded from assets/data/*.json.
class GameData {
  GameData({
    required this.characters,
    required this.skills,
    required this.enemies,
  });

  factory GameData.fromJsonStrings({
    required String characters,
    required String skills,
    required String enemies,
  }) {
    Iterable<Map<String, dynamic>> rows(String src) =>
        (jsonDecode(src) as List).cast<Map<String, dynamic>>();
    return GameData(
      characters: {
        for (final r in rows(characters)) r['id'] as String: CharacterDef.fromJson(r),
      },
      skills: {for (final r in rows(skills)) r['id'] as String: Skill.fromJson(r)},
      enemies: {for (final r in rows(enemies)) r['id'] as String: EnemyDef.fromJson(r)},
    );
  }

  static Future<GameData> load(AssetBundle bundle) async => GameData.fromJsonStrings(
        characters: await bundle.loadString('assets/data/characters.json'),
        skills: await bundle.loadString('assets/data/skills.json'),
        enemies: await bundle.loadString('assets/data/enemies.json'),
      );

  final Map<String, CharacterDef> characters;
  final Map<String, Skill> skills;
  final Map<String, EnemyDef> enemies;

  List<Skill> skillsFor(String characterId, int level) => [
        for (final s in skills.values)
          if (s.owner == characterId && s.learnLevel <= level) s,
      ];

  BattleUnit partyUnit(String characterId, {required int level}) {
    final def = characters[characterId]!;
    return BattleUnit.party(
      id: def.id,
      name: def.name,
      stats: def.statsAt(level),
      weapons: def.weapons,
      skills: skillsFor(characterId, level),
    );
  }

  /// [index] disambiguates duplicates of the same enemy in one battle.
  BattleUnit enemyUnit(String enemyId, {required int index}) {
    final def = enemies[enemyId]!;
    return BattleUnit.enemy(
      id: '$enemyId#$index',
      name: def.name,
      stats: def.stats,
      shield: def.shield,
      weaknesses: def.weaknesses,
      attackType: def.attackType,
      isBoss: def.isBoss,
      exp: def.exp,
      keping: def.keping,
    );
  }
}
