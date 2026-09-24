import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/attack_type.dart';
import '../domain/battle/battle_unit.dart';
import '../domain/character_def.dart';
import '../domain/encounter.dart';
import '../domain/enemy_def.dart';
import '../domain/game_state.dart';
import '../domain/item.dart';
import '../domain/party_member.dart';
import '../domain/skill.dart';

/// Static game content loaded from assets/data/*.json.
class GameData {
  GameData({
    required this.characters,
    required this.skills,
    required this.enemies,
    this.items = const {},
    this.encounters = const {},
  });

  /// Maps shipped in assets/maps/ (Tiled .tmx).
  static const mapIds = ['hollowmere', 'whisperwood_1'];

  factory GameData.fromJsonStrings({
    required String characters,
    required String skills,
    required String enemies,
    String items = '[]',
    String encounters = '{}',
  }) {
    Iterable<Map<String, dynamic>> rows(String src) =>
        (jsonDecode(src) as List).cast<Map<String, dynamic>>();
    return GameData(
      characters: {
        for (final r in rows(characters)) r['id'] as String: CharacterDef.fromJson(r),
      },
      skills: {for (final r in rows(skills)) r['id'] as String: Skill.fromJson(r)},
      enemies: {for (final r in rows(enemies)) r['id'] as String: EnemyDef.fromJson(r)},
      items: {for (final r in rows(items)) r['id'] as String: ItemDef.fromJson(r)},
      encounters: {
        for (final e in (jsonDecode(encounters) as Map<String, dynamic>).entries)
          e.key: EncounterTable.fromJson(e.value as Map<String, dynamic>),
      },
    );
  }

  static Future<GameData> load(AssetBundle bundle) async => GameData.fromJsonStrings(
        characters: await bundle.loadString('assets/data/characters.json'),
        skills: await bundle.loadString('assets/data/skills.json'),
        enemies: await bundle.loadString('assets/data/enemies.json'),
        items: await bundle.loadString('assets/data/items.json'),
        encounters: await bundle.loadString('assets/data/encounters.json'),
      );

  final Map<String, CharacterDef> characters;
  final Map<String, Skill> skills;
  final Map<String, EnemyDef> enemies;
  final Map<String, ItemDef> items;
  final Map<String, EncounterTable> encounters;

  /// Chapter 1 start: Kael and Lira at level 1 in front of Kael's house.
  GameState newGame() => GameState(
        party: [PartyMember(def: characters['kael']!), PartyMember(def: characters['lira']!)],
        mapId: 'hollowmere',
        spawn: 'start',
        facing: 'down',
        keping: 50,
      )..inventory.add('herbal', 2);

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
  BattleUnit enemyUnit(String enemyId, {required int index, Set<AttackType> revealed = const {}}) {
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
      revealed: revealed,
    );
  }

  /// Battle unit for a persistent party member (current HP/SP, learned skills).
  BattleUnit memberUnit(PartyMember m) => BattleUnit.party(
        id: m.id,
        name: m.def.name,
        stats: m.stats,
        weapons: m.def.weapons,
        skills: skillsFor(m.id, m.level),
        hp: m.hp,
        sp: m.sp,
      );
}
