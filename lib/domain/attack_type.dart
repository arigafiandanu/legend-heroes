/// The 9 attack types. Weapons use ATK/DEF, elements use EATK/EDEF.
enum AttackType {
  sword,
  spear,
  staff,
  dagger,
  fire,
  ice,
  lightning,
  wind,
  light;

  bool get isWeapon => index <= dagger.index;
}
