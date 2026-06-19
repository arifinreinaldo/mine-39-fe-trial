import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/chapter_repository.dart';
import '../game/bloc/game_bloc.dart';
import '../game/bloc/game_event.dart';
import '../game/bloc/game_state.dart';
import '../game/widgets/action_menu.dart';
import '../game/widgets/combat_preview_panel.dart';
import '../game/widgets/game_board_view.dart';
import '../game/widgets/unit_info_panel.dart';

/// Hosts the [GameBloc] and lays the touch UI over the board.
class BattleScreen extends StatelessWidget {
  const BattleScreen({super.key, this.chapterAsset = 'assets/maps/chapter_1.json'});

  final String chapterAsset;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GameBloc(repository: const ChapterRepository())
        ..add(GameStarted(chapterAsset)),
      child: _BattleScaffold(chapterAsset: chapterAsset),
    );
  }
}

class _BattleScaffold extends StatelessWidget {
  const _BattleScaffold({required this.chapterAsset});

  final String chapterAsset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C22),
      appBar: AppBar(
        title: const Text('Ember Tactics'),
        actions: [
          BlocBuilder<GameBloc, GameState>(
            builder: (context, state) {
              final isPlayerTurn = state is PlayerTurnIdle || state is UnitSelected;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    Chip(label: Text(_phaseLabel(state))),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: isPlayerTurn
                          ? () => context.read<GameBloc>().add(const EndTurnRequested())
                          : null,
                      child: const Text('End Turn'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<GameBloc, GameState>(
        listener: (context, state) {
          if (state is EnemyTurnBanner) {
            _flash(context, 'Enemy Phase');
          } else if (state is PlayerTurnIdle && state.showPhaseBanner) {
            _flash(context, 'Player Phase');
          }
        },
        builder: (context, state) {
          if (state is GameLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is GameError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(state.message, textAlign: TextAlign.center),
              ),
            );
          }
          if (state is! BattleState) return const SizedBox.shrink();

          final board = state.board;
          return LayoutBuilder(
            builder: (context, constraints) {
              final cell = min(
                constraints.maxWidth / board.width,
                constraints.maxHeight / board.height,
              );
              return Stack(
                children: [
                  Positioned.fill(
                    child: Center(child: GameBoardView(cellSize: cell)),
                  ),
                  _buildOverlays(context, state),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOverlays(BuildContext context, BattleState state) {
    final activeUnit = switch (state) {
      UnitSelected(:final unit) => unit,
      UnitActionMenu(:final unit) => unit,
      ChoosingTarget(:final unit) => unit,
      CombatPreviewState(:final unit) => unit,
      _ => null,
    };

    return Stack(
      children: [
        if (activeUnit != null)
          Positioned(
            left: 8,
            top: 8,
            child: UnitInfoPanel(unit: activeUnit),
          ),
        if (state is UnitActionMenu)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ActionMenu(canAttack: state.attackableTargets.isNotEmpty),
            ),
          ),
        if (state is ChoosingTarget)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _hintBar(context, 'Tap a highlighted enemy to attack'),
            ),
          ),
        if (state is CombatPreviewState)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CombatPreviewPanel(forecast: state.forecast),
            ),
          ),
        if (state is PlayerTurnIdle)
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: _Hint('Tap one of your (blue) units to act'),
            ),
          ),
        if (state is BattleOver) _gameOver(context, state.playerWon),
      ],
    );
  }

  Widget _hintBar(BuildContext context, String text) {
    return Card(
      color: Colors.black.withValues(alpha: 0.8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => context.read<GameBloc>().add(const SelectionCancelled()),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gameOver(BuildContext context, bool playerWon) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                playerWon ? 'Victory!' : 'Defeat',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: playerWon ? const Color(0xFF5FD068) : const Color(0xFFD24B4B),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    context.read<GameBloc>().add(GameStarted(chapterAsset)),
                icon: const Icon(Icons.refresh),
                label: const Text('Play Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _flash(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(text, textAlign: TextAlign.center),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
        width: 200,
      ));
  }

  String _phaseLabel(GameState state) => switch (state) {
        EnemyTurnBanner() || EnemyMoving() => 'Enemy Phase',
        CombatAnimating(:final isEnemyPhase) =>
          isEnemyPhase ? 'Enemy Phase' : 'Player Phase',
        BattleState() => 'Player Phase',
        _ => '',
      };
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Card(
        color: Colors.black.withValues(alpha: 0.55),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(text, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}
