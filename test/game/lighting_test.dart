import 'dart:io';
import 'dart:ui';

import 'package:ashen_crest/game/overworld/lighting.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses #RRGGBB map colours as opaque', () {
    expect(parseHexColor('#B8CCC8'), const Color(0xFFB8CCC8));
    expect(parseHexColor(null), isNull);
  });

  test('a shaft leans right as it falls (sun from the top-left)', () {
    final bounds = const LightShaft(Rect.fromLTWH(0, 0, 20, 100)).path.getBounds();
    expect(bounds.left, 0);
    expect(bounds.right, 20 + 45);
    expect(bounds.bottom, 100);
  });

  test('Whisperwood is dimmed and has canopy light; Hollowmere stays in daylight', () {
    TiledMap map(String id) => TileMapParser.parseTmx(File('assets/maps/$id.tmx').readAsStringSync());
    List<TiledObject> lights(TiledMap m) =>
        m.layers.whereType<ObjectGroup>().firstWhere((g) => g.name == 'lights').objects;
    final forest = map('whisperwood_1');
    expect(parseHexColor(forest.properties.getValue<String>('ambient')), isNotNull);
    expect(lights(forest).where((o) => o.name == 'shaft'), isNotEmpty);
    final village = map('hollowmere');
    expect(village.properties.getValue<String>('ambient'), isNull);
    expect(lights(village), isEmpty);
  });
}
