import 'dart:async';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:jenny/jenny.dart';

import '../core/bgm.dart';
import '../core/l10n/gen/app_localizations.dart';
import '../core/pixel_camera.dart';
import '../data/dialog_project.dart';
import '../data/game_data.dart';
import '../data/save_repository.dart';
import '../domain/battle/battle_engine.dart';
import '../domain/encounter.dart';
import '../domain/game_state.dart';
import '../presentation/battle/battle_cubit.dart';
import '../presentation/battle/battle_state.dart';
import '../presentation/controls/input_state.dart';
import '../presentation/dialog/dialog_cubit.dart';
import '../presentation/dialog/game_dialog_view.dart';
import 'battle/battle_world.dart';
import 'character_sprite.dart';
import 'overworld/map_objects.dart';
import 'overworld/map_world.dart';
import 'title_world.dart';

abstract final class Overlays {
  static const title = 'title';
  static const controls = 'controls';
  static const hud = 'hud';
  static const dialog = 'dialog';
  static const menu = 'menu';
  static const saveSlots = 'saveSlots';
  static const battleHud = 'battleHud';
  static const gameOver = 'gameOver';
  static const fade = 'fade';
}

enum SlotMode { save, load }

class AshenCrestGame extends FlameGame with KeyboardEvents implements DialogHost {
  AshenCrestGame({
    required this.data,
    required this.input,
    required this.saves,
    Bgm? bgm,
    this.bundle,
  }) : bgm = bgm ?? Bgm();

  final GameData data;
  final InputState input;
  final SaveRepository saves;
  final Bgm bgm;
  final AssetBundle? bundle;

  /// Set by the Flutter layer once localizations are available.
  late AppLocalizations l10n;

  // UI state shared with overlays.
  final dialog = DialogCubit();
  final danger = ValueNotifier<Danger?>(null);
  final toast = ValueNotifier<String?>(null);
  final fade = ValueNotifier<double>(0);
  SlotMode slotMode = SlotMode.save;
  Timer? _toastTimer;
  Completer<void>? _slotPicker;

  GameState? state;
  MapWorld? map;
  BattleCubit? battle;
  late final RouterComponent router;
  DialogueRunner? _runner;
  String? _yarnLanguage;
  bool _transitioning = false;

  /// True while something other than free walking has the player's input.
  bool get isBusy =>
      _transitioning ||
      dialog.state.active ||
      battle != null ||
      overlays.isActive(Overlays.menu) ||
      overlays.isActive(Overlays.saveSlots) ||
      overlays.isActive(Overlays.gameOver);

  @override
  Color backgroundColor() => const Color(0xFF14121A);

  @override
  Future<void> onLoad() async {
    await bgm.init();
    input.onAction = () => map?.interact();
    router = RouterComponent(
      initialRoute: 'title',
      routes: {'title': WorldRoute(TitleWorld.new)},
    );
    await add(router);
    overlays.addAll([Overlays.title, Overlays.fade]);
    await bgm.play('main_theme');
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final dpr = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    camera.viewfinder.zoom = pixelZoom(logicalHeight: size.y, devicePixelRatio: dpr);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final s = state;
    if (s != null && !overlays.isActive(Overlays.title)) s.playSeconds += dt;
  }

  // ---------------------------------------------------------------- flow

  Future<void> newGame() async {
    state = data.newGame();
    await _enterFromTitle();
  }

  /// Loads [slot]; false when the slot is empty or unreadable.
  Future<bool> loadSlot(int slot) async {
    final loaded = await saves.load(slot, data.characters);
    if (loaded == null) return false;
    state = loaded;
    await _enterFromTitle();
    return true;
  }

  Future<void> _enterFromTitle() async {
    overlays.removeAll([Overlays.title, Overlays.gameOver, Overlays.menu, Overlays.saveSlots]);
    final s = state!;
    await enterMap(
      s.mapId,
      spawn: s.x == null ? s.spawn : null,
      position: s.x == null ? null : Vector2(s.x!, s.y!),
      facing: Facing.values.byName(s.facing),
      autosave: false,
    );
    overlays.addAll([Overlays.controls, Overlays.hud, Overlays.dialog]);
  }

