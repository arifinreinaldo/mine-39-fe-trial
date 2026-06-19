import '../../data/models/game_board.dart';
import '../../data/models/unit.dart';
import 'movement.dart';

/// Healing support: staff (cleric) heals and consumable vulneraries. Pure Dart
/// so it can be unit-tested without the bloc/UI.
class HealSystem {
  const HealSystem._();

  static const int vulneraryHeal = 10;
  static const String vulnerary = 'vulnerary';

  /// Amount a staff user restores: the staff's base plus the healer's magic.
  static int staffHealAmount(Unit healer) => healer.weapon.heal + healer.magic;

  /// Wounded allies a staff user can reach (excludes the healer itself).
  static List<Unit> healTargets(Unit healer, GameBoard board) {
    if (!healer.weapon.isStaff) return const [];
    return board.units
        .where((u) =>
            u.isAlive &&
            u != healer &&
            u.faction == healer.faction &&
            u.hp < u.maxHp &&
            healer.weapon
                .reaches(MovementSystem.manhattan(healer.position, u.position)))
        .toList();
  }

  static bool canUseVulnerary(Unit u) =>
      u.heldItems.contains(vulnerary) && u.hp < u.maxHp;

  /// Restores [amount] HP to [target] (clamped to max); returns HP actually
  /// recovered.
  static int heal(Unit target, int amount) {
    final before = target.hp;
    target.hp = (target.hp + amount).clamp(0, target.maxHp);
    return target.hp - before;
  }
}
