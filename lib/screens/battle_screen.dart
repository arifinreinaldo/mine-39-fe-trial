import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/campaign.dart';
import '../data/repositories/chapter_repository.dart';
import '../game/bloc/game_bloc.dart';
import '../game/bloc/game_event.dart';
import '../game/bloc/game_state.dart';
import '../game/widgets/action_menu.dart';
import '../game/widgets/combat_preview_panel.dart';
import '../game/widgets/game_board_view.dart';
import '../game/widgets/promotion_menu.dart';
import '../game/widgets/unit_info_panel.dart';
import '../l10n/game_strings.dart';

/// Hosts the [GameBloc] for one campaign run and lays the touch UI over the
/// board. Owns the chapter index so it can advance to the next chapter on a win.
class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key, this.chapterIndex = 0});

  final int chapterIndex;

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  late final GameBloc _bloc;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.chapterIndex;
    _bloc = GameBloc(repository: const ChapterRepository())
      ..add(GameStarted(Campaign.chapters[_index]));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _restartChapter() => _bloc.add(GameStarted(Campaign.chapters[_index]));

  void _nextChapter() {
    setState(() => _index++);
    _bloc.add(GameStarted(Campaign.chapters[_index]));
  }

  void _cycleLocale() {
    final all = GameStrings.all;
    final next = all[(all.indexOf(GameStrings.current) + 1) % all.length];
    setState(() => GameStrings.current = next);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(value: _bloc, child: _scaffold());
  }

  Widget _scaffold() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C22),
      appBar: AppBar(
        title: BlocBuilder<GameBloc, GameState>(
          builder: (context, state) => Text(
              state is BattleState ? state.board.chapterName : 'Ember Tactics',
              style: const TextStyle(fontSize: 16)),
        ),
        actions: [
          IconButton(
            tooltip: 'Language: ${GameStrings.current.localeCode.toUpperCase()}',
            icon: const Icon(Icons.translate),
            onPressed: _cycleLocale,
          ),
          BlocBuilder<GameBloc, GameState>(
            builder: (context, state) {
              final isPlayerTurn =
                  state is PlayerTurnIdle || state is UnitSelected;
              return TextButton(
                onPressed: isPlayerTurn
                    ? () => context.read<GameBloc>().add(const EndTurnRequested())
                    : null,
                child: Text(GameStrings.current.ui('endTurn')),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<GameBloc, GameState>(
        listener: (context, state) {
          if (state is EnemyTurnBanner) {
            _flash(context, GameStrings.current.ui('enemyPhase'));
          } else if (state is PlayerTurnIdle && state.showPhaseBanner) {
            _flash(context, GameStrings.current.ui('playerPhase'));
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
                  _hud(context, state),
                  _overlays(context, state),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _hud(BuildContext context, GameState state) {
    final strings = GameStrings.current;
    final phase = _phaseLabel(state);
    return Positioned(
      top: 6,
      right: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _chip('${strings.ui('turn')} ${_bloc.turn}  ·  $phase'),
          const SizedBox(height: 4),
          _chip(strings.ui('objective'), subtle: true),
        ],
      ),
    );
  }

  Widget _chip(String text, {bool subtle = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: subtle ? 0.45 : 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: subtle ? 11 : 13,
              color: subtle ? Colors.white70 : Colors.white)),
    );
  }

  Widget _overlays(BuildContext context, BattleState state) {
    final activeUnit = switch (state) {
      UnitSelected(:final unit) => unit,
      UnitActionMenu(:final unit) => unit,
      ChoosingTarget(:final unit) => unit,
      ChoosingPromotion(:final unit) => unit,
      CombatPreviewState(:final unit) => unit,
      _ => null,
    };
    final strings = GameStrings.current;

    return Stack(
      children: [
        if (activeUnit != null)
          Positioned(left: 8, top: 8, child: UnitInfoPanel(unit: activeUnit)),
        if (state is UnitActionMenu)
          _bottom(ActionMenu(
              canAttack: state.attackableTargets.isNotEmpty,
              canPromote: state.canPromote)),
        if (state is ChoosingTarget)
          _bottom(_hintBar(context, strings.ui('selectTargetHint'))),
        if (state is CombatPreviewState)
          _bottom(CombatPreviewPanel(forecast: state.forecast)),
        if (state is ChoosingPromotion) _bottom(PromotionMenu(state: state)),
        if (state is PlayerTurnIdle)
          _bottom(_Hint(strings.ui('tapUnitHint'))),
        if (state is BattleOver) _gameOver(context, state.playerWon),
      ],
    );
  }

  Widget _bottom(Widget child) => Align(
        alignment: Alignment.bottomCenter,
        child: Padding(padding: const EdgeInsets.only(bottom: 16), child: child),
      );

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
              onPressed: () =>
                  context.read<GameBloc>().add(const SelectionCancelled()),
              child: Text(GameStrings.current.ui('cancel')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gameOver(BuildContext context, bool playerWon) {
    final strings = GameStrings.current;
    final lastChapter = !Campaign.hasNext(_index);
    final title = !playerWon
        ? strings.ui('defeat')
        : (lastChapter ? strings.ui('campaignComplete') : strings.ui('victory'));
    final titleColor =
        playerWon ? const Color(0xFF5FD068) : const Color(0xFFD24B4B);

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: titleColor)),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (playerWon && !lastChapter)
                    ElevatedButton.icon(
                      onPressed: _nextChapter,
                      icon: const Icon(Icons.skip_next),
                      label: Text(strings.ui('nextChapter')),
                    )
                  else if (!playerWon)
                    ElevatedButton.icon(
                      onPressed: _restartChapter,
                      icon: const Icon(Icons.refresh),
                      label: Text(strings.ui('playAgain')),
                    ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.home),
                    label: Text(strings.ui('toTitle')),
                  ),
                ],
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
        EnemyTurnBanner() || EnemyMoving() => GameStrings.current.ui('enemyPhase'),
        CombatAnimating(:final isEnemyPhase) => isEnemyPhase
            ? GameStrings.current.ui('enemyPhase')
            : GameStrings.current.ui('playerPhase'),
        BattleState() => GameStrings.current.ui('playerPhase'),
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