  Future<void> enterMap(
    String mapId, {
    String? spawn,
    Vector2? position,
    Facing? facing,
    bool autosave = true,
  }) async {
    if (_transitioning) return;
    _transitioning = true;
    input.reset();
    await _fadeTo(1);
    final world = MapWorld(
      mapId: mapId,
      spawn: spawn,
      startPosition: position,
      startFacing: facing ?? map?.player.facing ?? Facing.down,
    );
    router.pushReplacement(WorldRoute(() => world, maintainState: false), name: 'map');
    await world.loaded;
    map = world;
    danger.value = world.meter == null ? null : Danger.low;
    state!
      ..mapId = mapId
      ..spawn = null;
    _syncPosition();
    unawaited(bgm.play(world.bgm));
    if (autosave) await saves.save(SaveRepository.autoSlot, state!);
    await _fadeTo(0);
    _transitioning = false;
  }

  Future<void> _fadeTo(double target, {int ms = 220}) async {
    final start = fade.value;
    const steps = 10;
    for (var i = 1; i <= steps; i++) {
      fade.value = start + (target - start) * i / steps;
      await Future<void>.delayed(Duration(milliseconds: ms ~/ steps));
    }
  }

  /// Copies the live player position into [state] (before saving).
  void _syncPosition() {
    final m = map;
    final s = state;
    if (m == null || s == null || !m.isLoaded) return;
    s
      ..x = m.player.position.x
      ..y = m.player.position.y
      ..facing = m.player.facing.name;
  }

  Future<void> quitToTitle() async {
    await _fadeTo(1);
    overlays.removeAll([
      Overlays.controls, Overlays.hud, Overlays.dialog, Overlays.menu,
      Overlays.saveSlots, Overlays.gameOver, Overlays.battleHud,
    ]);
    battle?.close();
    battle = null;
    map = null;
    state = null;
    danger.value = null;
    router.pushReplacement(WorldRoute(TitleWorld.new, maintainState: false), name: 'title');
    overlays.add(Overlays.title);
    unawaited(bgm.play('main_theme'));
    await _fadeTo(0);
  }

  // -------------------------------------------------------------- dialog

  Future<void> runDialog(String node) async {
    if (dialog.state.active) return;
    input.reset();
    final language = l10n.localeName;
    if (_runner == null || _yarnLanguage != language) {
      final sources = await DialogFiles.load(bundle ?? rootBundle, language);
      _runner = DialogueRunner(
        yarnProject: buildYarnProject(sources, this),
        dialogueViews: [GameDialogView(dialog)],
      );
      _yarnLanguage = language;
    }
    await _runner!.startDialogue(node);
  }

  @override
  bool hasFlag(String flag) => state?.flags.contains(flag) ?? false;

  @override
  void setFlag(String flag) => state?.flags.add(flag);

  @override
  void giveItem(String id, int count) {
    state?.inventory.add(id, count);
    showToast(l10n.foundItem(data.items[id]?.name(l10n.localeName) ?? id, count));
  }

  @override
  void restParty() {
    for (final m in state?.party ?? const []) {
      m.restore();
    }
  }

  @override
  Future<void> openSaveMenu() => openSlots(SlotMode.save);

  // ------------------------------------------------------------ overlays

  Future<void> openSlots(SlotMode mode) {
    slotMode = mode;
    _slotPicker = Completer<void>();
    overlays.add(Overlays.saveSlots);
    return _slotPicker!.future;
  }

  void closeSlots() {
    overlays.remove(Overlays.saveSlots);
    _slotPicker?.complete();
    _slotPicker = null;
  }

  Future<void> saveToSlot(int slot) async {
    _syncPosition();
    await saves.save(slot, state!);
    showToast(l10n.saved);
  }

  void openMenu() {
    if (isBusy || state == null) return;
    input.reset();
    overlays.add(Overlays.menu);
  }

