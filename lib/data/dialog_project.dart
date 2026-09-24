import 'dart:async';

import 'package:flutter/services.dart';
import 'package:jenny/jenny.dart';

/// What Yarn scripts can do to the game.
///
/// Commands: `<<flag name>>`, `<<give item count>>`, `<<rest>>`,
/// `<<save_menu>>`. Function: `has_flag("name")`.
abstract interface class DialogHost {
  bool hasFlag(String flag);
  void setFlag(String flag);
  void giveItem(String id, int count);
  void restParty();
  Future<void> openSaveMenu();
}

abstract final class DialogFiles {
  static const languages = ['id', 'en'];
  static const files = ['hollowmere.yarn', 'whisperwood.yarn'];

  static Future<List<String>> load(AssetBundle bundle, String languageCode) async {
    final lang = languages.contains(languageCode) ? languageCode : 'en';
    return [for (final f in files) await bundle.loadString('assets/dialog/$lang/$f')];
  }
}

YarnProject buildYarnProject(List<String> sources, DialogHost host) {
  final project = YarnProject()..strictCharacterNames = false;
  project.functions.addFunction1<bool, String>('has_flag', host.hasFlag);
  project.commands
    ..addCommand1<String>('flag', host.setFlag)
    ..addCommand2<String, int>('give', host.giveItem)
    ..addCommand0('rest', host.restParty)
    ..addCommand0('save_menu', host.openSaveMenu);
  for (final s in sources) {
    project.parse(s);
  }
  return project;
}
