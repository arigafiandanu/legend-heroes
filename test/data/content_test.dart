import 'dart:io';

import 'package:ashen_crest/data/dialog_project.dart';
import 'package:ashen_crest/data/game_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame_tiled/flame_tiled.dart';

class _Host implements DialogHost {
  @override
  bool hasFlag(String flag) => false;
  @override
  void setFlag(String flag) {}
  @override
  void giveItem(String id, int count) {}
  @override
  void restParty() {}
  @override
  Future<void> openSaveMenu() async {}
}

String read(String path) => File(path).readAsStringSync();

GameData data() => GameData.fromJsonStrings(
      characters: read('assets/data/characters.json'),
      skills: read('assets/data/skills.json'),
      enemies: read('assets/data/enemies.json'),
      items: read('assets/data/items.json'),
      encounters: read('assets/data/encounters.json'),
    );

TiledMap map(String id) => TileMapParser.parseTmx(read('assets/maps/$id.tmx'));

Iterable<TiledObject> objects(TiledMap m) => m.layers
    .whereType<ObjectGroup>()
    .where((g) => g.name == 'objects')
    .expand((g) => g.objects);

void main() {
  final gameData = data();
  final projects = {
    for (final lang in DialogFiles.languages)
      lang: buildYarnProject([for (final f in DialogFiles.files) read('assets/dialog/$lang/$f')], _Host()),
  };

  test('every dialog file parses in both languages with the same nodes', () {
    expect(projects['id']!.nodes.keys.toSet(), projects['en']!.nodes.keys.toSet());
  });

  for (final id in GameData.mapIds) {
    group('map $id', () {
      final m = map(id);

      test('dialog nodes referenced by objects exist', () {
        for (final o in objects(m)) {
          for (final key in ['dialog', 'blockedDialog']) {
            final node = o.properties.getValue<String>(key);
            if (node == null) continue;
            for (final lang in projects.keys) {
              expect(projects[lang]!.nodes.containsKey(node), isTrue, reason: '$id/${o.name} → $lang:$node');
            }
          }
        }
      });

      test('hidden chests open with a flag some dialog sets', () {
        final setFlags = {
          for (final lang in ['id', 'en'])
            for (final f in DialogFiles.files)
              for (final m in RegExp(r'<<flag (\w+)>>').allMatches(read('assets/dialog/$lang/$f'))) m.group(1)!,
        };
        for (final o in objects(m).where((o) => o.type == 'chest')) {
          final flag = o.properties.getValue<String>('requiresFlag');
          if (flag != null) expect(setFlags, contains(flag), reason: '${o.name} needs $flag');
        }
      });

      test('chests hold known items', () {
        for (final o in objects(m).where((o) => o.type == 'chest')) {
          expect(gameData.items.containsKey(o.properties.getValue<String>('item')), isTrue, reason: o.name);
          expect(o.properties.getValue<int>('count'), greaterThan(0), reason: '${o.name}: count must be an int property');
        }
      });

      test('exits lead to existing maps and spawn points', () {
        for (final o in objects(m).where((o) => o.type == 'exit')) {
          final target = o.properties.getValue<String>('map');
          if (target == null) continue; // closed path
          final spawns = objects(map(target)).where((s) => s.type == 'spawn').map((s) => s.name);
          expect(spawns, contains(o.properties.getValue<String>('spawn')), reason: '${o.name} → $target');
        }
      });

      test('encounter table and music exist', () {
        final table = m.properties.getValue<String>('encounters');
        if (table != null) expect(gameData.encounters.containsKey(table), isTrue);
        final bgm = m.properties.getValue<String>('bgm')!;
        expect(File('assets/audio/bgm/$bgm.ogg').existsSync(), isTrue);
      });
    });
  }

  test('enemy battle sheets exist for enemies that name one', () {
    for (final e in gameData.enemies.values.where((e) => e.sprite != null)) {
      for (final ext in ['png', 'json']) {
        expect(File('assets/images/${e.sprite}.$ext').existsSync(), isTrue, reason: '${e.id}.$ext');
      }
    }
    expect(gameData.enemies.values.where((e) => e.sprite != null).length, 4, reason: 'the Whisperwood four');
  });

  test('party battle sheets exist for Kael and Lira', () {
    for (final id in ['kael', 'lira']) {
      final sprite = gameData.characters[id]!.battleSprite;
      expect(sprite, isNotNull, reason: id);
      for (final ext in ['png', 'json']) {
        expect(File('assets/images/$sprite.$ext').existsSync(), isTrue, reason: '$id.$ext');
      }
    }
  });

  test('map backdrops and the chest sprite exist', () {
    expect(File('assets/images/props/chest.png').existsSync(), isTrue);
    for (final id in GameData.mapIds) {
      final bg = map(id).properties.getValue<String>('backdrop');
      if (bg != null) expect(File('assets/images/backdrops/$bg.png').existsSync(), isTrue, reason: '$id → $bg');
    }
    expect(map('whisperwood_1').properties.getValue<String>('backdrop'), 'whisperwood');
  });

  test('map tilesets point at existing images', () {
    for (final id in GameData.mapIds) {
      for (final ts in map(id).tilesets) {
        expect(File('assets/maps/${ts.image!.source}').existsSync(), isTrue, reason: '$id → ${ts.image!.source}');
      }
    }
  });

  test('encounter groups only use known enemies', () {
    for (final table in gameData.encounters.values) {
      for (final g in table.groups) {
        for (final e in g.enemies) {
          expect(gameData.enemies.containsKey(e), isTrue, reason: e);
        }
      }
    }
  });

  test('a new game starts on an existing spawn', () {
    final s = gameData.newGame();
    final spawns = objects(map(s.mapId)).where((o) => o.type == 'spawn').map((o) => o.name);
    expect(spawns, contains(s.spawn));
    expect(s.party.map((m) => m.id), ['kael', 'lira']);
  });
}
