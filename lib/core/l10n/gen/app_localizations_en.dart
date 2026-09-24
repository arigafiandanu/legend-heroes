// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Legend Heroes';

  @override
  String get actionButton => 'Action';

  @override
  String get runButton => 'Run';

  @override
  String get menuButton => 'Menu';

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

  @override
  String get titleSubtitle => 'Chapter 1: Ashen Crest';

  @override
  String get titleNewGame => 'New Game';

  @override
  String get titleContinue => 'Continue';

  @override
  String get titleLoad => 'Load';

  @override
  String get menuParty => 'Party';

  @override
  String get menuItems => 'Items';

  @override
  String get menuClose => 'Close';

  @override
  String get menuQuitToTitle => 'Quit to Title';

  @override
  String levelLabel(int level) {
    return 'Lv $level';
  }

  @override
  String expToNext(int exp) {
    return 'Next level: $exp EXP';
  }

  @override
  String get useOn => 'Use on whom?';

  @override
  String get noItems => 'No items.';

  @override
  String get saveTitle => 'Save';

  @override
  String get loadTitle => 'Load';

  @override
  String get slotEmpty => 'Empty';

  @override
  String get slotAuto => 'Auto-save';

  @override
  String slotManual(int n) {
    return 'Slot $n';
  }

  @override
  String get saved => 'Game saved.';

  @override
  String foundItem(String item, int count) {
    return 'Found $item ×$count';
  }

  @override
  String get chestEmpty => 'The chest is empty.';

  @override
  String levelUp(String name, int level) {
    return '$name reached Lv $level!';
  }

  @override
  String get gameOverTitle => 'Game Over';

  @override
  String get gameOverLoad => 'Load last save';

  @override
  String get gameOverToTitle => 'Back to title';

  @override
  String get mapHollowmere => 'Hollowmere';

  @override
  String get mapWhisperwood => 'Whisperwood';

  @override
  String get dangerLow => 'Safe';

  @override
  String get dangerMedium => 'Careful';

  @override
  String get dangerHigh => 'Danger';
}
