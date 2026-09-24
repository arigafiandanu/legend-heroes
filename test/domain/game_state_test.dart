import 'package:ashen_crest/domain/attack_type.dart';
import 'package:ashen_crest/domain/game_state.dart';
import 'package:ashen_crest/domain/party_member.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/defs.dart';

GameState sample() => GameState(
      party: [PartyMember(def: kaelDef, level: 3, exp: 9)..hp = 120],
      mapId: 'whisperwood_1',
      x: 120.5,
      y: 88,
      facing: 'left',
      keping: 75,
      playSeconds: 3600.5,
    )
      ..inventory.add('herbal', 2)
      ..flags.add('met_elder')
      ..openedChests.add('whisperwood_1/chest_a')
      ..reveal('ashen_rat', AttackType.fire);

void main() {
  test('round-trips everything a save needs', () {
    final copy = GameState.fromJson(sample().toJson(), {'kael': kaelDef});
    expect(copy.mapId, 'whisperwood_1');
    expect([copy.x, copy.y], [120.5, 88]);
    expect(copy.facing, 'left');
    expect(copy.keping, 75);
    expect(copy.playSeconds, 3600.5);
    expect(copy.party.single.level, 3);
    expect(copy.party.single.hp, 120);
    expect(copy.inventory.count('herbal'), 2);
    expect(copy.flags, {'met_elder'});
    expect(copy.openedChests, {'whisperwood_1/chest_a'});
    expect(copy.bestiary['ashen_rat'], {AttackType.fire});
  });

  test('writes the current saveVersion', () {
    expect(sample().toJson()['saveVersion'], GameState.saveVersion);
  });

  test('rejects saves from a newer game version', () {
    final json = sample().toJson()..['saveVersion'] = GameState.saveVersion + 1;
    expect(() => GameState.fromJson(json, {'kael': kaelDef}), throwsFormatException);
  });

  test('rejects files without a saveVersion', () {
    final json = sample().toJson()..remove('saveVersion');
    expect(() => GameState.fromJson(json, {'kael': kaelDef}), throwsFormatException);
  });
}
