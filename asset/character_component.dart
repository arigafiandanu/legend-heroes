import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/painting.dart';

/// Layout sprite sheet (192x192, frame 32x48):
/// baris: 0=down, 1=left, 2=right, 3=up
/// kolom: 0-1 = idle, 2-5 = walk
enum Facing { down, left, right, up }
enum CharState { idleDown, idleLeft, idleRight, idleUp, walkDown, walkLeft, walkRight, walkUp }

class RpgCharacter extends SpriteAnimationGroupComponent<CharState>
    with HasGameReference {
  RpgCharacter({required this.sheetPath, super.position})
      : super(size: Vector2(32, 48) * 3, anchor: Anchor.bottomCenter);

  final String sheetPath; // 'kael_sheet.png' / 'lira_sheet.png'
  Facing facing = Facing.down;
  static final _frame = Vector2(32, 48);

  @override
  Future<void> onLoad() async {
    final image = await game.images.load(sheetPath);
    final sheet = SpriteSheet(image: image, srcSize: _frame);

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
    current = CharState.idleDown;

    // Wajib untuk pixel art: jangan di-blur saat di-scale
    paint.filterQuality = FilterQuality.none;
  }

  /// Panggil tiap update dengan arah input (Vector2.zero() = diam)
  void move(Vector2 dir, double dt, {double speed = 120}) {
    if (dir.isZero()) {
      current = CharState.values[facing.index]; // idle*
      return;
    }
    if (dir.x.abs() > dir.y.abs()) {
      facing = dir.x < 0 ? Facing.left : Facing.right;
    } else {
      facing = dir.y < 0 ? Facing.up : Facing.down;
    }
    current = CharState.values[4 + facing.index]; // walk*
    position += dir.normalized() * speed * dt;
  }
}
