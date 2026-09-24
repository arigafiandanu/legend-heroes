import 'package:flutter/material.dart';

import '../../game/ashen_crest_game.dart';

class FadeOverlay extends StatelessWidget {
  const FadeOverlay({super.key, required this.game});

  final AshenCrestGame game;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        ignoring: true,
        child: ValueListenableBuilder<double>(
          valueListenable: game.fade,
          builder: (context, v, _) => v <= 0 ? const SizedBox.shrink() : ColoredBox(color: Color.fromRGBO(0, 0, 0, v)),
        ),
      );
}
