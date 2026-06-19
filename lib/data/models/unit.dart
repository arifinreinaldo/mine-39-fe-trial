import 'dart:math';

import 'unit_class.dart';
import 'weapon.dart';

/// Which side a unit fights for. NPCs (green units) are modelled for
/// completeness though the first chapter only uses player and enemy.
enum Faction { player, enemy, npc }

/// A combat unit. Stats follow the classic spread; [strength] feeds physical
/// damage and [magic] feeds magical damage (chosen by the equipped weapon).
///
/// Permadeath rule: a fallen unit is never removed from the roster — [isAlive]
/// is flipped to false so the unit stays in the chapter data (and could be
/// reported in an after-action screen) but no longer occupies the board.
class Unit {
  Unit({
    required this.id,
    required this.name,
    required this.unitClass,
    required this.faction,
    required this.maxHp,
    required this.strength,
    required this.magic,
    required this.skill,
    required this.speed,
    required this.luck,
    required this.defense,
    required this.resistance,
    required this.weapon,
    required this.x,
    required this.y,
    int? movement,
    this.level = 1,
    this.exp = 0,
  })  : hp = maxHp,
        movement = movement ?? unitClass.baseMove;

  final String id;
  final String name;
  final UnitClass unitClass;
  final Faction faction;

  int maxHp;
  int hp;
  int strength;
  int magic;
  int skill;
  int speed;
  int luck;
  int defense;
  int resistance;
  int movement;
  int level;
  int exp;
  Weapon weapon;

  /// Grid position (column = x, row = y).
  int x;
  int y;

  /// Per-turn flags. [hasMoved] is set once a unit relocates; [hasActed] is set
  /// once it has fully finished its turn (after attacking or waiting).
  bool hasMoved = false;
  bool hasActed = false;

  bool isAlive = true;

  Point<int> get position => Point(x, y);

  /// The stat that feeds damage for the currently-equipped weapon.
  int get attackPower => weapon.isMagic ? magic : strength;

  void clampHp() {
    if (hp > maxHp) hp = maxHp;
    if (hp <= 0) {
      hp = 0;
      isAlive = false;
    }
  }

  void resetForNewTurn() {
    hasMoved = false;
    hasActed = false;
  }
}
