import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';

import '../ashen_crest_game.dart';
import 'follower.dart';
import 'placeholder_ground.dart';
import 'player.dart';

/// M0 test field: empty map, Kael + Lira, camera follows Kael.
class OverworldWorld extends World with HasGameReference<AshenCrestGame> {
  static final mapSize = Vector2(960, 540);

  late final Player player;
  late final Follower follower;

  @override
  Future<void> onLoad() async {
    const margin = 12.0;
    player = Player(
      sheetPath: 'kael_sheet.png',
      input: game.input,
      bounds: Rect.fromLTRB(margin, 48, mapSize.x - margin, mapSize.y - 4),
      position: mapSize / 2,
    );
    follower = Follower(sheetPath: 'lira_sheet.png', leader: player);
    await addAll([PlaceholderGround(size: mapSize), follower, player]);
  }

  @override
  void onMount() {
    super.onMount();
    game.camera
      ..follow(player, snap: true)
      ..setBounds(Rectangle.fromLTWH(0, 0, mapSize.x, mapSize.y), considerViewport: true);
  }
}