  void closeMenu() => overlays.remove(Overlays.menu);

  void showToast(String text) {
    toast.value = text;
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 2200), () => toast.value = null);
  }

  Future<void> openChest(Chest chest, String key, String itemId, int count) async {
    if (chest.opened) {
      showToast(l10n.chestEmpty);
      return;
    }
    chest.opened = true;
    state!.openedChests.add(key);
    giveItem(itemId, count);
  }

  // -------------------------------------------------------------- battle

  void startBattle(List<String> enemyIds) {
    final s = state;
    if (battle != null || s == null) return;
    input.reset();
    final engine = BattleEngine(
      party: [for (final m in s.party) data.memberUnit(m)],
      enemies: [
        for (var i = 0; i < enemyIds.length; i++)
          data.enemyUnit(enemyIds[i], index: i, revealed: s.bestiary[enemyIds[i]] ?? const {}),
      ],
      inventory: s.inventory,
      items: data.items,
    );
    final cubit = battle = BattleCubit(engine, onOutcome: _applyOutcome);
    overlays.removeAll([Overlays.controls, Overlays.hud]);
    router.pushRoute(
      WorldRoute(() => BattleWorld(cubit: cubit, data: data, l10n: l10n), maintainState: false),
      name: 'battle',
    );
    overlays.add(Overlays.battleHud);
    unawaited(bgm.play(engine.enemies.any((e) => e.isBoss) ? 'boss' : 'battle'));
  }

  /// Writes the battle back into the persistent state; returns level-up lines.
  List<String> _applyOutcome(BattleOutcome outcome) {
    final s = state!;
    final engine = battle!.engine;
    for (var i = 0; i < s.party.length; i++) {
      s.party[i]
        ..hp = engine.party[i].hp
        ..sp = engine.party[i].sp;
    }
    for (final e in engine.enemies) {
      final id = e.id.split('#').first;
      for (final t in e.revealed) {
        s.reveal(id, t);
      }
    }
    final notes = <String>[];
    if (outcome.phase == BattlePhase.victory) {
      s.keping += outcome.keping;
      for (final m in s.party.where((m) => !m.isKnockedOut)) {
        for (final level in m.gainExp(outcome.exp)) {
          notes.add(l10n.levelUp(m.def.name, level));
        }
      }
    }
    return notes;
  }

  /// Result screen "Continue": back to the map (or Game Over).
  void endBattle() {
    final cubit = battle;
    if (cubit == null) return;
    final defeated = cubit.state.outcome?.phase == BattlePhase.defeat;
    overlays.remove(Overlays.battleHud);
    router.pop();
    battle = null;
    cubit.close();
    if (defeated) {
      overlays.add(Overlays.gameOver);
      unawaited(bgm.stop());
      return;
    }
    map?.meter?.startSafePeriod(3);
    overlays.addAll([Overlays.controls, Overlays.hud]);
    final m = map;
    if (m != null) unawaited(bgm.play(m.bgm));
  }

  // ------------------------------------------------------------ keyboard

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    bool any(List<LogicalKeyboardKey> keys) => keys.any(keysPressed.contains);
    final x = (any([LogicalKeyboardKey.keyD, LogicalKeyboardKey.arrowRight]) ? 1 : 0) -
        (any([LogicalKeyboardKey.keyA, LogicalKeyboardKey.arrowLeft]) ? 1 : 0);
    final y = (any([LogicalKeyboardKey.keyS, LogicalKeyboardKey.arrowDown]) ? 1 : 0) -
        (any([LogicalKeyboardKey.keyW, LogicalKeyboardKey.arrowUp]) ? 1 : 0);
    input.keyboard.setValues(x.toDouble(), y.toDouble());
    input.runKey = any([LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftRight]);
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.enter) {
        if (dialog.state.active) {
          dialog.advance();
        } else {
          input.onAction?.call();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        overlays.isActive(Overlays.menu) ? closeMenu() : openMenu();
      }
    }
    return KeyEventResult.handled;
  }
}
