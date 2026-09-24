import 'package:ashen_crest/game/overworld/trail.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pointBehind walks back along the recorded path', () {
    final t = Trail()
      ..push(Vector2(0, 0))
      ..push(Vector2(10, 0))
      ..push(Vector2(10, 20));
    expect(t.pointBehind(5), Vector2(10, 15));
    expect(t.pointBehind(25), Vector2(5, 0));
  });

  test('clamps to the oldest point when the path is shorter', () {
    final t = Trail()
      ..push(Vector2(0, 0))
      ..push(Vector2(4, 0));
    expect(t.pointBehind(100), Vector2(0, 0));
  });

  test('ignores pushes that do not move', () {
    final t = Trail()
      ..push(Vector2(1, 1))
      ..push(Vector2(1, 1));
    expect(t.length, 1);
  });

  test('drops points beyond maxDistance', () {
    final t = Trail(maxDistance: 10);
    for (var x = 0; x <= 100; x += 5) {
      t.push(Vector2(x.toDouble(), 0));
    }
    expect(t.pointBehind(50), Vector2(85, 0));
  });
}
