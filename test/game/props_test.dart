import 'dart:io';
import 'dart:ui';

import 'package:ashen_crest/game/overworld/props.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, PropFrame> frames(String area) =>
      PropFrame.parseAll(File('assets/data/props_$area.json').readAsStringSync());

  test('frames parse with a collision box at the base', () {
    final tree = frames('whisperwood')['big_tree']!;
    expect(tree.src.size, const Size(48, 64));
    expect(tree.solid.bottom, 0); // box sits on the base point
    expect(tree.glow, isNull);
  });

  test('light-giving props carry a glow', () {
    final lantern = frames('hollowmere')['lantern']!.glow!;
    expect(lantern.dy, lessThan(0)); // above the base, at the lamp
    expect(lantern.radius, greaterThan(0));
    expect(frames('whisperwood')['ashblight']!.glow, isNotNull);
  });

  for (final id in ['hollowmere', 'whisperwood_1', 'whisperwood_2']) {
    group(id, () {
      final map = TileMapParser.parseTmx(File('assets/maps/$id.tmx').readAsStringSync());
      final area = map.properties.getValue<String>('props')!;
      final sheet = frames(area);
      List<TiledObject> layer(String name) =>
          map.layers.whereType<ObjectGroup>().firstWhere((g) => g.name == name).objects;
      final props = layer('props');
      Rect solid(TiledObject o) => sheet[o.name]!.solid.shift(Offset(o.x, o.y));

      test('every prop on the map is a known kind', () {
        expect(props, isNotEmpty);
        for (final o in props) {
          expect(sheet.containsKey(o.name), isTrue, reason: o.name);
        }
      });

      test('no prop blocks a chest, sign, NPC, exit or spawn', () {
        for (final o in layer('objects')) {
          final area = Rect.fromLTWH(o.x, o.y, o.width, o.height).inflate(8);
          for (final p in props) {
            if (o.type == 'sign' && p.name == 'signpost') continue; // the post is the sign itself
            if (o.type == 'examine' && p.name == 'shrine') continue; // likewise the shrine
            expect(solid(p).overlaps(area), isFalse, reason: '${p.name} at ${p.x},${p.y} blocks ${o.name}');
          }
        }
      });

      if (id == 'whisperwood_1') {
        test('the path from the west entrance is clear', () {
          const walk = Rect.fromLTRB(0, 210, 170, 236); // where the app flow test paces for encounters
          for (final p in props) {
            expect(solid(p).overlaps(walk), isFalse, reason: '${p.name} at ${p.x},${p.y}');
          }
        });
      }
    });
  }
}
