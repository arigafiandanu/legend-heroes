import 'attack_type.dart';
import 'stats.dart';

class EnemyDef {
  const EnemyDef({
    required this.id,
    required this.name,
    required this.stats,
    required this.shield,
    required this.weaknesses,
    required this.attackType,
    required this.exp,
    required this.keping,
    required this.color,
    this.isBoss = false,
    this.sprite,
  });

  factory EnemyDef.fromJson(Map<String, dynamic> json) => EnemyDef(
        id: json['id'] as String,
        name: json['name'] as String,
        stats: Stats.fromJson(json['stats'] as Map<String, dynamic>),
        shield: json['shield'] as int,
        weaknesses: {
          for (final t in json['weaknesses'] as List) AttackType.values.byName(t as String),
        },
        attackType: AttackType.values.byName(json['attackType'] as String),
        exp: json['exp'] as int,
        keping: json['keping'] as int,
        color: int.parse((json['color'] as String).substring(1), radix: 16) | 0xFF000000,
        isBoss: json['boss'] as bool? ?? false,
        sprite: json['sprite'] as String?,
      );

  final String id;
  final String name;
  final Stats stats;
  final int shield;
  final Set<AttackType> weaknesses;
  final AttackType attackType;
  final int exp;
  final int keping;

  /// ARGB placeholder color, used while an enemy has no battle sprite.
  final int color;
  final bool isBoss;

  /// Battle sheet under assets/images/ without extension (`<sprite>.png` +
  /// `<sprite>.json`), or null to draw the placeholder.
  final String? sprite;
}
