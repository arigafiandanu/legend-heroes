import 'dart:math';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';

import '../../domain/encounter.dart';
import '../ashen_crest_game.dart';
import '../character_sprite.dart';
import 'follower.dart';
import 'map_layers.dart';
import 'map_objects.dart';
import 'player.dart';

/// One Tiled map (`assets/maps/<id>.tmx`) with its party, NPCs and objects.
class MapWorld extends World with HasGameReference<AshenCrestGame> {
  MapWorld({required this.mapId, this.spawn, this.startPosition, this.startFacing = Facing.down});

  static const tileSize = 16.0;
  static final _mapImages = Images(prefix: 'assets/maps/');

  final String mapId;
  final String? spawn;
  final Vector2? startPosition;
  final Facing startFacing;

  late final Player player;
  late final Follower follower;
  late final Vector2 mapSize;
  late final String bgm;
  late final String? nameKey;
  EncounterMeter? meter;
  EncounterTable? _table;
  final _random = Random();

  final List<Rect> _walls = [];
  final List<Npc> _npcs = [];
  final List<Chest> _chests = [];
  final List<Campfire> _fires = [];
  final List<Interactable> _interactables = [];
  final List<ExitZone> _exits = [];
  final Map<String, Vector2> spawns = {};

  List<Rect> _solids() => [
        ..._walls,
        for (final n in _npcs) n.solid,
        for (final c in _chests) c.solid,
        for (final f in _fires) f.solid,
      ];

  @override
  Future<void> onLoad() async {
    final ground = await TiledComponent.load('$mapId.tmx', Vector2.all(tileSize),
        prefix: 'assets/maps/', images: _mapImages, priority: -100000);
    final foreground = await TiledComponent.load('$mapId.tmx', Vector2.all(tileSize),
        prefix: 'assets/maps/', images: _mapImages, priority: 100000);
    final map = ground.tileMap.map;
    final split = splitLayers(map);
    for (final i in split.below) {
      foreground.tileMap.setLayerVisibility(i, visible: false);
    }
    for (final i in split.above) {
      ground.tileMap.setLayerVisibility(i, visible: false);
    }
    mapSize = Vector2(map.width * tileSize, map.height * tileSize);
    bgm = map.properties.getValue<String>('bgm') ?? 'hollowmere';
    nameKey = map.properties.getValue<String>('nameKey');
    final table = map.properties.getValue<String>('encounters');
    if (table != null) {
      _table = game.data.encounters[table];
      meter = EncounterMeter(random: _random, minDistance: _table!.minDistance, maxDistance: _table!.maxDistance);
    }

    final collision = map.layerByName('collision') as ObjectGroup;
    _walls.addAll([for (final o in collision.objects) Rect.fromLTWH(o.x, o.y, o.width, o.height)]);
    final objects = map.layerByName('objects') as ObjectGroup;
    for (final o in objects.objects) {
      _addObject(o);
    }

    final start = startPosition ?? spawns[spawn] ?? spawns.values.firstOrNull ?? mapSize / 2;
    final state = game.state!;
    player = Player(
      sheetPath: state.party.first.def.sheet,
      input: game.input,
      solids: _solids,
      canMove: () => !game.isBusy,
      position: start.clone(),
      facing: startFacing,
    );
    follower = Follower(
      sheetPath: state.party.length > 1 ? state.party[1].def.sheet : state.party.first.def.sheet,
      leader: player,
    );
    await addAll([ground, foreground, ..._npcs, ..._chests, ..._fires, follower, player]);
  }

  void _addObject(TiledObject o) {
    String? prop(String name) => o.properties.getValue<String>(name);
    final rect = Rect.fromLTWH(o.x, o.y, o.width, o.height);
    switch (o.type) {
      case 'spawn':
        spawns[o.name] = Vector2(o.x, o.y);
      case 'npc':
        final npc = Npc(
          sheetPath: prop('sheet') ?? 'kael_sheet.png',
          dialogNode: prop('dialog')!,
          onTalk: game.runDialog,
          tint: _parseColor(prop('tint')),
          position: Vector2(o.x, o.y),
          facing: Facing.values.byName(prop('facing') ?? 'down'),
        );
        _npcs.add(npc);
        _interactables.add(npc);
      case 'chest':
        final key = '$mapId/${o.name}';
        final chest = Chest(
          rect: rect,
          opened: game.state!.openedChests.contains(key),
          onOpen: (c) => game.openChest(c, key, prop('item')!, o.properties.getValue<int>('count') ?? 1),
        );
        _chests.add(chest);
        _interactables.add(chest);
      case 'campfire':
        final fire = Campfire(rect: rect, onUse: () => game.runDialog(prop('dialog') ?? 'Campfire'));
        _fires.add(fire);
        _interactables.add(fire);
      case 'sign' || 'examine':
        _interactables.add(Examinable(area: rect.inflate(4), node: prop('dialog')!, onExamine: game.runDialog));
      case 'exit':
        _exits.add(ExitZone(
          area: rect,
          targetMap: prop('map'),
          targetSpawn: prop('spawn'),
          requiresFlag: prop('requiresFlag'),
          blockedDialog: prop('blockedDialog'),
        ));
    }
  }

  static Color _parseColor(String? hex) =>
      hex == null ? const Color(0xFFFFFFFF) : Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000);

  @override
  void onMount() {
    super.onMount();
    game.camera.stop();
    game.camera.setBounds(null);
    _updateCamera();
  }

  /// Action button: talk to / open / inspect what the player faces.
  Future<void> interact() async {
    if (game.isBusy) return;
    final probe = player.probe.toOffset();
    final feet = player.position.toOffset();
    Interactable? best;
    var bestDistance = double.infinity;
    for (final i in _interactables) {
      final inFront = i.area.contains(probe);
      final d = (i.area.center - feet).distance;
      if ((inFront || i.area.inflate(4).contains(feet)) && d < bestDistance) {
        best = i;
        bestDistance = d;
      }
    }
    if (best is Npc) best.face(player.position);
    await best?.interact();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updateCamera();
    if (game.isBusy) return;
    _checkExits();
    final m = meter;
    if (m != null && !game.isBusy) {
      if (m.advance(player.movedLastFrame, dt)) {
        game.startBattle(_table!.pick(_random));
      }
      game.danger.value = m.danger;
    }
  }

  void _checkExits() {
    final feet = player.position.toOffset();
    for (final exit in _exits) {
      final inside = exit.area.contains(feet);
      if (!inside) {
        exit.armed = true;
        continue;
      }
      if (!exit.armed) continue;
      exit.armed = false;
      final open = exit.targetMap != null &&
          (exit.requiresFlag == null || game.state!.flags.contains(exit.requiresFlag));
      if (open) {
        game.enterMap(exit.targetMap!, spawn: exit.targetSpawn);
      } else {
        // Step back out of the exit and explain why.
        final away = (player.position - exit.area.center.toVector2())..y = 0;
        player.position.add(away.normalized() * 10);
        if (exit.blockedDialog != null) game.runDialog(exit.blockedDialog!);
      }
      return;
    }
  }

  /// Follow the player, clamped to the map; centred if the map is smaller.
  void _updateCamera() {
    final view = game.size / game.camera.viewfinder.zoom;
    double axis(double p, double viewLen, double mapLen) =>
        mapLen <= viewLen ? mapLen / 2 : p.clamp(viewLen / 2, mapLen - viewLen / 2);
    game.camera.viewfinder.position = Vector2(
      axis(player.position.x, view.x, mapSize.x),
      axis(player.position.y - 16, view.y, mapSize.y),
    );
  }
}
