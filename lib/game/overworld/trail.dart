import 'package:flame/components.dart';

/// Recent path of a moving leader, so a follower can walk the same route a
/// fixed distance behind.
class Trail {
  Trail({this.maxDistance = 200});

  final double maxDistance;
  final List<Vector2> _points = [];

  int get length => _points.length;

  void push(Vector2 p) {
    if (_points.isNotEmpty && _points.last == p) return;
    _points.add(p.clone());
    while (_points.length > 2 &&
        _distanceFromHead(1) > maxDistance) {
      _points.removeAt(0);
    }
  }

  /// Point [distance] px back along the path from the newest point.
  Vector2 pointBehind(double distance) {
    var remaining = distance;
    for (var i = _points.length - 1; i > 0; i--) {
      final a = _points[i];
      final b = _points[i - 1];
      final seg = a.distanceTo(b);
      if (remaining <= seg) {
        return a + (b - a) * (remaining / seg);
      }
      remaining -= seg;
    }
    return _points.first.clone();
  }

  /// Path length from the newest point back to the point at [index].
  double _distanceFromHead(int index) {
    var d = 0.0;
    for (var i = _points.length - 1; i > index; i--) {
      d += _points[i].distanceTo(_points[i - 1]);
    }
    return d;
  }
}
