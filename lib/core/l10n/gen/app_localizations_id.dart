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

  @override
  String get titleSubtitle => 'Chapter 1: Ashen Crest';

  @override
  String get titleNewGame => 'Mulai Baru';

  @override
  String get titleContinue => 'Lanjutkan';

  @override
  String get titleLoad => 'Muat';

  @override
  String get menuParty => 'Party';

  @override
  String get menuItems => 'Item';

  @override
  String get menuClose => 'Tutup';

  @override
  String get menuQuitToTitle => 'Kembali ke Judul';

  @override
  String levelLabel(int level) {
    return 'Lv $level';
  }

  @override
  String expToNext(int exp) {
    return 'Level berikut: $exp EXP';
  }

  @override
  String get useOn => 'Pakai ke siapa?';

  @override
  String get noItems => 'Tidak ada item.';

  @override
  String get saveTitle => 'Simpan';

  @override
  String get loadTitle => 'Muat';

  @override
  String get slotEmpty => 'Kosong';

  @override
  String get slotAuto => 'Simpan otomatis';

  @override
  String slotManual(int n) {
    return 'Slot $n';
  }

  @override
  String get saved => 'Permainan disimpan.';

  @override
  String foundItem(String item, int count) {
    return 'Menemukan $item ×$count';
  }

  @override
  String get chestEmpty => 'Peti ini kosong.';

  @override
  String levelUp(String name, int level) {
    return '$name naik ke Lv $level!';
  }

  @override
  String get gameOverTitle => 'Game Over';

  @override
  String get gameOverLoad => 'Muat simpanan terakhir';

  @override
  String get gameOverToTitle => 'Kembali ke judul';

  @override
  String get mapHollowmere => 'Hollowmere';

  @override
  String get mapWhisperwood => 'Whisperwood';

  @override
  String get dangerLow => 'Aman';

  @override
  String get dangerMedium => 'Waspada';

  @override
  String get dangerHigh => 'Bahaya';
}
