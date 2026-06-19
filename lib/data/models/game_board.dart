import 'dart:math';

import 'tile.dart';
import 'unit.dart';

/// The mutable battlefield state: a grid of [tiles] plus the full unit roster.
///
/// Tiles are stored row-major: `tiles[y][x]`. Units carry their own position,
/// so [unitAt] is the canonical way to ask "who is standing here?".
class GameBoard {
  GameBoard({
    required this.chapterName,
    required this.width,
    required this.height,
    required this.tiles,
    required this.units,
  });

  final String chapterName;
  final int width;
  final int height;
  final List<List<Tile>> tiles;
  final List<Unit> units;

  bool inBounds(Point<int> p) =>
      p.x >= 0 && p.x < width && p.y >= 0 && p.y < height;

  Tile tileAt(Point<int> p) => tiles[p.y][p.x];

  /// The living unit standing on [p], or null if the tile is empty.
  Unit? unitAt(Point<int> p) {
    for (final u in units) {
      if (u.isAlive && u.x == p.x && u.y == p.y) return u;
    }
    return null;
  }

  Iterable<Unit> aliveOf(Faction faction) =>
      units.where((u) => u.isAlive && u.faction == faction);

  bool get playerHasUnits => aliveOf(Faction.player).isNotEmpty;
  bool get enemyHasUnits => aliveOf(Faction.enemy).isNotEmpty;
}
