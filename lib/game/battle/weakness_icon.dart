import 'dart:ui';

import '../../domain/attack_type.dart';

/// 8×8 procedural weakness icons until the UI sprite set exists.
/// Weapons are drawn as silhouettes, elements as colored gems.
void drawWeaknessIcon(Canvas canvas, Offset o, AttackType? type) {
  final bg = Paint()..color = const Color(0xFF221E2B);
  final frame = Paint()
    ..color = const Color(0xFF6B6480)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final box = Rect.fromLTWH(o.dx, o.dy, 9, 9);
  canvas
    ..drawRect(box, bg)
    ..drawRect(box.deflate(0.5), frame);

  final ink = Paint()
    ..color = const Color(0xFFE6E1D6)
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.square;
  Offset p(double x, double y) => Offset(o.dx + x, o.dy + y);

  switch (type) {
    case null: // unknown "?"
      canvas
        ..drawLine(p(3, 2.5), p(6, 2.5), ink)
        ..drawLine(p(6, 2.5), p(6, 4.5), ink)
        ..drawLine(p(6, 4.5), p(4.5, 4.5), ink)
        ..drawLine(p(4.5, 4.5), p(4.5, 5.5), ink)
        ..drawRect(Rect.fromLTWH(o.dx + 4, o.dy + 6.5, 1, 1), ink);
    case AttackType.sword:
      canvas
        ..drawLine(p(2, 7), p(7, 2), ink)
        ..drawLine(p(2.5, 5), p(4, 6.5), ink);
    case AttackType.spear:
      canvas
        ..drawLine(p(4.5, 7.5), p(4.5, 3), ink)
        ..drawLine(p(3, 3.5), p(4.5, 1.5), ink)
        ..drawLine(p(6, 3.5), p(4.5, 1.5), ink);
    case AttackType.staff:
      canvas
        ..drawLine(p(4.5, 7.5), p(4.5, 3.5), ink)
        ..drawCircle(p(4.5, 2.5), 1.5, ink);
    case AttackType.dagger:
      canvas
        ..drawLine(p(3, 6), p(6, 3), ink)
        ..drawLine(p(2, 7), p(3, 6), ink..color = const Color(0xFFB08A5A));
    case AttackType.fire:
      canvas.drawCircle(p(4.5, 4.5), 2.5, Paint()..color = const Color(0xFFE8572E));
    case AttackType.ice:
      canvas.drawCircle(p(4.5, 4.5), 2.5, Paint()..color = const Color(0xFF7FD3F0));
    case AttackType.lightning:
      canvas.drawCircle(p(4.5, 4.5), 2.5, Paint()..color = const Color(0xFFF2D14B));
    case AttackType.wind:
      canvas.drawCircle(p(4.5, 4.5), 2.5, Paint()..color = const Color(0xFF7ED08A));
    case AttackType.light:
      canvas.drawCircle(p(4.5, 4.5), 2.5, Paint()..color = const Color(0xFFFFF6D8));
  }
}
