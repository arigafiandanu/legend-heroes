import 'package:flame/extensions.dart';

import '../../core/constants.dart';
import '../../domain/collision.dart';
import '../../presentation/controls/input_state.dart';
import '../character_sprite.dart';

/// The party leader on the map: free (non-grid) movement from [InputState],
/// blocked by [solids]. `position` is the feet point (anchor bottomCenter).
class Player extends CharacterSprite {
  Player({
    required super.sheetPath,
    required this.input,
    required this.solids,
    required this.canMove,
    super.position,
    super.facing,
  });

  final InputState input;
  final List<Rect> Function() solids;
  final bool Function() canMove;

  /// Distance walked during the last update (drives encounters).
  double movedLastFrame = 0;

  static const feetWidth = 12.0;
  static const feetHeight = 6.0;

  Rect get feetBox =>
      Rect.fromLTWH(position.x - feetWidth / 2, position.y - feetHeight, feetWidth, feetHeight);

  /// Point just in front of the player, used to pick what to interact with.
  Vector2 get probe => position +
      switch (facing) {
        Facing.down => Vector2(0, 10),
        Facing.up => Vector2(0, -12),
        Facing.left => Vector2(-12, -3),
        Facing.right => Vector2(12, -3),
      };

  @override
  void update(double dt) {
    super.update(dt);
    movedLastFrame = 0;
    final dir = canMove() ? input.direction : Vector2.zero();
    final running = input.running;
    animateTowards(dir, stepTime: running ? 0.09 : 0.14);
    priority = position.y.toInt(); // y-sort, also while standing still
    if (dir.isZero()) return;

    final speed = running ? Movement.runSpeed : Movement.walkSpeed;
    final step = (dir.length > 1 ? dir.normalized() : dir) * speed * dt;
    final allowed = resolveMove(feetBox, step.toOffset(), solids());
    position.add(allowed.toVector2());
    movedLastFrame = allowed.distance;
  }
}
