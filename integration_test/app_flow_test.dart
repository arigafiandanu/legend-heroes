import 'dart:io';

import 'package:ashen_crest/domain/battle/battle_engine.dart';
import 'package:ashen_crest/game/ashen_crest_game.dart';
import 'package:ashen_crest/game/character_sprite.dart';
import 'package:ashen_crest/main.dart' as app;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

/// Lets the real game loop run for [ms] while pumping frames.
Future<void> run(WidgetTester tester, int ms) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await Future<void>.delayed(const Duration(milliseconds: 16));
    await tester.pump();
  }
}

Future<void> until(WidgetTester tester, bool Function() done, {int timeoutMs = 20000, String? what}) async {
  final end = DateTime.now().add(Duration(milliseconds: timeoutMs));
  while (!done()) {
    if (DateTime.now().isAfter(end)) fail('timed out waiting for ${what ?? 'condition'}');
    await run(tester, 50);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('new game, talk, loot, save, walk out, battle, hidden chest, then load back', (tester) async {
    final docs = await getApplicationDocumentsDirectory();
    final saves = Directory('${docs.path}/saves');
    if (saves.existsSync()) saves.deleteSync(recursive: true);

    app.main();
    await until(tester, () => find.text('New Game').evaluate().isNotEmpty, what: 'title');
    final game = tester.widget<GameWidget<AshenCrestGame>>(find.byType(GameWidget<AshenCrestGame>)).game!;
    await run(tester, 800); // screenshot: title

    // --- New game in Hollowmere
    await tester.tap(find.text('New Game'));
    await until(tester, () => game.map?.isLoaded == true && !game.isBusy, what: 'map');
    expect(game.map!.mapId, 'hollowmere');
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;

    Future<void> place(double x, double y, Facing facing) async {
      game.map!.player
        ..position.setValues(x, y)
        ..facing = facing;
      await run(tester, 150);
    }

    Future<void> readDialog({int? choose}) async {
      await until(tester, () => game.dialog.state.active, what: 'dialog');
      while (game.dialog.state.active) {
        if (game.dialog.state.choices.isNotEmpty && choose != null) {
          await run(tester, 400);
          await tester.tap(find.text(game.dialog.state.choices[choose]));
          choose = null;
        } else if (game.dialog.state.choices.isEmpty) {
          await tester.tapAt(Offset(screen.width / 2, screen.height * 0.8));
        }
        await run(tester, 120);
        if (game.overlays.isActive(Overlays.saveSlots)) return;
      }
    }

    // Try the east gate before talking to the Elder: the guard stops us.
    await place(620, 208, Facing.right);
    final gesture = await tester.startGesture(Offset(screen.width * 0.2, screen.height * 0.6));
    await gesture.moveBy(const Offset(60, 0));
    await run(tester, 800);
    await gesture.up();
    await until(tester, () => game.dialog.state.active, what: 'guard');
    expect(game.dialog.state.text, contains('Elder'));
    await readDialog();
    expect(game.map!.mapId, 'hollowmere');

    // Talk to the Elder (starts the quest, gives 3 Herbal).
    await place(296, 156, Facing.up);
    await run(tester, 600); // screenshot: village
    await tester.tap(find.text('Action'));
    await readDialog();
    expect(game.state!.flags, contains('quest_started'));
    expect(game.state!.inventory.count('herbal'), 5);

    // Open the chest by Kael's house.
    await place(56, 314, Facing.up);
    await tester.tap(find.text('Action'));
    await run(tester, 300);
    expect(game.state!.inventory.count('herbal'), 7);
    expect(game.state!.openedChests, contains('hollowmere/chest_1'));

    // Rest and save at the campfire into slot 1.
    game.state!.party.first.hp = 50;
    await place(320, 234, Facing.up);
    await tester.tap(find.text('Action'));
    await readDialog(choose: 0);
    await until(tester, () => game.overlays.isActive(Overlays.saveSlots), what: 'save slots');
    await run(tester, 500); // screenshot: save slots
    await tester.tap(find.text('Slot 1'));
    await until(tester, () => !game.dialog.state.active && !game.isBusy, what: 'save done');
    expect(game.state!.party.first.hp, game.state!.party.first.maxHp);
    expect(await game.saves.summary(1), isNotNull);

    // Walk out through the east gate into Whisperwood (autosave).
    await place(620, 208, Facing.right);
    final g2 = await tester.startGesture(Offset(screen.width * 0.2, screen.height * 0.6));
    await g2.moveBy(const Offset(60, 0));
    await until(tester, () => game.map?.mapId == 'whisperwood_1' && !game.isBusy, what: 'whisperwood');
    await g2.up();
    expect(await game.saves.summary(0), isNotNull);
    await run(tester, 600); // screenshot: forest + danger indicator

    // Pace along the path until an encounter starts.
    final expBefore = game.state!.party.first.exp;
    var dir = 1.0;
    while (game.battle == null) {
      await place(dir > 0 ? 24 : 150, 222, dir > 0 ? Facing.right : Facing.left);
      final g = await tester.startGesture(Offset(screen.width * 0.2, screen.height * 0.6));
      await g.moveBy(Offset(60 * dir, 0));
      await until(tester, () => game.battle != null || (dir > 0 ? game.map!.player.position.x > 140 : game.map!.player.position.x < 30),
          what: 'walking');
      await g.up();
      dir = -dir;
    }

    // Fight: boosted attacks until the battle ends.
    final cubit = game.battle!;
    await until(tester, () => !cubit.state.busy || cubit.state.outcome != null, what: 'battle start');
    while (cubit.state.outcome == null) {
      for (var i = 0; i < cubit.maxBoost; i++) {
        await tester.tap(find.byIcon(Icons.add));
        await run(tester, 60);
      }
      await tester.tap(find.text('Attack'));
      await run(tester, 100);
      if (find.text('Sword').evaluate().isNotEmpty) await tester.tap(find.text('Sword'));
      if (find.text('Staff').evaluate().isNotEmpty) await tester.tap(find.text('Staff'));
      await run(tester, 100);
      await tester.tap(find.text(cubit.targets.first.name).first);
      await until(tester, () => cubit.state.outcome != null || !cubit.state.busy, what: 'turn');
    }
    await run(tester, 800); // screenshot: result
    expect(cubit.state.outcome!.phase, BattlePhase.victory);
    await tester.tap(find.text('Continue'));
    await until(tester, () => game.battle == null && !game.isBusy, what: 'back to map');
    await run(tester, 400); // let the map overlays rebuild
    final kael = game.state!.party.first;
    expect(kael.level > 1 || kael.exp > expBefore, isTrue, reason: 'EXP was awarded');

    // East into the second Whisperwood map; Lira's [Ask] makes the hunter
    // reveal a hidden chest.
    await place(740, 200, Facing.right);
    final g3 = await tester.startGesture(Offset(screen.width * 0.2, screen.height * 0.6));
    await g3.moveBy(const Offset(60, 0));
    await until(tester, () => game.map?.mapId == 'whisperwood_2' && !game.isBusy, what: 'whisperwood_2');
    await g3.up();
    await run(tester, 600); // screenshot: deeper forest
    await place(484, 232, Facing.right);
    await tester.tap(find.text('Action'));
    await readDialog(choose: 0);
    expect(game.state!.flags, contains('ww_secret'));
    final feathers = game.state!.inventory.count('bulu_bara');
    await place(248, 78, Facing.up);
    await tester.tap(find.text('Action'));
    await run(tester, 300);
    expect(game.state!.openedChests, contains('whisperwood_2/chest_secret'));
    expect(game.state!.inventory.count('bulu_bara'), feathers + 2);

    // Field menu shows items.
    await tester.tap(find.text('Menu'));
    await run(tester, 300);
    await tester.tap(find.text('Items'));
    await run(tester, 500); // screenshot: menu
    expect(find.text('Herbal'), findsOneWidget);

    // Quit to title, then load slot 1 (the campfire save).
    await tester.tap(find.text('Quit to Title'));
    await until(tester, () => find.text('Load').evaluate().isNotEmpty, what: 'title again');
    await run(tester, 300);
    await tester.tap(find.text('Load'));
    await run(tester, 500);
    await tester.tap(find.text('Slot 1'));
    await until(tester, () => game.map?.isLoaded == true && !game.isBusy, what: 'loaded');
    expect(game.map!.mapId, 'hollowmere');
    expect(game.state!.flags, contains('quest_started'));
    expect(game.state!.inventory.count('herbal'), 7);
    expect(game.state!.openedChests, contains('hollowmere/chest_1'));
    expect(game.map!.player.position.distanceTo(Vector2(320, 234)), lessThan(2));
    await run(tester, 600); // screenshot: loaded

    // Stop music so audioplayers' position ticker doesn't outlive the test.
    await game.bgm.stop();
    await run(tester, 300);
  });
}
