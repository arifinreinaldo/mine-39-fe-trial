import 'dart:math';

import '../../data/models/game_board.dart';
import '../../data/models/unit.dart';

/// Grid movement and range calculation.
///
/// Movement uses a cost-aware flood fill (Dijkstra) rather than a plain BFS,
/// because terrain has variable entry cost (forest 2, mountain 3, ...). A plain
/// BFS that marks a tile visited on first arrival can lock in an expensive path
/// and wrongly exclude reachable tiles, so we always keep the cheapest cost to
/// each tile.
class MovementSystem {
  const MovementSystem._();

  static const List<List<int>> _dirs = [
    [1, 0],
    [-1, 0],
    [0, 1],
    [0, -1],
  ];

  static int manhattan(Point<int> a, Point<int> b) =>
      (a.x - b.x).abs() + (a.y - b.y).abs();

  /// Minimum movement cost to reach every tile within range of [unit],
  /// keyed by tile. Enemy-occupied tiles block passage; allied units can be
  /// passed through but not stopped on (see [movementRange]).
  static Map<Point<int>, int> reachableCosts(Unit unit, GameBoard board) {
    final best = <Point<int>, int>{unit.position: 0};
    final frontier = <Point<int>>[unit.position];

    while (frontier.isNotEmpty) {
      // Cheap priority queue: fine for the small grids this game uses.
      frontier.sort((a, b) => best[a]!.compareTo(best[b]!));
      final current = frontier.removeAt(0);
      final currentCost = best[current]!;

      for (final next in _neighbors(current, board)) {
        final tile = board.tileAt(next);
        if (!tile.isPassableFor(unit.unitClass)) continue;

        final occupant = board.unitAt(next);
        if (occupant != null && occupant.faction != unit.faction) continue;

        final newCost = currentCost + tile.movementCost(unit.unitClass);
        if (newCost <= unit.movement &&
            (best[next] == null || newCost < best[next]!)) {
          best[next] = newCost;
          frontier.add(next);
        }
      }
    }
    return best;
  }

  /// Tiles [unit] can actually end its move on: reachable and not occupied by
  /// another unit (its own tile is allowed).
  static Set<Point<int>> movementRange(Unit unit, GameBoard board) {
    final costs = reachableCosts(unit, board);
    return costs.keys.where((p) {
      final occupant = board.unitAt(p);
      return occupant == null || occupant == unit;
    }).toSet();
  }

  /// The cheapest ordered path from the unit's current tile to [dest],
  /// excluding the start tile. Returns an empty list if [dest] is the current
  /// tile, or null if [dest] is unreachable within movement.
  static List<Point<int>>? path(Unit unit, Point<int> dest, GameBoard board) {
    if (dest == unit.position) return <Point<int>>[];

    final best = <Point<int>, int>{unit.position: 0};
    final prev = <Point<int>, Point<int>>{};
    final frontier = <Point<int>>[unit.position];

    while (frontier.isNotEmpty) {
      frontier.sort((a, b) => best[a]!.compareTo(best[b]!));
      final current = frontier.removeAt(0);
      final currentCost = best[current]!;

      for (final next in _neighbors(current, board)) {
        final tile = board.tileAt(next);
        if (!tile.isPassableFor(unit.unitClass)) continue;

        final occupant = board.unitAt(next);
        if (occupant != null && occupant.faction != unit.faction) continue;

        final newCost = currentCost + tile.movementCost(unit.unitClass);
        if (newCost <= unit.movement &&
            (best[next] == null || newCost < best[next]!)) {
          best[next] = newCost;
          prev[next] = current;
          frontier.add(next);
        }
      }
    }

    if (!best.containsKey(dest)) return null;

    final reversed = <Point<int>>[];
    Point<int>? step = dest;
    while (step != null && step != unit.position) {
      reversed.add(step);
      step = prev[step];
    }
    return reversed.reversed.toList();
  }

  /// All in-bounds tiles within [minRange]..[maxRange] (Manhattan) of any of the
  /// given [origins]. The origins themselves are removed so callers can colour
  /// "attack-only" tiles distinctly from movement tiles.
  static Set<Point<int>> attackableTiles(
    Iterable<Point<int>> origins,
    int minRange,
    int maxRange,
    GameBoard board,
  ) {
    final result = <Point<int>>{};
    for (final origin in origins) {
      for (var dx = -maxRange; dx <= maxRange; dx++) {
        for (var dy = -maxRange; dy <= maxRange; dy++) {
          final dist = dx.abs() + dy.abs();
          if (dist < minRange || dist > maxRange) continue;
          final p = Point(origin.x + dx, origin.y + dy);
          if (board.inBounds(p)) result.add(p);
        }
      }
    }
    result.removeAll(origins);
    return result;
  }

  static List<Point<int>> _neighbors(Point<int> p, GameBoard board) {
    final result = <Point<int>>[];
    for (final d in _dirs) {
      final np = Point(p.x + d[0], p.y + d[1]);
      if (board.inBounds(np)) result.add(np);
    }
    return result;
  }
}
