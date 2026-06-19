import 'dart:math';

import 'terrain.dart';
import 'unit_class.dart';

/// A single cell of the battlefield. A tile knows its [terrain] and grid
/// [position]; occupancy is tracked on units (a single source of truth) rather
/// than stored here, and looked up via `GameBoard.unitAt`.
class Tile {
  const Tile({required this.position, required this.terrain});

  final Point<int> position;
  final TerrainType terrain;

  int get defenseBonus => terrain.defenseBonus;
  int get avoidBonus => terrain.avoidBonus;

  /// Movement points required for [unitClass] to enter this tile. Fliers glide
  /// over everything passable at a flat cost of 1.
  int movementCost(UnitClass unitClass) {
    if (unitClass.isFlier) return 1;
    return terrain.moveCost;
  }

  /// Whether [unitClass] may ever stand on this tile.
  bool isPassableFor(UnitClass unitClass) {
    if (unitClass.isFlier) return terrain != TerrainType.wall;
    return !terrain.blocksMovement;
  }
}
