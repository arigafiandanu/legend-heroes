import 'dart:ui';

import 'package:ashen_crest/domain/collision.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const wall = Rect.fromLTWH(20, 0, 10, 100);
  const box = Rect.fromLTWH(0, 40, 10, 6);

  test('free movement is unchanged', () {
    expect(resolveMove(box, const Offset(5, 3), [wall]), const Offset(5, 3));
  });

  test('stops flush against a wall on the x axis', () {
    expect(resolveMove(box, const Offset(15, 0), [wall]), const Offset(10, 0));
  });

  test('slides along a wall: blocked x, free y', () {
    expect(resolveMove(box, const Offset(15, 4), [wall]), const Offset(10, 4));
  });

  test('stops flush on the y axis', () {
    const floor = Rect.fromLTWH(0, 50, 100, 10);
    expect(resolveMove(box, const Offset(0, 10), [floor]), const Offset(0, 4));
  });

  test('moving away from a touching wall is allowed', () {
    const touching = Rect.fromLTWH(10, 40, 10, 6);
    expect(resolveMove(box, const Offset(-3, 0), [touching]), const Offset(-3, 0));
  });
}
