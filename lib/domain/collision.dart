import 'dart:ui';

/// Moves [box] by [delta] against [solids], one axis at a time so the
/// mover slides along walls. Returns the allowed movement.
Offset resolveMove(Rect box, Offset delta, List<Rect> solids) {
  var dx = delta.dx;
  if (dx != 0) {
    for (final s in solids) {
      if (box.bottom <= s.top || box.top >= s.bottom) continue;
      if (dx > 0 && s.left >= box.right) {
        dx = dx < s.left - box.right ? dx : s.left - box.right;
      } else if (dx < 0 && s.right <= box.left) {
        dx = dx > s.right - box.left ? dx : s.right - box.left;
      }
    }
  }
  final moved = box.shift(Offset(dx, 0));
  var dy = delta.dy;
  if (dy != 0) {
    for (final s in solids) {
      if (moved.right <= s.left || moved.left >= s.right) continue;
      if (dy > 0 && s.top >= moved.bottom) {
        dy = dy < s.top - moved.bottom ? dy : s.top - moved.bottom;
      } else if (dy < 0 && s.bottom <= moved.top) {
        dy = dy > s.bottom - moved.top ? dy : s.bottom - moved.top;
      }
    }
  }
  return Offset(dx, dy);
}
