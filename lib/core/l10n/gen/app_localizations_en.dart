// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ashen Crest';

  @override
  String get actionButton => 'Action';

  @override
  String get runButton => 'Run';

  @override
  String get menuButton => 'Menu';

  @override
  String get testBattleButton => 'Test Battle';

  @override
  String get cmdAttack => 'Attack';

  @override
  String get cmdSkill => 'Skill';

  @override
  String get cmdItem => 'Item';

  @override
  String get cmdDefend => 'Defend';

  @override
  String get cmdFlee => 'Flee';

  @override
  String get cmdBack => 'Back';

  @override
  String get cmdConfirm => 'Confirm';

  @override
  String roundLabel(int round) {
    return 'Round $round';
  }

  @override
  String get nextRoundLabel => 'Next';

  @override
  String spCost(int sp) {
    return '$sp SP';
  }

  @override
  String get breakText => 'BREAK';

  @override
  String get weakText => 'WEAK';

  @override
  String get victoryTitle => 'Victory!';

  @override
  String victoryRewards(int exp, int keping) {
    return '$exp EXP · $keping Keping';
  }

  @override
  String get defeatTitle => 'Defeated...';

  @override
  String get escapedTitle => 'Got away safely';

  @override
  String get escapeFailed => 'Couldn\'t escape!';

  @override
  String get continueButton => 'Continue';

  @override
  String get typeSword => 'Sword';

  @override
  String get typeSpear => 'Spear';

  @override
  String get typeStaff => 'Staff';

  @override
  String get typeDagger => 'Dagger';

  @override
  String get typeFire => 'Fire';

  @override
  String get typeIce => 'Ice';

  @override
  String get typeLightning => 'Lightning';

  @override
  String get typeWind => 'Wind';

  @override
  String get typeLight => 'Light';

  @override
  String get boostTitle => 'Boost';
}
