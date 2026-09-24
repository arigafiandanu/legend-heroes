import '../core/l10n/gen/app_localizations.dart';
import '../domain/attack_type.dart';

extension AttackTypeName on AttackType {
  String label(AppLocalizations l) => switch (this) {
        AttackType.sword => l.typeSword,
        AttackType.spear => l.typeSpear,
        AttackType.staff => l.typeStaff,
        AttackType.dagger => l.typeDagger,
        AttackType.fire => l.typeFire,
        AttackType.ice => l.typeIce,
        AttackType.lightning => l.typeLightning,
        AttackType.wind => l.typeWind,
        AttackType.light => l.typeLight,
      };
}
