import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Ashen Crest'**
  String get appTitle;

  /// No description provided for @actionButton.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get actionButton;

  /// No description provided for @runButton.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get runButton;

  /// No description provided for @menuButton.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuButton;

  /// No description provided for @testBattleButton.
  ///
  /// In en, this message translates to:
  /// **'Test Battle'**
  String get testBattleButton;

  /// No description provided for @cmdAttack.
  ///
  /// In en, this message translates to:
  /// **'Attack'**
  String get cmdAttack;

  /// No description provided for @cmdSkill.
  ///
  /// In en, this message translates to:
  /// **'Skill'**
  String get cmdSkill;

  /// No description provided for @cmdItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get cmdItem;

  /// No description provided for @cmdDefend.
  ///
  /// In en, this message translates to:
  /// **'Defend'**
  String get cmdDefend;

  /// No description provided for @cmdFlee.
  ///
  /// In en, this message translates to:
  /// **'Flee'**
  String get cmdFlee;

  /// No description provided for @cmdBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get cmdBack;

  /// No description provided for @cmdConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get cmdConfirm;

  /// No description provided for @roundLabel.
  ///
  /// In en, this message translates to:
  /// **'Round {round}'**
  String roundLabel(int round);

  /// No description provided for @nextRoundLabel.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextRoundLabel;

  /// No description provided for @spCost.
  ///
  /// In en, this message translates to:
  /// **'{sp} SP'**
  String spCost(int sp);

  /// No description provided for @breakText.
  ///
  /// In en, this message translates to:
  /// **'BREAK'**
  String get breakText;

  /// No description provided for @weakText.
  ///
  /// In en, this message translates to:
  /// **'WEAK'**
  String get weakText;

  /// No description provided for @victoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Victory!'**
  String get victoryTitle;

  /// No description provided for @victoryRewards.
  ///
  /// In en, this message translates to:
  /// **'{exp} EXP · {keping} Keping'**
  String victoryRewards(int exp, int keping);

  /// No description provided for @defeatTitle.
  ///
  /// In en, this message translates to:
  /// **'Defeated...'**
  String get defeatTitle;

  /// No description provided for @escapedTitle.
  ///
  /// In en, this message translates to:
  /// **'Got away safely'**
  String get escapedTitle;

  /// No description provided for @escapeFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t escape!'**
  String get escapeFailed;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @typeSword.
  ///
  /// In en, this message translates to:
  /// **'Sword'**
  String get typeSword;

  /// No description provided for @typeSpear.
  ///
  /// In en, this message translates to:
  /// **'Spear'**
  String get typeSpear;

  /// No description provided for @typeStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get typeStaff;

  /// No description provided for @typeDagger.
  ///
  /// In en, this message translates to:
  /// **'Dagger'**
  String get typeDagger;

  /// No description provided for @typeFire.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get typeFire;

  /// No description provided for @typeIce.
  ///
  /// In en, this message translates to:
  /// **'Ice'**
  String get typeIce;

  /// No description provided for @typeLightning.
  ///
  /// In en, this message translates to:
  /// **'Lightning'**
  String get typeLightning;

  /// No description provided for @typeWind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get typeWind;

  /// No description provided for @typeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get typeLight;

  /// No description provided for @boostTitle.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get boostTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
