import 'package:ashen_crest/domain/inventory.dart';
import 'package:ashen_crest/domain/item.dart';
import 'package:flutter_test/flutter_test.dart';

class _Target implements Vitals {
  _Target({required this.hp, required this.sp});
  @override
  int hp;
  @override
  int sp;
  @override
  int get maxHp => 200;
  @override
  int get maxSp => 50;
}

const herbal = ItemDef(id: 'herbal', names: {'en': 'Herbal'}, kind: ItemKind.consumable, effect: ItemEffect.healHp, amount: 100);
const tonic = ItemDef(id: 'tonik', names: {'en': 'Tonic'}, kind: ItemKind.consumable, effect: ItemEffect.healSp, amount: 30);
const feather = ItemDef(id: 'bulu_bara', names: {'en': 'Ember Feather'}, kind: ItemKind.consumable, effect: ItemEffect.revive, amount: 50);

void main() {
  group('Inventory', () {
    test('adds, counts and removes', () {
      final inv = Inventory()..add('herbal', 3);
      expect(inv.count('herbal'), 3);
      expect(inv.remove('herbal', 2), isTrue);
      expect(inv.count('herbal'), 1);
    });

    test('refuses to remove more than it has and drops empty entries', () {
      final inv = Inventory()..add('herbal');
      expect(inv.remove('herbal', 2), isFalse);
      expect(inv.remove('herbal'), isTrue);
      expect(inv.items, isEmpty);
    });

    test('caps stacks at 99', () {
      final inv = Inventory()..add('herbal', 120);
      expect(inv.count('herbal'), 99);
    });

    test('round-trips through JSON', () {
      final inv = Inventory()
        ..add('herbal', 2)
        ..add('tonik');
      expect(Inventory.fromJson(inv.toJson()).items, {'herbal': 2, 'tonik': 1});
    });
  });

  group('ItemDef.use', () {
    test('Herbal heals HP up to max', () {
      final t = _Target(hp: 150, sp: 0);
      final r = herbal.use(t)!;
      expect(t.hp, 200);
      expect(r.hp, 50);
    });

    test('Tonic restores SP', () {
      final t = _Target(hp: 10, sp: 5);
      tonic.use(t);
      expect(t.sp, 35);
    });

    test('healing items do nothing on knocked-out targets', () {
      final t = _Target(hp: 0, sp: 0);
      expect(herbal.canUseOn(t), isFalse);
      expect(herbal.use(t), isNull);
    });

    test('Ember Feather revives only knocked-out targets with 50% HP', () {
      final alive = _Target(hp: 10, sp: 0);
      expect(feather.canUseOn(alive), isFalse);
      final ko = _Target(hp: 0, sp: 0);
      final r = feather.use(ko)!;
      expect(ko.hp, 100);
      expect(r.revived, isTrue);
    });

    test('items with nothing to restore cannot be used', () {
      expect(herbal.canUseOn(_Target(hp: 200, sp: 0)), isFalse);
      expect(tonic.canUseOn(_Target(hp: 1, sp: 50)), isFalse);
    });
  });
}
