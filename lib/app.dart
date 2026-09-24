import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'core/l10n/gen/app_localizations.dart';
import 'data/game_data.dart';
import 'data/save_repository.dart';
import 'game/ashen_crest_game.dart';
import 'presentation/battle/battle_hud.dart';
import 'presentation/controls/controls_overlay.dart';
import 'presentation/controls/input_state.dart';
import 'presentation/dialog/dialog_overlay.dart';
import 'presentation/overlays/fade_overlay.dart';
import 'presentation/overlays/game_over_overlay.dart';
import 'presentation/overlays/hud_overlay.dart';
import 'presentation/overlays/menu_overlay.dart';
import 'presentation/overlays/save_slots_overlay.dart';
import 'presentation/overlays/title_overlay.dart';

class LegendHeroesApp extends StatelessWidget {
  const LegendHeroesApp({super.key, required this.data, required this.saves});

  final GameData data;
  final SaveRepository saves;

  @override
  Widget build(BuildContext context) => MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameScreen(data: data, saves: saves),
      );
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.data, required this.saves});

  final GameData data;
  final SaveRepository saves;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final AshenCrestGame _game =
      AshenCrestGame(data: widget.data, input: InputState(), saves: widget.saves);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _game.l10n = AppLocalizations.of(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: GameWidget<AshenCrestGame>(
          game: _game,
          overlayBuilderMap: {
            Overlays.title: (context, game) => TitleOverlay(game: game),
            Overlays.controls: (context, game) => ControlsOverlay(game: game),
            Overlays.hud: (context, game) => HudOverlay(game: game),
            Overlays.dialog: (context, game) => DialogOverlay(cubit: game.dialog),
            Overlays.menu: (context, game) => MenuOverlay(game: game),
            Overlays.saveSlots: (context, game) => SaveSlotsOverlay(game: game),
            Overlays.battleHud: (context, game) => BattleHud(game: game),
            Overlays.gameOver: (context, game) => GameOverOverlay(game: game),
            Overlays.fade: (context, game) => FadeOverlay(game: game),
          },
        ),
      );
}
