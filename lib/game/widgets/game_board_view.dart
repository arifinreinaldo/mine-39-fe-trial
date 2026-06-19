import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/game_board.dart';
import '../../data/models/unit.dart';
import '../bloc/game_bloc.dart';
import '../bloc/game_event.dart';
import '../bloc/game_state.dart';
import '../logic/combat.dart';
import '../painters/board_painter.dart';
import '../../l10n/game_strings.dart';

/// The interactive board. It paints via [BoardPainter] and owns the imperative
/// animation logic: when the bloc enters a "moving" or "combat" state, the view
/// plays the animation and then reports completion back to the bloc.
class GameBoardView extends StatefulWidget {
  const GameBoardView({super.key, required this.cellSize});

  final double cellSize;

  @override
  State<GameBoardView> createState() => _GameBoardViewState();
}

class _GameBoardViewState extends State<GameBoardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  void Function(double)? _onTick;

  final Map<String, Offset> _overrides = {};
  final Map<String, int> _displayHp = {};
  FloatingLabel? _floating;

  double get cell => widget.cellSize;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this);
    _anim.addListener(() {
      if (_onTick != null) setState(() => _onTick!(_anim.value));
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _tween(void Function(double) tick, Duration duration) async {
    _onTick = tick;
    _anim.duration = duration;
    await _anim.forward(from: 0);
    _onTick = null;
  }

  // ---- Animation routines ---------------------------------------------------

  Future<void> _playMove(Unit unit, List<Point<int>> path) async {
    if (path.isNotEmpty) {
      final points = <Point<int>>[unit.position, ...path];
      for (var i = 0; i < points.length - 1; i++) {
        final a = points[i];
        final b = points[i + 1];
        await _tween((t) {
          final dx = (a.x + (b.x - a.x) * t) * cell;
          final dy = (a.y + (b.y - a.y) * t) * cell;
          _overrides[unit.id] = Offset(dx, dy);
        }, const Duration(milliseconds: 130));
      }
      _overrides.remove(unit.id);
    }
    if (mounted) context.read<GameBloc>().add(const MovementAnimationCompleted());
  }

  Future<void> _playCombat(CombatResult result) async {
    _displayHp[result.attacker.id] =
        result.startingHp[result.attacker.id] ?? result.attacker.hp;
    _displayHp[result.defender.id] =
        result.startingHp[result.defender.id] ?? result.defender.hp;
    if (mounted) setState(() {});

    for (final strike in result.strikes) {
      await _lunge(strike.attacker, strike.defender);
      if (strike.hit) _displayHp[strike.defender.id] = strike.defenderHpAfter;

      final (text, color) = _strikeLabel(strike);
      await _tween((t) {
        _floating = FloatingLabel(
            tile: strike.defender.position, text: text, color: color, t: t);
      }, const Duration(milliseconds: 480));
      _floating = null;
    }

    _overrides.clear();
    _displayHp.clear();
    if (mounted) {
      setState(() {});
      context.read<GameBloc>().add(const CombatAnimationCompleted());
    }
  }

  /// The floating label (text + colour) for a single strike, including skill
  /// procs (Great Shield / Pierce / Silencer) with their localized names.
  (String, Color) _strikeLabel(CombatStrike strike) {
    final strings = GameStrings.current;
    if (!strike.hit) return ('Miss', Colors.white);
    if (strike.blocked) {
      return ('${strings.skillLabel(strike.defender.unitClass.skill)}!',
          Colors.lightBlueAccent);
    }
    if (strike.lethal) {
      return ('${strings.skillLabel(strike.attacker.unitClass.skill)}!',
          Colors.redAccent);
    }
    if (strike.crit) {
      return ('CRIT ${strike.damage}!', const Color(0xFFFFC107));
    }
    if (strike.pierced) {
      return ('${strings.skillLabel(strike.attacker.unitClass.skill)} -${strike.damage}',
          Colors.orangeAccent);
    }
    return ('-${strike.damage}', Colors.amberAccent);
  }

  Future<void> _lunge(Unit attacker, Unit defender) async {
    final base = Offset(attacker.x * cell, attacker.y * cell);
    var nx = (defender.x - attacker.x).toDouble();
    var ny = (defender.y - attacker.y).toDouble();
    final len = sqrt(nx * nx + ny * ny);
    if (len > 0) {
      nx /= len;
      ny /= len;
    }
    await _tween((t) {
      final k = sin(t * pi);
      _overrides[attacker.id] = base + Offset(nx, ny) * (cell * 0.3 * k);
    }, const Duration(milliseconds: 180));
    _overrides.remove(attacker.id);
  }

  // ---- Build ----------------------------------------------------------------

  void _onStateChanged(BuildContext context, GameState state) {
    if (state is UnitMoving) {
      _playMove(state.unit, state.path);
    } else if (state is EnemyMoving) {
      _playMove(state.unit, state.path);
    } else if (state is CombatAnimating) {
      _playCombat(state.result);
    } else if (state is HealAnimating) {
      _playHeal(state.target, state.amount);
    }
  }

  Future<void> _playHeal(Unit target, int amount) async {
    await _tween((t) {
      _floating = FloatingLabel(
          tile: target.position,
          text: '+$amount',
          color: const Color(0xFF7CF2A0),
          t: t);
    }, const Duration(milliseconds: 480));
    _floating = null;
    if (mounted) context.read<GameBloc>().add(const HealAnimationCompleted());
  }

  void _handleTap(GameBoard board, Offset localPosition) {
    final tile = Point<int>(
        (localPosition.dx / cell).floor(), (localPosition.dy / cell).floor());
    if (board.inBounds(tile)) {
      context.read<GameBloc>().add(TileTapped(tile));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      listener: _onStateChanged,
      builder: (context, state) {
        if (state is! BattleState) return const SizedBox.shrink();
        final board = state.board;

        final movementTiles =
            state is UnitSelected ? state.movementTiles : const <Point<int>>{};
        final attackTiles =
            state is UnitSelected ? state.attackTiles : const <Point<int>>{};
        final targets = switch (state) {
          ChoosingTarget(:final targets) => targets,
          ChoosingHealTarget(:final targets) => targets,
          _ => const <Unit>[],
        };
        final activeUnit = switch (state) {
          UnitSelected(:final unit) => unit,
          UnitActionMenu(:final unit) => unit,
          ChoosingTarget(:final unit) => unit,
          ChoosingHealTarget(:final unit) => unit,
          CombatPreviewState(:final unit) => unit,
          _ => null,
        };

        final width = board.width * cell;
        final height = board.height * cell;

        return GestureDetector(
          onTapUp: (details) => _handleTap(board, details.localPosition),
          child: CustomPaint(
            size: Size(width, height),
            painter: BoardPainter(
              board: board,
              cellSize: cell,
              movementTiles: movementTiles,
              attackTiles: attackTiles,
              activeUnit: activeUnit,
              targets: targets,
              pixelOverrides: _overrides,
              displayHp: _displayHp,
              floating: _floating,
              repaint: _anim,
            ),
          ),
        );
      },
    );
  }
}
