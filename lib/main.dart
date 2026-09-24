import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'data/game_data.dart';
import 'data/save_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();
  final data = await GameData.load(rootBundle);
  final saves = await SaveRepository.inAppDocuments();
  runApp(LegendHeroesApp(data: data, saves: saves));
}
