import 'attack_type.dart';
import 'stats.dart';

class CharacterDef {
  const CharacterDef({
    required this.id,
    required this.name,
    required this.sheet,
    required this.base,
    required this.hpGrowth,
    required this.statGrowth,
    required this.weapons,
    required this.elements,
  });

  factory CharacterDef.fromJson(Map<String, dynamic> json) => CharacterDef(
        id: json['id'] as String,
        name: json['name'] as String,
        sheet: json['sheet'] as String,
        base: Stats.fromJson(json['stats'] as Map<String, dynamic>),
        hpGrowth: (json['hpGrowth'] as num).toDouble(),
        statGrowth: (json['statGrowth'] as num).toDouble(),
        weapons: _types(json['weapons']),
        elements: _types(json['elements']),
      );

  final String id;
  final String name;

  /// Overworld sprite sheet under assets/images/.
  final String sheet;
  final Stats base;
  final double hpGrowth;
  final double statGrowth;
  final List<AttackType> weapons;
  final List<AttackType> elements;

  Stats statsAt(int level) =>
      base.atLevel(level, hpGrowth: hpGrowth, statGrowth: statGrowth);
}

List<AttackType> _types(Object? list) => [
      for (final t in list as List? ?? const []) AttackType.values.byName(t as String),
    ];
