import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

/// Empty test map until Tiled maps land in M2: a 16 px grass grid with a
/// dirt path and a few scattered stones, pre-rendered once to a picture.
class PlaceholderGround extends PositionComponent {
  PlaceholderGround({required Vector2 size}) : super(size: size, priority: -100000);

  static const _tile = 16.0;
  late final Picture _picture;

  @override
  Future<void> onLoad() async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final grassA = Paint()..color = const Color(0xFF5E8C4A);
    final grassB = Paint()..color = const Color(0xFF58844A);
    final dirt = Paint()..color = const Color(0xFFB08A5A);
    final stone = Paint()..color = const Color(0xFF7D7F86);
    final tuft = Paint()..color = const Color(0xFF4B7340);
    final rng = Random(7);

    final cols = (size.x / _tile).ceil();
    final rows = (size.y / _tile).ceil();
    final pathRow = rows ~/ 2;
    final pathCol = cols ~/ 2;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final rect = Rect.fromLTWH(x * _tile, y * _tile, _tile, _tile);
        final onPath = (y - pathRow).abs() <= 1 || (x - pathCol).abs() <= 1;
        canvas.drawRect(rect, onPath ? dirt : ((x + y).isEven ? grassA : grassB));
        if (!onPath && rng.nextDouble() < 0.12) {
          canvas.drawRect(Rect.fromLTWH(rect.left + 5, rect.top + 7, 2, 4), tuft);
          canvas.drawRect(Rect.fromLTWH(rect.left + 8, rect.top + 6, 2, 5), tuft);
        }
        if (!onPath && rng.nextDouble() < 0.015) {
          canvas.drawRect(Rect.fromLTWH(rect.left + 3, rect.top + 6, 10, 6), stone);
        }
      }
    }
    _picture = recorder.endRecording();
  }

  @override
  void render(Canvas canvas) => canvas.drawPicture(_picture);
}
