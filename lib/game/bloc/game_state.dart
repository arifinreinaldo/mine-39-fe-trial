import 'dart:math';

import '../../data/models/game_board.dart';
import '../../data/models/unit.dart';
import '../../data/models/unit_class.dart';
import '../logic/combat.dart';

/// States emitted by [GameBloc].
///
/// Note: these intentionally do NOT implement value equality. The board is
/// mutated in place during play, so every emit is a fresh instance and always
/// triggers a rebuild — which is what we want for a game board.
sealed class GameState {
  const GameState();
}

class GameLoading extends GameState {
  const GameLoading();
}

class GameError extends GameState {
  const GameError(this.message);
  final String message;
}

/// Base for any in-battle state; always carries the live [board] to render.
sealed class BattleState extends GameState {
  const BattleState(this.board);
  final GameBoard board;
}

/// Player phase, nothing selected. [showPhaseBanner] is true on the frame the
/// player phase (re)starts so the UI can flash a "Player Phase" banner.
class PlayerTurnIdle extends BattleState {
  const PlayerTurnIdle(super.board, {this.showPhaseBanner = false});
  final bool showPhaseBanner;
}

/// A player unit is selected; movement/attack ranges are shown.
class UnitSelected extends BattleState {
  const UnitSelected(
    super.board, {
    required this.unit,
    required this.movementTiles,
    required this.attackTiles,
    required this.origin,
  });
  final Unit unit;
  final Set<Point<int>> movementTiles;
  final Set<Point<int>> attackTiles;
  final Point<int> origin;
}

/// A player unit is gliding along [path] to its chosen tile.
class UnitMoving extends BattleState {
  const UnitMoving(
    super.board, {
    required this.unit,
    required this.path,
    required this.origin,
  });
  final Unit unit;
  final List<Point<int>> path;
  final Point<int> origin;
}

/// The unit has arrived; choose Attack (if [attackableTargets] is non-empty),
/// Wait, or Cancel (return to [origin]).
class UnitActionMenu extends BattleState {
  const UnitActionMenu(
    super.board, {
    required this.unit,
    required this.origin,
    required this.attackableTargets,
    required this.canPromote,
    required this.canHeal,
    required this.canUseItem,
  });
  final Unit unit;
  final Point<int> origin;
  final List<Unit> attackableTargets;
  final bool canPromote;
  final bool canHeal;
  final bool canUseItem;
}

/// Choosing a wounded ally to heal with a staff.
class ChoosingHealTarget extends BattleState {
  const ChoosingHealTarget(
    super.board, {
    required this.unit,
    required this.origin,
    required this.targets,
  });
  final Unit unit;
  final Point<int> origin;
  final List<Unit> targets;
}

/// A heal effect is animating over [target] (+[amount] HP).
class HealAnimating extends BattleState {
  const HealAnimating(super.board, {required this.target, required this.amount});
  final Unit target;
  final int amount;
}

/// Choosing which class to promote into (1-of-2, or 3 for trainees).
class ChoosingPromotion extends BattleState {
  const ChoosingPromotion(
    super.board, {
    required this.unit,
    required this.origin,
    required this.options,
  });
  final Unit unit;
  final Point<int> origin;
  final List<Promotion> options;
}

/// Choosing which enemy to strike.
class ChoosingTarget extends BattleState {
  const ChoosingTarget(
    super.board, {
    required this.unit,
    required this.origin,
    required this.targets,
  });
  final Unit unit;
  final Point<int> origin;
  final List<Unit> targets;
}

/// Showing the battle forecast before committing to an attack.
class CombatPreviewState extends BattleState {
  const CombatPreviewState(
    super.board, {
    required this.unit,
    required this.origin,
    required this.target,
    required this.forecast,
  });
  final Unit unit;
  final Point<int> origin;
  final Unit target;
  final CombatForecast forecast;
}

/// A combat exchange is animating. Shared by both phases ([isEnemyPhase]).
class CombatAnimating extends BattleState {
  const CombatAnimating(
    super.board, {
    required this.result,
    required this.isEnemyPhase,
  });
  final CombatResult result;
  final bool isEnemyPhase;
}

/// Brief marker state when the enemy phase begins (drives the banner).
class EnemyTurnBanner extends BattleState {
  const EnemyTurnBanner(super.board);
}

/// An enemy unit is gliding along [path]; if [pendingTarget] is set it will
/// attack on arrival.
class EnemyMoving extends BattleState {
  const EnemyMoving(
    super.board, {
    required this.unit,
    required this.path,
    required this.pendingTarget,
  });
  final Unit unit;
  final List<Point<int>> path;
  final Unit? pendingTarget;
}

class BattleOver extends BattleState {
  const BattleOver(super.board, {required this.playerWon});
  final bool playerWon;
}
