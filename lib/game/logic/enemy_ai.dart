import 'dart:math';

import '../../data/models/game_board.dart';
import '../../data/models/unit.dart';
import 'combat.dart';
import 'movement.dart';

/// What an enemy unit decides to do on its turn: where to move and, optionally,
/// who to attack from there.
class AiDecision {
  AiDecision({
    required this.unit,
    required this.destination,
    required this.path,
    this.target,
  });

  final Unit unit;
  final Point<int> destination;
  final List<Point<int>> path;
  final Unit? target;
}

/// A simple greedy AI: if it can reach a tile from which it can hit a player,
/// it picks the highest-scoring such attack; otherwise it advances toward the
/// nearest player. This alone reads as recognisably Fire-Emblem-like.
class EnemyAi {
  EnemyAi(this.board, this.combat);

  final GameBoard board;
  final CombatSystem combat;

  AiDecision decideFor(Unit unit) {
    final reachable = MovementSystem.movementRange(unit, board);
    final players = board.aliveOf(Faction.player).toList();

    AiDecision? best;
    var bestScore = -1 << 30;

    for (final tile in reachable) {
      for (final player in players) {
        final dist = MovementSystem.manhattan(tile, player.position);
        if (!unit.weapon.reaches(dist)) continue;
        final score = _scoreAttack(unit, tile, player);
        if (score > bestScore) {
          bestScore = score;
          best = AiDecision(
            unit: unit,
            destination: tile,
            path: MovementSystem.path(unit, tile, board) ?? const [],
            target: player,
          );
        }
      }
    }
    if (best != null) return best;

    // No attack available: close the distance to the nearest player.
    if (players.isEmpty) {
      return AiDecision(unit: unit, destination: unit.position, path: const []);
    }
    players.sort((a, b) => MovementSystem.manhattan(unit.position, a.position)
        .compareTo(MovementSystem.manhattan(unit.position, b.position)));
    final goal = players.first.position;

    var bestTile = unit.position;
    var bestDist = MovementSystem.manhattan(unit.position, goal);
    for (final tile in reachable) {
      final d = MovementSystem.manhattan(tile, goal);
      if (d < bestDist) {
        bestDist = d;
        bestTile = tile;
      }
    }
    return AiDecision(
      unit: unit,
      destination: bestTile,
      path: MovementSystem.path(unit, bestTile, board) ?? const [],
    );
  }

  /// Scores attacking [defender] from [from]. Rewards expected damage and
  /// potential kills; penalises walking into a hard counter.
  int _scoreAttack(Unit attacker, Point<int> from, Unit defender) {
    final originX = attacker.x;
    final originY = attacker.y;
    attacker.x = from.x;
    attacker.y = from.y;

    final expectedDamage =
        (combat.damage(attacker, defender) * (combat.doubles(attacker, defender) ? 2 : 1) * combat.hitChance(attacker, defender)) ~/ 100;
    final counters = combat.canCounter(defender, attacker);
    final counterDamage = counters ? combat.damage(defender, attacker) : 0;

    attacker.x = originX;
    attacker.y = originY;

    var score = expectedDamage * 10;
    if (expectedDamage >= defender.hp) score += 1000; // likely kill
    score -= counterDamage * 3; // prefer striking without reprisal
    return score;
  }
}
