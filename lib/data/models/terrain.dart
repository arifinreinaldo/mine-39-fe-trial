/// Terrain types and the tactical bonuses each grants.
///
/// [moveCost] is the number of movement points required to *enter* a tile of
/// this terrain. [defenseBonus] is subtracted from incoming damage (i.e. added
/// to the occupant's effective defense/resistance), and [avoidBonus] is added
/// to the occupant's avoid (dodge) chance. Blocked terrain cannot be entered by
/// ground units at all.
///
/// The integer order of these values is also their JSON id (see
/// `assets/maps/*.json`): 0=plain, 1=forest, 2=mountain, 3=fort, 4=water,
/// 5=wall.
enum TerrainType {
  plain(label: 'Plain', moveCost: 1, defenseBonus: 0, avoidBonus: 0, blocksMovement: false),
  forest(label: 'Forest', moveCost: 2, defenseBonus: 1, avoidBonus: 20, blocksMovement: false),
  mountain(label: 'Mountain', moveCost: 3, defenseBonus: 2, avoidBonus: 30, blocksMovement: false),
  fort(label: 'Fort', moveCost: 1, defenseBonus: 2, avoidBonus: 20, blocksMovement: false),
  water(label: 'Water', moveCost: 99, defenseBonus: 0, avoidBonus: 0, blocksMovement: true),
  wall(label: 'Wall', moveCost: 99, defenseBonus: 0, avoidBonus: 0, blocksMovement: true);

  const TerrainType({
    required this.label,
    required this.moveCost,
    required this.defenseBonus,
    required this.avoidBonus,
    required this.blocksMovement,
  });

  final String label;
  final int moveCost;
  final int defenseBonus;
  final int avoidBonus;
  final bool blocksMovement;

  /// Resolves a terrain from its JSON integer id, defaulting to [plain].
  static TerrainType fromId(int id) =>
      (id >= 0 && id < values.length) ? values[id] : TerrainType.plain;
}
