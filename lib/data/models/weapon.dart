/// The category of a weapon. Sword/Lance/Axe form the melee "weapon triangle";
/// Bow and Magic sit outside it (they trade triangle interaction for range).
enum WeaponType { sword, lance, axe, bow, magic }

/// Outcome of comparing two weapon types on the triangle.
enum TriangleResult { advantage, neutral, disadvantage }

/// An equippable weapon. Stats are deliberately small integers in the spirit of
/// the genre's tight, readable math.
class Weapon {
  const Weapon({
    required this.name,
    required this.type,
    required this.might,
    required this.hit,
    required this.crit,
    required this.minRange,
    required this.maxRange,
  });

  final String name;
  final WeaponType type;
  final int might;
  final int hit;
  final int crit;
  final int minRange;
  final int maxRange;

  bool get isMagic => type == WeaponType.magic;

  /// Whether this weapon can strike a target at [distance] tiles (Manhattan).
  bool reaches(int distance) => distance >= minRange && distance <= maxRange;

  /// The weapon triangle: Sword > Axe > Lance > Sword. Bow and Magic are
  /// neutral against everything (and everything is neutral against them).
  static TriangleResult triangle(WeaponType attacker, WeaponType defender) {
    bool beats(WeaponType a, WeaponType b) =>
        (a == WeaponType.sword && b == WeaponType.axe) ||
        (a == WeaponType.axe && b == WeaponType.lance) ||
        (a == WeaponType.lance && b == WeaponType.sword);
    if (beats(attacker, defender)) return TriangleResult.advantage;
    if (beats(defender, attacker)) return TriangleResult.disadvantage;
    return TriangleResult.neutral;
  }

  /// A small catalogue of weapons referenced by id from chapter JSON.
  static const Map<String, Weapon> catalogue = {
    'ironSword': Weapon(name: 'Iron Sword', type: WeaponType.sword, might: 5, hit: 90, crit: 0, minRange: 1, maxRange: 1),
    'swiftEdge': Weapon(name: 'Swift Edge', type: WeaponType.sword, might: 4, hit: 90, crit: 25, minRange: 1, maxRange: 1),
    'ironLance': Weapon(name: 'Iron Lance', type: WeaponType.lance, might: 7, hit: 80, crit: 0, minRange: 1, maxRange: 1),
    'ironAxe': Weapon(name: 'Iron Axe', type: WeaponType.axe, might: 8, hit: 75, crit: 0, minRange: 1, maxRange: 1),
    'ironBow': Weapon(name: 'Iron Bow', type: WeaponType.bow, might: 6, hit: 85, crit: 0, minRange: 2, maxRange: 2),
    'flame': Weapon(name: 'Flame', type: WeaponType.magic, might: 5, hit: 90, crit: 0, minRange: 1, maxRange: 2),
  };

  static Weapon byId(String id) =>
      catalogue[id] ?? catalogue['ironSword']!;
}
