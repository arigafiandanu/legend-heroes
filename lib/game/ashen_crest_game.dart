import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../core/l10n/gen/app_localizations.dart';
import '../core/pixel_camera.dart';
import '../data/game_data.dart';
import '../domain/battle/battle_engine.dart';
import '../presentation/battle/battle_cubit.dart';
import '../presentation/controls/input_state.dart';
import 'battle/battle_world.dart';
import 'overworld/overworld_world.dart';

abstract final class Overlays {
  static const controls = 'controls';
  static const battleHud = 'battleHud';
}

class AshenCrestGame extends FlameGame with KeyboardEvents {
  AshenCrestGame({required this.data, required this.input});

  final GameData data;
  final InputState input;

  /// Party level for the M1 test battle so more skills can be tried.
  static const testBattleLevel = 7;
  static const testBattleEnemies = ['ashen_rat', 'wisp_moth', 'blight_sprout'];

  late final OverworldWorld overworld;
  late final RouterComponent router;
  BattleCubit? battle;

  @override
  Color backgroundColor() => const Color(0xFF14121A);

  @override
  Future<void> onLoad() async {
    overworld = OverworldWorld();
    router = RouterComponent(
      initialRoute: 'overworld',
      routes: {'overworld': WorldRoute(() => overworld)},
    );
    await add(router);
    overlays.add(Overlays.controls);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final dpr = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    camera.viewfinder.zoom = pixelZoom(logicalHeight: size.y, devicePixelRatio: dpr);
  }

  void startBattle(List<String> enemyIds, AppLocalizations l10n) {
    if (battle != null) return;
    input.reset();
    final engine = BattleEngine(
      party: [
        data.partyUnit('kael', level: testBattleLevel),
        data.partyUnit('lira', level: testBattleLevel),
      ],
      enemies: [
        for (var i = 0; i < enemyIds.length; i++) data.enemyUnit(enemyIds[i], index: i),
      ],
    );
    final cubit = battle = BattleCubit(engine);
    overlays.remove(Overlays.controls);
    router.pushRoute(
      WorldRoute(() => BattleWorld(cubit: cubit, data: data, l10n: l10n), maintainState: false),
      name: 'battle',
    );
    overlays.add(Overlays.battleHud);
  }

  /// Back to the overworld at the same spot. M1: party HP is not carried
  /// over between battles (persistence arrives with save/load in M2).
  void endBattle() {
    final cubit = battle;
    if (cubit == null) return;
    overlays.remove(Overlays.battleHud);
    router.pop();
    battle = null;
    cubit.close();
    overlays.add(Overlays.controls);
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    bool any(List<LogicalKeyboardKey> keys) => keys.any(keysPressed.contains);
    final x = (any([LogicalKeyboardKey.keyD, LogicalKeyboardKey.arrowRight]) ? 1 : 0) -
        (any([LogicalKeyboardKey.keyA, LogicalKeyboardKey.arrowLeft]) ? 1 : 0);
    final y = (any([LogicalKeyboardKey.keyS, LogicalKeyboardKey.arrowDown]) ? 1 : 0) -
        (any([LogicalKeyboardKey.keyW, LogicalKeyboardKey.arrowUp]) ? 1 : 0);
    input.keyboard.setValues(x.toDouble(), y.toDouble());
    input.runKey = any([LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftRight]);
    return KeyEventResult.handled;
  }
}
