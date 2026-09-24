import 'package:ashen_crest/domain/attack_type.dart';
import 'package:ashen_crest/domain/character_def.dart';
import 'package:ashen_crest/domain/stats.dart';

const kaelDef = CharacterDef(
  id: 'kael',
  name: 'Kael',
  sheet: 'kael_sheet.png',
  base: Stats(hp: 220, sp: 40, atk: 34, def: 28, eatk: 18, edef: 18, spd: 24),
  hpGrowth: 0.07,
  statGrowth: 0.05,
  weapons: [AttackType.sword, AttackType.spear],
  elements: [AttackType.fire, AttackType.lightning],
);
