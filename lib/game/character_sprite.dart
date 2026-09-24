import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

/// Sheet layout (192×192, 32×48 frames):
/// rows 0=down, 1=left, 2=right, 3=up · columns 0–1 idle, 2–5 walk.
enum Facing { down, left, right, up }

enum CharState { idleDown, idleLeft, idleRight, idleUp, walkDown, walkLeft, walkRight, walkUp }

class CharacterSprite extends SpriteAnimationGroupComponent<CharState>
    with HasGameReference {
  CharacterSprite({required this.sheetPath, this.facing = Facing.down, super.position})
      : super(size: frameSize, anchor: Anchor.bottomCenter);

  static final frameSize = Vector2(32, 48);
  static final _shadowPaint = Paint()..color = const Color(0x55000000);

  final String sheetPath;
  Facing facing;

  @override
  Future<void> onLoad() async {
    final sheet = SpriteSheet(image: await game.images.load(sheetPath), srcSize: frameSize);

    SpriteAnimation idle(int row) =>
        sheet.createAnimation(row: row, stepTime: 0.5, from: 0, to: 2);
    SpriteAnimation walk(int row) =>
        sheet.createAnimation(row: row, stepTime: 0.14, from: 2, to: 6);

    animations = {
      CharState.idleDown: idle(0),
      CharState.idleLeft: idle(1),
      CharState.idleRight: idle(2),
      CharState.idleUp: idle(3),
      CharState.walkDown: walk(0),
      CharState.walkLeft: walk(1),
      CharState.walkRight: walk(2),
      CharState.walkUp: walk(3),
    };
    current = CharState.values[facing.index];

    // Pixel art must never be smoothed when scaled.
    paint.filterQuality = FilterQuality.none;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawOval(Rect.fromLTWH(7, size.y - 5, size.x - 14, 6), _shadowPaint);
    super.render(canvas);
  }

  /// Updates facing/animation for movement [dir] (zero = stand still).
  void animateTowards(Vector2 dir, {double stepTime = 0.14}) {
    if (dir.isZero()) {
      current = CharState.values[facing.index];
      return;
    }
    if (dir.x.abs() > dir.y.abs()) {
      facing = dir.x < 0 ? Facing.left : Facing.right;
    } else {
      facing = dir.y < 0 ? Facing.up : Facing.down;
    }
    current = CharState.values[4 + facing.index];
    final anim = animations?[current];
    if (anim != null) {
      for (final f in anim.frames) {
        f.stepTime = stepTime;
      }
    }
  }
}
