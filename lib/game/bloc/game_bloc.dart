import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/game_board.dart';
import '../../data/models/unit.dart';
import '../../data/repositories/chapter_repository.dart';
import '../logic/combat.dart';
import '../logic/enemy_ai.dart';
import '../logic/movement.dart';
import '../logic/promotion.dart';
import '../logic/support.dart';
import 'game_event.dart';
import 'game_state.dart';

/// The single source of truth for a battle. It owns the [GameBoard], decides
/// what each touch means in context, runs the combat math, and drives the enemy
/// phase. Animation is delegated to the view, which signals completion back via
/// [MovementAnimationCompleted] / [CombatAnimationCompleted].
class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc({required this.repository, Random? rng})
      : _rng = rng ?? Random(),
        super(const GameLoading()) {
    on<GameStarted>(_onStarted);
    on<TileTapped>(_onTileTapped);
    on<ActionSelected>(_onActionSelected);
    on<CombatConfirmed>(_onCombatConfirmed);
    on<PromotionChosen>(_onPromotionChosen);
    on<SelectionCancelled>(_onSelectionCancelled);
    on<EndTurnRequested>(_onEndTurnRequested);
    on<MovementAnimationCompleted>(_onMovementDone);
    on<CombatAnimationCompleted>(_onCombatDone);
    on<HealAnimationCompleted>(_onHealDone);
    on<AdvanceAiRequested>(_onAdvanceAi);
  }

  final ChapterRepository repository;
  final Random _rng;

  late GameBoard _board;
  late CombatSystem _combat;

  int _turn = 1;

  /// Current player-turn number (1-based), for the HUD.
  int get turn => _turn;

  Future<void> _onStarted(GameStarted event, Emitter<GameState> emit) async {
    emit(const GameLoading());
    try {
      _board = await repository.loadChapter(event.chapterAsset);
      _combat = CombatSystem(_board, rng: _rng);
      _turn = 1;
      emit(PlayerTurnIdle(_board, showPhaseBanner: true));
    } catch (e) {
      emit(GameError('Failed to load chapter: $e'));
    }
  }

  // ---- Touch handling -------------------------------------------------------

  void _onTileTapped(TileTapped event, Emitter<GameState> emit) {
    final pos = event.position;
    final current = state;

    if (current is PlayerTurnIdle) {
      final unit = _board.unitAt(pos);
      if (unit != null && unit.faction == Faction.player && !unit.hasActed) {
        emit(_selectionFor(unit));
      }
      return;
    }

    if (current is UnitSelected) {
      // Tapping another ready player unit re-selects it.
      final tapped = _board.unitAt(pos);
      if (tapped != null &&
          tapped != current.unit &&
          tapped.faction == Faction.player &&
          !tapped.hasActed) {
        emit(_selectionFor(tapped));
        return;
      }
      // Tapping a reachable tile moves there.
      if (current.movementTiles.contains(pos)) {
        final path = MovementSystem.path(current.unit, pos, _board) ?? const [];
        if (path.isEmpty) {
          emit(_actionMenuFor(current.unit, current.origin));
        } else {
          emit(UnitMoving(_board,
              unit: current.unit, path: path, origin: current.origin));
        }
        return;
      }
      // Anything else cancels the selection.
      emit(PlayerTurnIdle(_board));
      return;
    }

    if (current is ChoosingTarget) {
      final tapped = _board.unitAt(pos);
      if (tapped != null && current.targets.contains(tapped)) {
        emit(CombatPreviewState(_board,
            unit: current.unit,
            origin: current.origin,
            target: tapped,
            forecast: _combat.forecast(current.unit, tapped)));
      }
      return;
    }

    if (current is ChoosingHealTarget) {
      final tapped = _board.unitAt(pos);
      if (tapped != null && current.targets.contains(tapped)) {
        final healed =
            HealSystem.heal(tapped, HealSystem.staffHealAmount(current.unit));
        current.unit.hasActed = true;
        emit(HealAnimating(_board, target: tapped, amount: healed));
      }
      return;
    }
    // Other states ignore raw taps (use the on-screen buttons).
  }

  void _onActionSelected(ActionSelected event, Emitter<GameState> emit) {
    final current = state;
    if (current is! UnitActionMenu) return;

    switch (event.action) {
      case BattleAction.attack:
        if (current.attackableTargets.isEmpty) return;
        emit(ChoosingTarget(_board,
            unit: current.unit,
            origin: current.origin,
            targets: current.attackableTargets));
      case BattleAction.heal:
        final targets = HealSystem.healTargets(current.unit, _board);
        if (targets.isEmpty) return;
        emit(ChoosingHealTarget(_board,
            unit: current.unit, origin: current.origin, targets: targets));
      case BattleAction.item:
        if (!HealSystem.canUseVulnerary(current.unit)) return;
        final healed =
            HealSystem.heal(current.unit, HealSystem.vulneraryHeal);
        current.unit.heldItems.remove(HealSystem.vulnerary);
        current.unit.hasActed = true;
        emit(HealAnimating(_board, target: current.unit, amount: healed));
      case BattleAction.promote:
        final options = PromotionSystem.optionsFor(current.unit);
        if (options.isEmpty) return;
        emit(ChoosingPromotion(_board,
            unit: current.unit, origin: current.origin, options: options));
      case BattleAction.wait:
        current.unit.hasActed = true;
        _afterPlayerAction(emit);
    }
  }

  void _onPromotionChosen(PromotionChosen event, Emitter<GameState> emit) {
    final current = state;
    if (current is! ChoosingPromotion) return;
    PromotionSystem.apply(current.unit, event.promotion);
    current.unit.hasActed = true;
    _afterPlayerAction(emit);
  }

  void _onCombatConfirmed(CombatConfirmed event, Emitter<GameState> emit) {
    final current = state;
    if (current is! CombatPreviewState) return;

    final result = _combat.resolve(current.unit, current.target);
    _awardExp(result);
    current.unit.hasActed = true;
    emit(CombatAnimating(_board, result: result, isEnemyPhase: false));
  }

  void _onSelectionCancelled(SelectionCancelled event, Emitter<GameState> emit) {
    final current = state;
    if (current is UnitSelected) {
      emit(PlayerTurnIdle(_board));
    } else if (current is UnitActionMenu) {
      // Undo the move: send the unit back to where it started.
      current.unit.x = current.origin.x;
      current.unit.y = current.origin.y;
      current.unit.hasMoved = false;
      emit(_selectionFor(current.unit));
    } else if (current is ChoosingTarget) {
      emit(_actionMenuFor(current.unit, current.origin));
    } else if (current is ChoosingPromotion) {
      emit(_actionMenuFor(current.unit, current.origin));
    } else if (current is ChoosingHealTarget) {
      emit(_actionMenuFor(current.unit, current.origin));
    } else if (current is CombatPreviewState) {
      emit(ChoosingTarget(_board,
          unit: current.unit,
          origin: current.origin,
          targets: _targetsFor(current.unit)));
    }
  }

  void _onEndTurnRequested(EndTurnRequested event, Emitter<GameState> emit) {
    final current = state;
    if (current is! BattleState) return;
    if (current is CombatAnimating || current is EnemyMoving) return;
    _beginEnemyPhase(emit);
  }

  // ---- Animation completion -------------------------------------------------

  void _onMovementDone(MovementAnimationCompleted event, Emitter<GameState> emit) {
    final current = state;
    if (current is UnitMoving) {
      _commitPosition(current.unit, current.path);
      current.unit.hasMoved = true;
      emit(_actionMenuFor(current.unit, current.origin));
    } else if (current is EnemyMoving) {
      _commitPosition(current.unit, current.path);
      current.unit.hasMoved = true;
      final target = current.pendingTarget;
      if (target != null &&
          target.isAlive &&
          current.unit.weapon
              .reaches(MovementSystem.manhattan(current.unit.position, target.position))) {
        final result = _combat.resolve(current.unit, target);
        emit(CombatAnimating(_board, result: result, isEnemyPhase: true));
      } else {
        current.unit.hasActed = true;
        add(const AdvanceAiRequested());
      }
    }
  }

  void _onCombatDone(CombatAnimationCompleted event, Emitter<GameState> emit) {
    final current = state;
    if (current is! CombatAnimating) return;

    if (!_board.enemyHasUnits) {
      emit(BattleOver(_board, playerWon: true));
      return;
    }
    if (!_board.playerHasUnits) {
      emit(BattleOver(_board, playerWon: false));
      return;
    }

    current.result.attacker.hasActed = true;
    if (current.isEnemyPhase) {
      add(const AdvanceAiRequested());
    } else {
      _afterPlayerAction(emit);
    }
  }

  void _onHealDone(HealAnimationCompleted event, Emitter<GameState> emit) {
    if (state is! HealAnimating) return;
    _afterPlayerAction(emit);
  }

  // ---- Enemy phase ----------------------------------------------------------

  void _beginEnemyPhase(Emitter<GameState> emit) {
    for (final u in _board.units) {
      if (u.faction == Faction.player) u.hasActed = true;
    }
    emit(EnemyTurnBanner(_board));
    add(const AdvanceAiRequested());
  }

  void _onAdvanceAi(AdvanceAiRequested event, Emitter<GameState> emit) {
    final next = _board
        .aliveOf(Faction.enemy)
        .where((u) => !u.hasActed)
        .cast<Unit?>()
        .firstWhere((u) => true, orElse: () => null);

    if (next == null) {
      // Enemy phase finished — fresh player turn.
      for (final u in _board.units) {
        u.resetForNewTurn();
      }
      _turn++;
      emit(PlayerTurnIdle(_board, showPhaseBanner: true));
      return;
    }

    final decision = EnemyAi(_board, _combat).decideFor(next);
    if (decision.path.isEmpty && decision.target == null) {
      next.hasActed = true;
      add(const AdvanceAiRequested());
      return;
    }
    emit(EnemyMoving(_board,
        unit: next, path: decision.path, pendingTarget: decision.target));
  }

  // ---- Helpers --------------------------------------------------------------

  /// Advances to the next player turn after a unit finishes acting, auto-ending
  /// the phase once every player unit has acted.
  void _afterPlayerAction(Emitter<GameState> emit) {
    final anyReady = _board.aliveOf(Faction.player).any((u) => !u.hasActed);
    if (anyReady) {
      emit(PlayerTurnIdle(_board));
    } else {
      _beginEnemyPhase(emit);
    }
  }

  UnitSelected _selectionFor(Unit unit) {
    final movement = MovementSystem.movementRange(unit, _board);
    final attack = MovementSystem.attackableTiles(
        movement, unit.weapon.minRange, unit.weapon.maxRange, _board);
    return UnitSelected(_board,
        unit: unit,
        movementTiles: movement,
        attackTiles: attack,
        origin: unit.position);
  }

  UnitActionMenu _actionMenuFor(Unit unit, Point<int> origin) =>
      UnitActionMenu(_board,
          unit: unit,
          origin: origin,
          attackableTargets: _targetsFor(unit),
          canPromote: PromotionSystem.canPromote(unit),
          canHeal: HealSystem.healTargets(unit, _board).isNotEmpty,
          canUseItem: HealSystem.canUseVulnerary(unit));

  // Staff users cannot attack — they mend, not fight.
  List<Unit> _targetsFor(Unit unit) {
    if (unit.weapon.isStaff) return const [];
    return _board.units
        .where((u) =>
            u.isAlive &&
            u.faction != unit.faction &&
            unit.weapon
                .reaches(MovementSystem.manhattan(unit.position, u.position)))
        .toList();
  }

  void _commitPosition(Unit unit, List<Point<int>> path) {
    if (path.isEmpty) return;
    final dest = path.last;
    unit.x = dest.x;
    unit.y = dest.y;
  }

  void _awardExp(CombatResult result) {
    final attacker = result.attacker;
    if (attacker.faction != Faction.player || !attacker.isAlive) return;

    final dealt = result.strikes
        .where((s) => s.attacker == attacker && s.hit)
        .fold<int>(0, (sum, s) => sum + s.damage);
    var gained = dealt > 0 ? 10 : 1;
    if (result.casualties.any((c) => c.faction != Faction.player)) gained += 30;

    attacker.exp += gained;
    while (attacker.exp >= 100) {
      attacker.exp -= 100;
      _levelUp(attacker);
    }
  }

  /// Minimal, deterministic level-up. A fuller version would roll per-stat
  /// growth rates; left as a clearly-marked extension point.
  void _levelUp(Unit unit) {
    unit.level += 1;
    unit.maxHp += 2;
    unit.hp += 2;
    unit.strength += 1;
    unit.skill += 1;
    unit.speed += 1;
    unit.clampToCaps();
    unit.clampHp();
  }
}
