import 'package:flame/components.dart';

import '../character_sprite.dart';
import 'player.dart';
import 'trail.dart';

/// Lira walking Kael's path a fixed distance behind.
class Follower extends CharacterSprite {
  Follower({required super.sheetPath, required this.leader, this.spacing = 22})
      : super(position: leader.position.clone());

  final Player leader;
  final double spacing;
  final Trail _trail = Trail();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Start just above Kael so the pair doesn't overlap before moving.
    _trail
      ..push(leader.position - Vector2(0, spacing))
      ..push(leader.position);
    position.setFrom(_trail.pointBehind(spacing));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _trail.push(leader.position);
    final target = _trail.pointBehind(spacing);
    final delta = target - position;
    if (delta.length2 < 0.01) {
      animateTowards(Vector2.zero());
    } else {
      animateTowards(delta, stepTime: leader.input.running ? 0.09 : 0.14);
      position.setFrom(target);
    }
    priority = position.y.toInt();
  }
}
