import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'core/l10n/gen/app_localizations.dart';
import 'data/game_data.dart';
import 'game/ashen_crest_game.dart';
import 'presentation/battle/battle_hud.dart';
import 'presentation/controls/controls_overlay.dart';
import 'presentation/controls/input_state.dart';

class AshenCrestApp extends StatelessWidget {
  const AshenCrestApp({super.key, required this.data});

  final GameData data;

  @override
  Widget build(BuildContext context) => MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameScreen(data: data),
      );
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.data});

  final GameData data;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final AshenCrestGame _game = AshenCrestGame(data: widget.data, input: InputState());

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: GameWidget<AshenCrestGame>(
          game: _game,
          overlayBuilderMap: {
            Overlays.controls: (context, game) => ControlsOverlay(game: game),
            Overlays.battleHud: (context, game) => BattleHud(game: game),
          },
        ),
      );
}
