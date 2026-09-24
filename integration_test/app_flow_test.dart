import 'package:ashen_crest/domain/battle/battle_engine.dart';
import 'package:ashen_crest/game/ashen_crest_game.dart';
import 'package:ashen_crest/main.dart' as app;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Lets the real game loop run for [ms] while pumping frames.
Future<void> run(WidgetTester tester, int ms) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await Future<void>.delayed(const Duration(milliseconds: 16));
    await tester.pump();
  }
}

Future<void> until(WidgetTester tester, bool Function() done, {int timeoutMs = 20000}) async {
  final end = DateTime.now().add(Duration(milliseconds: timeoutMs));
  while (!done()) {
    if (DateTime.now().isAfter(end)) fail('timed out');
    await run(tester, 50);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('walk with the joystick, win the test battle, return to the same spot', (tester) async {
    app.main();
    await until(tester, () => find.byType(GameWidget<AshenCrestGame>).evaluate().isNotEmpty);
    final game = tester.widget<GameWidget<AshenCrestGame>>(find.byType(GameWidget<AshenCrestGame>)).game!;
    await until(tester, () => find.text('Test Battle').evaluate().isNotEmpty);
    await run(tester, 1500); // screenshot: overworld idle

    // Drag the floating joystick right on the left half of the screen.
    final player = game.overworld.player;
    final startX = player.position.x;
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    final gesture = await tester.startGesture(Offset(size.width * 0.2, size.height * 0.6));
    for (var i = 1; i <= 10; i++) {
      await gesture.moveBy(const Offset(6, 0));
      await run(tester, 16);
    }
    await run(tester, 1200); // screenshot: walking right, joystick visible
    await gesture.up();
    await run(tester, 200);
    expect(player.position.x, greaterThan(startX + 60), reason: 'Kael walks right');
    final spot = player.position.clone();

    // Enter the test battle.
    await tester.tap(find.text('Test Battle'));
    await until(tester, () => game.battle != null && !game.battle!.state.busy);
    final cubit = game.battle!;
    expect(cubit.engine.enemies, hasLength(3));
    var sawBreak = false;

    while (cubit.state.outcome == null) {
      final actor = cubit.actor!;
      for (var i = 0; i < cubit.maxBoost; i++) {
        await tester.tap(find.byIcon(Icons.add));
        await run(tester, 60);
      }
      await tester.tap(find.text('Attack'));
      await run(tester, 100);

      // Kael: sword vs Blight Sprout (weak), Lira: dagger vs Ashen Rat (weak).
      final plan = actor.id == 'kael' ? ('Sword', 'Blight Sprout') : ('Dagger', 'Ashen Rat');
      await tester.tap(find.text(plan.$1));
      await run(tester, 100);
      final preferred = find.text(plan.$2);
      final target = preferred.evaluate().isNotEmpty
          ? preferred
          : find.text(cubit.targets.first.name);
      await tester.tap(target);
      await until(tester, () {
        sawBreak |= cubit.engine.enemies.any((e) => e.isBroken);
        return cubit.state.outcome != null || !cubit.state.busy;
      });
    }

    await run(tester, 1500); // screenshot: result card
    expect(cubit.state.outcome!.phase, BattlePhase.victory);
    expect(sawBreak, isTrue, reason: 'weakness hits break at least one enemy');

    await tester.tap(find.text('Continue'));
    await run(tester, 800);
    expect(game.battle, isNull);
    expect(game.overworld.player.position, spot);
    expect(find.text('Test Battle'), findsOneWidget);

    // A second battle must work too; flee until it succeeds (60% per try).
    await tester.tap(find.text('Test Battle'));
    await until(tester, () => game.battle != null && !game.battle!.state.busy);
    final second = game.battle!;
    expect(second, isNot(same(cubit)));
    while (second.state.outcome == null) {
      await tester.tap(find.text('Flee'));
      await until(tester, () => second.state.outcome != null || !second.state.busy);
    }
    expect(second.state.outcome!.phase, anyOf(BattlePhase.escaped, BattlePhase.defeat));
    await run(tester, 600);
    await tester.tap(find.text('Continue'));
    await run(tester, 800);
    expect(game.battle, isNull);
    expect(game.overworld.player.position, spot);
  });
}
