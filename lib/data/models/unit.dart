import 'dart:math';

import 'unit_class.dart';
import 'weapon.dart';

/// Which side a unit fights for. NPCs (green units) are modelled for
/// completeness though the first chapter only uses player and enemy.
enum Faction { player, enemy, npc }

/// Used for the gender-split stat caps and the rescue (Aid) formula.
enum Gender { male, female }

/// A combat unit. [strength] feeds physical damage and [magic] feeds magical
/// damage (the equipped weapon decides which). [con] (constitution) gates
/// weapon weight and rescue capacity.
///
/// Permadeath rule: a fallen unit is never removed from the roster — [isAlive]
/// is flipped to false so the unit stays in the chapter data but no longer
/// occupies the board.
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
    this.gender = Gender.male,
    this.con = 8,
    int? movement,
    this.level = 1,
    this.exp = 0,
    List<String>? heldItems,
  })  : hp = maxHp,
        movement = movement ?? unitClass.baseMove,
        heldItems = heldItems ?? <String>[];

  final String id;
  final String name;
  UnitClass unitClass;
  final Faction faction;
  final Gender gender;

  int maxHp;
  int hp;
  int strength;
  int magic;
  int skill;
  int speed;
  int luck;
  int defense;
  int resistance;
  int con;
  int movement;
  int level;
  int exp;
  Weapon weapon;

  /// Consumable items the unit carries (e.g. promotion seals), by catalogue id.
  final List<String> heldItems;

  /// Grid position (column = x, row = y).
  int x;
  int y;

  bool hasMoved = false;
  bool hasActed = false;
  bool isAlive = true;

  Point<int> get position => Point(x, y);

  /// The stat that feeds damage for the currently-equipped weapon.
  int get attackPower => weapon.isMagic ? magic : strength;

  /// Effective speed for the double-attack check: weapon weight above your CON
  /// slows you down.
  int get attackSpeed {
    final penalty = weapon.weight - con;
    return penalty > 0 ? speed - penalty : speed;
  }

  /// Rescue capacity (Aid): mounted/flying units use 25−CON (M) / 20−CON (F),
  /// foot units use CON−1.
  int get aid {
    if (unitClass.isMounted || unitClass.isFlier) {
      return (gender == Gender.male ? 25 : 20) - con;
    }
    return con - 1;
  }

  void clampHp() {
    if (hp > maxHp) hp = maxHp;
    if (hp <= 0) {
      hp = 0;
      isAlive = false;
    }
  }

  /// Clamp every stat to this class's caps (60 HP / 30 Luck universally, plus
  /// the class-specific combat-stat caps and the CON cap from body type).
  void clampToCaps() {
    final caps = unitClass.caps;
    if (maxHp > caps.hp) maxHp = caps.hp;
    if (strength > caps.str) strength = caps.str;
    if (magic > caps.mag) magic = caps.mag;
    if (skill > caps.skl) skill = caps.skl;
    if (speed > caps.spd) speed = caps.spd;
    if (defense > caps.def) defense = caps.def;
    if (resistance > caps.res) resistance = caps.res;
    if (luck > caps.luck) luck = caps.luck;
    if (con > unitClass.conCap) con = unitClass.conCap;
    if (hp > maxHp) hp = maxHp;
  }

  void resetForNewTurn() {
    hasMoved = false;
    hasActed = false;
  }
}
