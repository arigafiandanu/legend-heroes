import 'dart:io';

import 'package:ashen_crest/data/game_data.dart';
import 'package:ashen_crest/domain/attack_type.dart';
import 'package:ashen_crest/domain/stats.dart';
import 'package:flutter_test/flutter_test.dart';

GameData loadFromDisk() => GameData.fromJsonStrings(
      characters: File('assets/data/characters.json').readAsStringSync(),
      skills: File('assets/data/skills.json').readAsStringSync(),
      enemies: File('assets/data/enemies.json').readAsStringSync(),
    );

void main() {
  late GameData data;
  setUpAll(() => data = loadFromDisk());

  group('Stats.atLevel', () {
    const base = Stats(hp: 220, sp: 40, atk: 34, def: 28, eatk: 18, edef: 18, spd: 24);

    test('level 1 is the base', () {
      final s = base.atLevel(1, hpGrowth: 0.07, statGrowth: 0.05);
      expect(s.hp, 220);
      expect(s.atk, 34);
    });

    test('grows HP by ~7% and other stats by ~5% per level', () {
      final s = base.atLevel(2, hpGrowth: 0.07, statGrowth: 0.05);
      expect(s.hp, 235); // 220 · 1.07
      expect(s.atk, 36); // 34 · 1.05
      expect(s.spd, 25); // 24 · 1.05
    });
  });

  group('characters.json', () {
    test('Kael and Lira level 1 stats match the spec', () {
      final kael = data.characters['kael']!.base;
      expect([kael.hp, kael.sp, kael.atk, kael.def, kael.eatk, kael.edef, kael.spd],
          [220, 40, 34, 28, 18, 18, 24]);
      final lira = data.characters['lira']!.base;
      expect([lira.hp, lira.sp, lira.atk, lira.def, lira.eatk, lira.edef, lira.spd],
          [170, 70, 22, 20, 32, 30, 28]);
    });

    test('Seren (guest) stats match the spec and she only carries a dagger', () {
      final seren = data.characters['seren']!;
      final b = seren.base;
      expect([b.hp, b.sp, b.atk, b.def, b.eatk, b.edef, b.spd], [190, 55, 30, 22, 26, 24, 34]);
      expect(seren.weapons, [AttackType.dagger]);
    });

    test('party units carry the character weapons, first is the default', () {
      final lira = data.partyUnit('lira', level: 1);
      expect(lira.weapons, [AttackType.staff, AttackType.dagger]);
      expect(lira.hp, 170);
      expect(lira.isParty, isTrue);
    });
  });

  group('skills.json', () {
    test('skills unlock by level', () {
      expect(data.skillsFor('kael', 1).map((s) => s.id), ['ember_slash']);
      expect(data.skillsFor('kael', 6).map((s) => s.id),
          ['ember_slash', 'cross_thrust', 'thunder_edge']);
      expect(data.skillsFor('lira', 1).map((s) => s.id), ['heal', 'frost_needle']);
    });

    test("Seren's damage skills unlock by level (debuffs arrive with M4)", () {
      expect(data.skillsFor('seren', 1).map((s) => s.id), ['shadow_stab']);
      expect(data.skillsFor('seren', 10).map((s) => s.id),
          ['shadow_stab', 'gale_cut', 'rime_flurry']);
      final stab = data.skills['shadow_stab']!;
      expect(stab.hits, 2);
      expect(stab.power, 0.7);
    });

    test('Ember Slash is sword + fire, 8 SP, power 1.5', () {
      final s = data.skills['ember_slash']!;
      expect(s.types, [AttackType.sword, AttackType.fire]);
      expect(s.spCost, 8);
      expect(s.power, 1.5);
      expect(s.isPhysical, isTrue);
    });
  });

  group('enemies.json', () {
    test('has every chapter 1 enemy with spec HP, shield and weaknesses', () {
      expect(data.enemies, hasLength(10));
      final rat = data.enemies['ashen_rat']!;
      expect(rat.stats.hp, 90);
      expect(rat.shield, 2);
      expect(rat.weaknesses, {AttackType.dagger, AttackType.fire});

      final warden = data.enemies['cinder_warden']!;
      expect(warden.stats.hp, 4500);
      expect(warden.shield, 8);
      expect(warden.isBoss, isTrue);
    });

    test('enemy units get unique ids for duplicates', () {
      final a = data.enemyUnit('ashen_rat', index: 0);
      final b = data.enemyUnit('ashen_rat', index: 1);
      expect(a.id, isNot(b.id));
      expect(a.name, 'Ashen Rat');
    });
  });
}
