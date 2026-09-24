import 'dart:io';

import 'package:ashen_crest/data/save_repository.dart';
import 'package:ashen_crest/domain/game_state.dart';
import 'package:ashen_crest/domain/party_member.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/defs.dart';

void main() {
  late Directory dir;
  late SaveRepository repo;
  final defs = {'kael': kaelDef};

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('saves');
    repo = SaveRepository(dir);
  });
  tearDown(() => dir.delete(recursive: true));

  GameState state({String map = 'hollowmere', int level = 1}) =>
      GameState(party: [PartyMember(def: kaelDef, level: level)], mapId: map, x: 1, y: 2);

  test('saves and loads a slot', () async {
    await repo.save(2, state(map: 'whisperwood_1', level: 4));
    final loaded = await repo.load(2, defs);
    expect(loaded!.mapId, 'whisperwood_1');
    expect(loaded.party.single.level, 4);
  });

  test('empty slots load as null', () async {
    expect(await repo.load(1, defs), isNull);
    expect(await repo.summary(1), isNull);
  });

  test('summary shows map, lead level, play time and save time', () async {
    await repo.save(SaveRepository.autoSlot, state(level: 5)..playSeconds = 125);
    final s = (await repo.summary(SaveRepository.autoSlot))!;
    expect(s.mapId, 'hollowmere');
    expect(s.leadLevel, 5);
    expect(s.playSeconds, 125);
    expect(s.savedAt.difference(DateTime.now()).inMinutes.abs(), lessThan(1));
  });

  test('latestSlot is the most recently written slot', () async {
    expect(await repo.latestSlot(), isNull);
    await repo.save(3, state());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await repo.save(SaveRepository.autoSlot, state());
    expect(await repo.latestSlot(), SaveRepository.autoSlot);
  });

  test('a corrupt file is treated as an empty slot', () async {
    await File('${dir.path}/slot_1.json').writeAsString('{not json');
    expect(await repo.load(1, defs), isNull);
    expect(await repo.summary(1), isNull);
  });

  test('writes atomically (no temp file left behind)', () async {
    await repo.save(1, state());
    expect(dir.listSync().map((e) => e.uri.pathSegments.last), ['slot_1.json']);
  });
}
