import 'dart:io';
import 'dart:ui';

import 'package:ashen_crest/game/overworld/props.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final frames = PropFrame.parseAll(File('assets/data/props_whisperwood.json').readAsStringSync());
  final map = TileMapParser.parseTmx(File('assets/maps/whisperwood_1.tmx').readAsStringSync());
  List<TiledObject> group(String name) =>
      map.layers.whereType<ObjectGroup>().firstWhere((g) => g.name == name).objects;
  final props = group('props');
  Rect solid(TiledObject o) => frames[o.name]!.solid.shift(Offset(o.x, o.y));

  test('frames parse with a collision box at the base', () {
    final tree = frames['big_tree']!;
    expect(tree.src.size, const Size(48, 64));
    expect(tree.solid.bottom, 0); // box sits on the base point
  });

  test('every prop on the map is a known kind', () {
    expect(props, isNotEmpty);
    expect(map.properties.getValue<String>('props'), 'whisperwood');
    for (final o in props) {
      expect(frames.containsKey(o.name), isTrue, reason: o.name);
    }
  });

  test('no prop blocks a chest, sign, exit or spawn', () {
    for (final o in group('objects')) {
      final area = Rect.fromLTWH(o.x, o.y, o.width, o.height).inflate(8);
      for (final p in props) {
        if (o.type == 'sign' && p.name == 'signpost') continue; // the post is the sign itself
        expect(solid(p).overlaps(area), isFalse, reason: '${p.name} at ${p.x},${p.y} blocks ${o.name}');
      }
    }
  });

  test('the path from the west entrance is clear', () {
    const walk = Rect.fromLTRB(0, 210, 170, 236); // where the app flow test paces for encounters
    for (final p in props) {
      expect(solid(p).overlaps(walk), isFalse, reason: '${p.name} at ${p.x},${p.y}');
    }
  });
}
