import 'package:ashen_crest/domain/attack_type.dart';
import 'package:ashen_crest/domain/battle/battle_unit.dart';
import 'package:ashen_crest/domain/skill.dart';
import 'package:ashen_crest/domain/stats.dart';

Stats stats({
  int hp = 200,
  int sp = 50,
  int atk = 30,
  int def = 20,
  int eatk = 30,
  int edef = 20,
  int spd = 20,
}) =>
    Stats(hp: hp, sp: sp, atk: atk, def: def, eatk: eatk, edef: edef, spd: spd);

BattleUnit hero(
  String id, {
  Stats? s,
  List<AttackType> weapons = const [AttackType.sword],
  List<Skill> skills = const [],
}) =>
    BattleUnit.party(
      id: id,
      name: id,
      stats: s ?? stats(),
      weapons: weapons,
      skills: skills,
    );

BattleUnit foe(
  String id, {
  Stats? s,
  int shield = 2,
  Set<AttackType> weak = const {},
  bool boss = false,
  int exp = 10,
  int keping = 5,
}) =>
    BattleUnit.enemy(
      id: id,
      name: id,
      stats: s ?? stats(),
      shield: shield,
      weaknesses: weak,
      isBoss: boss,
      exp: exp,
      keping: keping,
    );
