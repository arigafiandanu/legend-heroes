import 'dart:math';

/// Anything with HP/SP that items can act on (party members, battle units).
abstract interface class Vitals {
  int get hp;
  set hp(int value);
  int get sp;
  set sp(int value);
  int get maxHp;
  int get maxSp;
}

enum ItemKind { consumable, key, weapon, armor, accessory }

enum ItemEffect { none, healHp, healSp, revive, cure }

class ItemResult {
  const ItemResult({this.hp = 0, this.sp = 0, this.revived = false});
  final int hp;
  final int sp;
  final bool revived;
}

class ItemDef {
  const ItemDef({
    required this.id,
    required this.names,
    required this.kind,
    this.effect = ItemEffect.none,
    this.amount = 0,
    this.price = 0,
    this.descriptions = const {},
  });

  factory ItemDef.fromJson(Map<String, dynamic> json) => ItemDef(
        id: json['id'] as String,
        names: Map<String, String>.from(json['name'] as Map),
        descriptions: Map<String, String>.from(json['description'] as Map? ?? const {}),
        kind: ItemKind.values.byName(json['kind'] as String),
        effect: ItemEffect.values.byName(json['effect'] as String? ?? 'none'),
        amount: json['amount'] as int? ?? 0,
        price: json['price'] as int? ?? 0,
      );

  final String id;
  final Map<String, String> names;
  final Map<String, String> descriptions;
  final ItemKind kind;
  final ItemEffect effect;

  /// HP/SP restored, or % of max HP for [ItemEffect.revive].
  final int amount;
  final int price;

  String name(String languageCode) => names[languageCode] ?? names['en'] ?? id;
  String description(String languageCode) =>
      descriptions[languageCode] ?? descriptions['en'] ?? '';

  bool get isConsumable => kind == ItemKind.consumable;

  bool canUseOn(Vitals t) => switch (effect) {
        ItemEffect.healHp => t.hp > 0 && t.hp < t.maxHp,
        ItemEffect.healSp => t.hp > 0 && t.sp < t.maxSp,
        ItemEffect.revive => t.hp <= 0,
        // Status effects arrive in M4; until then there is nothing to cure.
        ItemEffect.cure || ItemEffect.none => false,
      };

  /// Applies the item; null when it would have no effect.
  ItemResult? use(Vitals t) {
    if (!canUseOn(t)) return null;
    switch (effect) {
      case ItemEffect.healHp:
        final before = t.hp;
        t.hp = min(t.maxHp, t.hp + amount);
        return ItemResult(hp: t.hp - before);
      case ItemEffect.healSp:
        final before = t.sp;
        t.sp = min(t.maxSp, t.sp + amount);
        return ItemResult(sp: t.sp - before);
      case ItemEffect.revive:
        t.hp = max(1, (t.maxHp * amount / 100).round());
        return ItemResult(hp: t.hp, revived: true);
      case ItemEffect.cure || ItemEffect.none:
        return null;
    }
  }
}
