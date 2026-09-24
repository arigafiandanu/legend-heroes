import 'dart:math';

class Stats {
  const Stats({
    required this.hp,
    required this.sp,
    required this.atk,
    required this.def,
    required this.eatk,
    required this.edef,
    required this.spd,
  });

  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
        hp: json['hp'] as int,
        sp: json['sp'] as int? ?? 0,
        atk: json['atk'] as int,
        def: json['def'] as int,
        eatk: json['eatk'] as int,
        edef: json['edef'] as int,
        spd: json['spd'] as int,
      );

  final int hp;
  final int sp;
  final int atk;
  final int def;
  final int eatk;
  final int edef;
  final int spd;

  /// Stats at [level], compounding [hpGrowth] for HP and [statGrowth] for
  /// everything else per level above 1.
  Stats atLevel(int level, {required double hpGrowth, required double statGrowth}) {
    int grow(int base, double rate) => (base * pow(1 + rate, level - 1)).round();
    return Stats(
      hp: grow(hp, hpGrowth),
      sp: grow(sp, statGrowth),
      atk: grow(atk, statGrowth),
      def: grow(def, statGrowth),
      eatk: grow(eatk, statGrowth),
      edef: grow(edef, statGrowth),
      spd: grow(spd, statGrowth),
    );
  }
}
