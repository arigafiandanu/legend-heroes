
import 'package:flame/extensions.dart';

import '../../core/constants.dart';
import '../../presentation/controls/input_state.dart';
import '../character_sprite.dart';

/// Kael on the overworld: free (non-grid) movement from [InputState].
class Player extends CharacterSprite {
  Player({required super.sheetPath, required this.input, required this.bounds, super.position});

  final InputState input;

  /// Walkable area for the player's feet.
  final Rect bounds;

  bool get isMoving => !input.direction.isZero();

  @override
  void update(double dt) {
    super.update(dt);
    final dir = input.direction;
    final running = input.running;
    animateTowards(dir, stepTime: running ? 0.09 : 0.14);
    priority = position.y.toInt(); // y-sort, also while standing still
    if (dir.isZero()) return;

    final speed = running ? Movement.runSpeed : Movement.walkSpeed;
    final step = dir.length > 1 ? dir.normalized() : dir;
    position
      ..add(step * speed * dt)
      ..clamp(bounds.topLeft.toVector2(), bounds.bottomRight.toVector2());
  }
}
