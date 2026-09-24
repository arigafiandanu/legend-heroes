import 'dart:io';

import 'package:ashen_crest/game/overworld/map_layers.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('splits tile layers by index: ground+decor below, foreground above', () {
    final map = TileMapParser.parseTmx(File('assets/maps/hollowmere.tmx').readAsStringSync());
    final split = splitLayers(map);
    expect(split.below, [0, 1]); // indices into map.layers, not Tiled ids (1, 2)
    expect(split.above, [2]);
  });
}
