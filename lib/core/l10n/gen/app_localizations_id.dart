// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Legend Heroes';

  @override
  String get actionButton => 'Aksi';

  @override
  String get runButton => 'Lari';

  @override
  String get menuButton => 'Menu';

  @override
  String get testBattleButton => 'Tes Battle';

  @override
  String get cmdAttack => 'Serang';

  @override
  String get cmdSkill => 'Skill';

  @override
  String get cmdItem => 'Item';

  @override
  String get cmdDefend => 'Tahan';

  @override
  String get cmdFlee => 'Kabur';

  @override
  String get cmdBack => 'Kembali';

  @override
  String get cmdConfirm => 'Oke';

  @override
  String roundLabel(int round) {
    return 'Ronde $round';
  }

  @override
  String get nextRoundLabel => 'Berikut';

  @override
  String spCost(int sp) {
    return '$sp SP';
  }

  @override
  String get breakText => 'BREAK';

  @override
  String get weakText => 'LEMAH';

  @override
  String get victoryTitle => 'Menang!';

  @override
  String victoryRewards(int exp, int keping) {
    return '$exp EXP · $keping Keping';
  }

  @override
  String get defeatTitle => 'Kalah...';

  @override
  String get escapedTitle => 'Berhasil kabur';

  @override
  String get escapeFailed => 'Gagal kabur!';

  @override
  String get continueButton => 'Lanjut';

  @override
  String get typeSword => 'Pedang';

  @override
  String get typeSpear => 'Tombak';

  @override
  String get typeStaff => 'Tongkat';

  @override
  String get typeDagger => 'Belati';

  @override
  String get typeFire => 'Api';

  @override
  String get typeIce => 'Es';

  @override
  String get typeLightning => 'Petir';

  @override
  String get typeWind => 'Angin';

  @override
  String get typeLight => 'Cahaya';

  @override
  String get boostTitle => 'Boost';
}
