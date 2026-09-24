import 'attack_type.dart';

enum SkillTarget { singleEnemy, allEnemies, randomEnemies, singleAlly }

enum SkillEffect { damage, heal }

class Skill {
  const Skill({
    required this.id,
    required this.names,
    required this.spCost,
    required this.types,
    required this.target,
    required this.effect,
    required this.power,
    this.hits = 1,
    this.owner = '',
    this.learnLevel = 1,
  });

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
        id: json['id'] as String,
        names: Map<String, String>.from(json['name'] as Map),
        spCost: json['sp'] as int,
        types: [
          for (final t in json['types'] as List? ?? const [])
            AttackType.values.byName(t as String),
        ],
        target: SkillTarget.values.byName(json['target'] as String),
        effect: SkillEffect.values.byName(json['effect'] as String),
        power: (json['power'] as num).toDouble(),
        hits: json['hits'] as int? ?? 1,
        owner: json['owner'] as String? ?? '',
        learnLevel: json['learnLevel'] as int? ?? 1,
      );

  final String id;
  final Map<String, String> names;
  final int spCost;
  final List<AttackType> types;
  final SkillTarget target;
  final SkillEffect effect;

  /// Power per hit (P in the damage formula; heal scale for heals).
  final double power;

  /// Hits per target, or total random hits for [SkillTarget.randomEnemies].
  final int hits;
  final String owner;
  final int learnLevel;

  /// Skills that carry a weapon type hit with ATK/DEF; pure elements use
  /// EATK/EDEF (e.g. Ember Slash = sword + fire is physical).
  bool get isPhysical => types.any((t) => t.isWeapon);

  String name(String languageCode) => names[languageCode] ?? names['en'] ?? id;
}
