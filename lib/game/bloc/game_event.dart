import 'dart:math';

import '../../data/models/unit_class.dart';

/// Player-chosen action from the post-move menu.
enum BattleAction { attack, heal, item, promote, wait }

/// Events fed into [GameBloc].
///
/// Touch input is intentionally funnelled through a single [TileTapped] event:
/// the bloc interprets a tap based on the current state (select a unit, choose a
/// destination, pick a target). This is the GBA button scheme (cursor + A/B)
/// re-expressed as direct touch.
sealed class GameEvent {
  const GameEvent();
}

class GameStarted extends GameEvent {
  const GameStarted(this.chapterAsset);
  final String chapterAsset;
}

class TileTapped extends GameEvent {
  const TileTapped(this.position);
  final Point<int> position;
}

class ActionSelected extends GameEvent {
  const ActionSelected(this.action);
  final BattleAction action;
}

class CombatConfirmed extends GameEvent {
  const CombatConfirmed();
}

/// The player picked a branch in the promotion menu.
class PromotionChosen extends GameEvent {
  const PromotionChosen(this.promotion);
  final Promotion promotion;
}

class SelectionCancelled extends GameEvent {
  const SelectionCancelled();
}

class EndTurnRequested extends GameEvent {
  const EndTurnRequested();
}

/// Sent by the view once a movement glide animation has finished playing.
class MovementAnimationCompleted extends GameEvent {
  const MovementAnimationCompleted();
}

/// Sent by the view once a combat (strike-by-strike) animation has finished.
class CombatAnimationCompleted extends GameEvent {
  const CombatAnimationCompleted();
}

/// Sent by the view once a heal effect has finished animating.
class HealAnimationCompleted extends GameEvent {
  const HealAnimationCompleted();
}

/// Internal: drive the enemy phase one unit at a time.
class AdvanceAiRequested extends GameEvent {
  const AdvanceAiRequested();
}
