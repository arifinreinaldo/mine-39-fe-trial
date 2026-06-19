# Ember Tactics

A **touch-first, turn-based tactical RPG** prototype built with **Flutter + BLoC +
`CustomPainter`**. It's an *original* game inspired by the grid-tactics genre
(class-based units, a weapon triangle, terrain bonuses, permadeath, player/enemy
phases). It contains **no assets, names, art, music, maps, or story from any
existing game** — only the genre's (uncopyrightable) mechanics, re-implemented
from scratch.

> Why raw Flutter instead of a game engine like Flame? A tactical RPG is
> *event-driven* (tap a unit, tap a destination, confirm combat, AI responds) —
> there's no continuous real-time loop. `CustomPainter` draws the board and a
> BLoC holds all game state, so a game engine would add complexity with no
> benefit.

## Input: ported from GBA buttons to touch

The original genre is played with a D-pad cursor + A/B/L/R buttons. Here every
interaction is **direct touch**, funnelled through a single `TileTapped` event
that the BLoC interprets by context:

| Original (buttons)            | This prototype (touch)                          |
| ----------------------------- | ----------------------------------------------- |
| Move cursor with D-pad        | (no cursor) tap the tile directly               |
| `A` on your unit              | tap a blue unit → movement/attack range shows   |
| Move cursor + `A` on a tile   | tap a highlighted tile → unit glides there      |
| `A` → Attack → pick target    | tap **Attack** → tap a ringed enemy → forecast  |
| `A` to confirm the forecast   | tap **Attack** in the forecast card             |
| `B` to cancel / back out      | **Cancel/Back** buttons                         |
| `Start` to end turn           | **End Turn** in the app bar                     |

## The six core systems (all implemented)

1. **Grid map** — `GameBoard` of `Tile`s with terrain (plain/forest/mountain/
   fort/water/wall), each with move cost, defense, and avoid bonuses.
2. **Units & classes** — full stat block (`str/mag/skill/spd/lck/def/res/mov`),
   classes, weapons. **Permadeath**: a fallen unit is flagged `isAlive = false`
   and stays in the roster, never deleted.
3. **Movement & range** — cost-aware flood fill (Dijkstra, so variable terrain
   cost is handled correctly), plus a second pass for attack range.
4. **Turn / phase manager** — `GameBloc` state machine: player phase →
   (units act) → enemy phase (AI) → repeat.
5. **Combat resolution** — hit/damage/crit + the `spd − spd ≥ 4` double rule +
   the **weapon triangle** (sword > axe > lance). Shown as a battle forecast
   before you commit.
6. **Enemy AI** — greedy: reach-and-attack the best-scoring target, otherwise
   advance toward the nearest player.

Plus lightweight **animation** (units glide along their path, attacker lunge,
floating damage/crit/miss numbers, HP bars), a fit-to-screen responsive board,
and a victory/defeat screen.

## Architecture

```
lib/
  data/
    models/            # pure Dart, no Flutter: terrain, tile, weapon,
                       # unit_class, unit, game_board
    repositories/      # chapter_repository.dart — loads JSON maps
  game/
    logic/             # movement (BFS/Dijkstra), combat, enemy_ai  (pure Dart)
    bloc/              # game_event, game_state, game_bloc (source of truth)
    painters/          # board_painter.dart (CustomPainter)
    widgets/           # game_board_view (touch + animation), panels
  screens/
    battle_screen.dart
  main.dart
assets/maps/chapter_1.json   # the map + unit placements (data-driven)
test/logic_test.dart         # movement / combat / AI unit tests
```

Maps and units are **data**, not code — edit `assets/maps/chapter_1.json`
(`tileLegend` documents the terrain ids) to change the battlefield or roster.

## Run it

```bash
flutter pub get
flutter run -d chrome      # or: an Android/iOS device/emulator, or desktop
```

A release web build is produced with `flutter build web` (output in
`build/web/`).

## Verified

- `flutter analyze` → **No issues found**
- `flutter test` → **7/7 passing** (movement flood-fill, terrain cost, water
  blocking, weapon triangle, doubling, lethal combat, AI targeting)
- `flutter build web --release` → builds successfully

## Deliberately left as next steps

- **Promotion / richer leveling** — level-up is currently minimal and
  deterministic (`GameBloc._levelUp`); a full version would roll per-stat growth.
- **Fog of war, healing/staff units, items & inventory, ranged magic trinity.**
- **Multiple chapters & a dialogue/story layer.**
- **Pinch-zoom / camera pan** (board currently auto-fits the screen).
- **Sprite art** — units are drawn as labelled tokens; swap `BoardPainter` for
  sprite sheets (this is the one place a tool like Flame could later help).
