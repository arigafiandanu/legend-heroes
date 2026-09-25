import 'dart:io';

import 'package:ashen_crest/game/battle/battle_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final meta = BattleSheetMeta.parse(File('assets/images/enemies/ashen_rat_battle.json').readAsStringSync());

  test('sheet lists idle, attack, hit and ko with matching frame data', () {
    expect(meta.size, 48);
    expect(meta.anims.keys, containsAll(['idle', 'attack', 'hit', 'ko']));
    for (final clip in meta.anims.values) {
      expect(clip.offsets.length, clip.frames);
    }
    expect(meta.anims['idle']!.loop, isTrue);
  });

  test('frameAt walks through frame durations and wraps only when looping', () {
    final attack = meta.anims['attack']!; // 110, 60, 140, 80, 90
    expect(attack.frameAt(0), 0);
    expect(attack.frameAt(109), 0);
    expect(attack.frameAt(110), 1);
    expect(attack.frameAt(200), 2);
    expect(attack.frameAt(10000), 4);
    final idle = meta.anims['idle']!;
    expect(idle.frameAt(idle.totalMs + 10.0), 0);
  });

  test('the blow lands on the contact frame', () {
    final attack = meta.anims['attack']!;
    expect(attack.contact, 2);
    expect(attack.msUntil(attack.contact!), 170);
  });

  test('one-shot clips return to idle; ko holds its last frame', () {
    final p = AnimPlayback(meta)..play('hit');
    p.update(meta.anims['hit']!.totalMs + 1.0);
    expect(p.name, 'idle');
    p
      ..play('ko')
      ..update(5000);
    expect(p.name, 'ko');
    expect(p.frame, meta.anims['ko']!.frames - 1);
  });

  test('the attack lunges toward the party and comes back', () {
    final p = AnimPlayback(meta)..play('attack');
    p.update(200);
    expect(p.offset.dx, greaterThan(0));
    p.play('nope'); // unknown clips are ignored
    expect(p.name, 'attack');
  });
}
