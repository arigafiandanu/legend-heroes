import 'package:ashen_crest/domain/party_member.dart';
import 'package:ashen_crest/domain/progression.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/defs.dart';


void main() {
  group('Progression.expToNext', () {
    test('follows 20 × L^1.8 from the spec', () {
      expect(Progression.expToNext(1), 20);
      expect(Progression.expToNext(10), 1262); // spec: ≈ 1.260
    });

    test('is zero at the chapter level cap', () {
      expect(Progression.expToNext(Progression.levelCap), 0);
    });
  });

  group('PartyMember', () {
    test('starts at full HP/SP for its level', () {
      final m = PartyMember(def: kaelDef, level: 2);
      expect(m.hp, 235);
      expect(m.sp, m.maxSp);
    });

    test('gaining EXP levels up and carries the remainder', () {
      final m = PartyMember(def: kaelDef);
      final gained = m.gainExp(20 + 70 + 5); // Lv1→2 needs 20, Lv2→3 needs 70
      expect(gained, [2, 3]);
      expect(m.level, 3);
      expect(m.exp, 5);
    });

    test('level up refills HP and SP', () {
      final m = PartyMember(def: kaelDef)
        ..hp = 100
        ..sp = 3;
      m.gainExp(20);
      expect(m.hp, m.maxHp);
      expect(m.sp, m.maxSp);
    });

    test('EXP without a level up leaves HP and SP alone', () {
      final m = PartyMember(def: kaelDef)
        ..hp = 100
        ..sp = 3;
      m.gainExp(19);
      expect([m.hp, m.sp], [100, 3]);
    });

    test('knocked-out members stay at 0 HP after a level up', () {
      final m = PartyMember(def: kaelDef)..hp = 0;
      m.gainExp(20);
      expect(m.hp, 0);
    });

    test('stops levelling at the cap', () {
      final m = PartyMember(def: kaelDef, level: Progression.levelCap);
      expect(m.gainExp(99999), isEmpty);
      expect(m.level, Progression.levelCap);
    });

    test('restore() refills HP and SP', () {
      final m = PartyMember(def: kaelDef)
        ..hp = 1
        ..sp = 0;
      m.restore();
      expect(m.hp, m.maxHp);
      expect(m.sp, m.maxSp);
    });

    test('round-trips through JSON', () {
      final m = PartyMember(def: kaelDef, level: 4, exp: 12)
        ..hp = 99
        ..sp = 7;
      final copy = PartyMember.fromJson(m.toJson(), kaelDef);
      expect([copy.level, copy.exp, copy.hp, copy.sp], [4, 12, 99, 7]);
    });
  });
}
