import 'dart:math';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../domain/encounter.dart';
import '../ashen_crest_game.dart';
import '../character_sprite.dart';
import 'follower.dart';
import 'lighting.dart';
import 'map_layers.dart';
import 'map_objects.dart';
import 'player.dart';
import 'props.dart';

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

  /// Battle backdrop for fights started here.
  late final String? backdrop;
  EncounterMeter? meter;
  EncounterTable? _table;
  final _random = Random();

  final List<Rect> _walls = [];
  final List<Npc> _npcs = [];
  final List<Chest> _chests = [];
  final List<Campfire> _fires = [];
  final List<Interactable> _interactables = [];
  final List<ExitZone> _exits = [];
  final List<Prop> _props = [];
  final Map<String, Vector2> spawns = {};

  List<Rect> _solids() => [
        ..._walls,
        for (final n in _npcs) n.solid,
        for (final c in _chests)
          if (c.shown) c.solid,
        for (final f in _fires) f.solid,
        for (final p in _props) p.solid,
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
    backdrop = map.properties.getValue<String>('backdrop');
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
    final area = map.properties.getValue<String>('props');
    if (area != null) {
      final sheet = await PropSheet.load(game.images, game.bundle ?? rootBundle, area);
      final layer = map.layers.whereType<ObjectGroup>().where((g) => g.name == 'props').firstOrNull;
      _props.addAll([
        for (final o in layer?.objects ?? const <TiledObject>[]) Prop(sheet: sheet, kind: o.name, base: Vector2(o.x, o.y)),
      ]);
    }

    final lightLayer = map.layers.whereType<ObjectGroup>().where((g) => g.name == 'lights').firstOrNull;
    final lighting = Lighting(
      size: Size(mapSize.x, mapSize.y),
      ambient: parseHexColor(map.properties.getValue<String>('ambient')),
      shafts: [
        for (final o in lightLayer?.objects ?? const <TiledObject>[])
          if (o.name == 'shaft') LightShaft(Rect.fromLTWH(o.x, o.y, o.width, o.height)),
      ],
      glows: [
        for (final (i, p) in _props.indexed)
          if (p.frame.glow case final g?)
            Glow(p.position.toOffset().translate(0, g.dy), radius: g.radius, color: g.color, phase: i * 1.7),
      ],
    );
    final lit = lighting.ambient != null || lighting.shafts.isNotEmpty || lighting.glows.isNotEmpty;

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
    await addAll([ground, foreground, ..._props, ..._npcs, ..._chests, ..._fires, follower, player, if (lit) lighting]);
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
          tint: parseHexColor(prop('tint')) ?? const Color(0xFFFFFFFF),
          position: Vector2(o.x, o.y),
          facing: Facing.values.byName(prop('facing') ?? 'down'),
        );
        _npcs.add(npc);
        _interactables.add(npc);
      case 'chest':
        final key = '$mapId/${o.name}';
        final flag = prop('requiresFlag');
        final chest = Chest(
          rect: rect,
          revealed: flag == null ? null : () => game.hasFlag(flag),
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
      if (i is Chest && !i.shown) continue;
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
