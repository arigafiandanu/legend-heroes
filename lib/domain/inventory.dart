import 'dart:math';

class Inventory {
  Inventory([Map<String, int>? items]) : _items = {...?items};

  factory Inventory.fromJson(Map<String, dynamic> json) =>
      Inventory(json.map((k, v) => MapEntry(k, v as int)));

  static const maxStack = 99;
  final Map<String, int> _items;

  Map<String, int> get items => Map.unmodifiable(_items);
  int count(String id) => _items[id] ?? 0;

  void add(String id, [int n = 1]) => _items[id] = min(maxStack, count(id) + n);

  bool remove(String id, [int n = 1]) {
    final have = count(id);
    if (have < n) return false;
    if (have == n) {
      _items.remove(id);
    } else {
      _items[id] = have - n;
    }
    return true;
  }

  Map<String, dynamic> toJson() => Map.of(_items);
}
