import 'package:flame_tiled/flame_tiled.dart';

/// Which tile layers draw below characters and which above (foreground).
/// Values are indices into `map.layers`, which is what
/// `RenderableTiledMap.setLayerVisibility` expects (not the Tiled layer id).
({List<int> below, List<int> above}) splitLayers(TiledMap map) {
  final below = <int>[], above = <int>[];
  for (var i = 0; i < map.layers.length; i++) {
    final layer = map.layers[i];
    if (layer is! TileLayer) continue;
    (layer.name == 'foreground' ? above : below).add(i);
  }
  return (below: below, above: above);
}
