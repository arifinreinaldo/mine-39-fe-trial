import '../../data/models/unit.dart';
import '../../data/models/unit_class.dart';
import '../../data/models/weapon.dart';

/// Class promotion: which branches a unit may take and how applying one changes
/// the unit. Kept as pure Dart so it can be unit-tested independently of the
/// bloc/UI.
class PromotionSystem {
  const PromotionSystem._();

  /// Minimum level to promote a base class. Trainee steps (`levelUp`) also use
  /// this threshold here for simplicity.
  static const int minLevel = 10;

  /// Branches the unit can take right now: high enough level, and either a free
  /// trainee step or the required seal in hand.
  static List<Promotion> optionsFor(Unit unit) {
    if (unit.level < minLevel) return const [];
    return unit.unitClass.promotions
        .where((p) => p.item == 'levelUp' || unit.heldItems.contains(p.item))
        .toList();
  }

  static bool canPromote(Unit unit) => optionsFor(unit).isNotEmpty;

  /// Applies [promotion] in place: swaps class, adds the stat bonus, resets to
  /// level 1, consumes the seal, and clamps to the new class's caps.
  static void apply(Unit unit, Promotion promotion) {
    final bonus = promotion.bonus;
    unit.unitClass = promotion.to;
    unit.maxHp += bonus.hp;
    unit.hp += bonus.hp;
    unit.strength += bonus.str;
    unit.magic += bonus.mag;
    unit.skill += bonus.skl;
    unit.speed += bonus.spd;
    unit.defense += bonus.def;
    unit.resistance += bonus.res;
    unit.con += bonus.con;
    unit.movement = promotion.to.baseMove;

    // Keep the equipped weapon if the new class can still wield it; otherwise
    // hand over a basic weapon of its primary type.
    if (!promotion.to.weapons.contains(unit.weapon.type)) {
      unit.weapon = Weapon.byId(basicWeaponFor(promotion.to.primaryWeapon));
    }

    if (promotion.item != 'levelUp') unit.heldItems.remove(promotion.item);
    unit.level = 1;
    unit.exp = 0;
    unit.clampToCaps();
    unit.clampHp();
  }

  static String basicWeaponFor(WeaponType type) => switch (type) {
        WeaponType.sword => 'ironSword',
        WeaponType.lance => 'ironLance',
        WeaponType.axe => 'ironAxe',
        WeaponType.bow => 'ironBow',
        WeaponType.magic => 'flame',
      };
}
