import 'weapon.dart';

/// A unit's class. Drives base movement, the weapon it tends to wield, and a
/// flag for fliers (who ignore ground terrain costs). The genre's promotion
/// system would extend this (e.g. myrmidon -> swordmaster); that hook is left
/// for later.
enum UnitClass {
  lord(label: 'Lord', baseMove: 5, defaultWeapon: WeaponType.sword, isFlier: false),
  myrmidon(label: 'Myrmidon', baseMove: 5, defaultWeapon: WeaponType.sword, isFlier: false),
  knight(label: 'Knight', baseMove: 4, defaultWeapon: WeaponType.lance, isFlier: false),
  soldier(label: 'Soldier', baseMove: 5, defaultWeapon: WeaponType.lance, isFlier: false),
  fighter(label: 'Fighter', baseMove: 5, defaultWeapon: WeaponType.axe, isFlier: false),
  archer(label: 'Archer', baseMove: 5, defaultWeapon: WeaponType.bow, isFlier: false),
  mage(label: 'Mage', baseMove: 5, defaultWeapon: WeaponType.magic, isFlier: false);

  const UnitClass({
    required this.label,
    required this.baseMove,
    required this.defaultWeapon,
    required this.isFlier,
  });

  final String label;
  final int baseMove;
  final WeaponType defaultWeapon;
  final bool isFlier;

  static UnitClass fromId(String id) =>
      values.firstWhere((c) => c.name == id, orElse: () => UnitClass.soldier);
}
