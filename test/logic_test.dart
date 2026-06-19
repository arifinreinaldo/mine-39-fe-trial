import 'dart:math';

import 'package:ember_tactics/data/models/game_board.dart';
import 'package:ember_tactics/data/models/terrain.dart';
import 'package:ember_tactics/data/models/tile.dart';
import 'package:ember_tactics/data/models/unit.dart';
import 'package:ember_tactics/data/models/unit_class.dart';
import 'package:ember_tactics/data/models/weapon.dart';
import 'package:ember_tactics/game/logic/combat.dart';
import 'package:ember_tactics/game/logic/enemy_ai.dart';
import 'package:ember_tactics/game/logic/movement.dart';
import 'package:ember_tactics/game/logic/promotion.dart';
import 'package:ember_tactics/game/logic/support.dart';
import 'package:flutter_test/flutter_test.dart';

GameBoard buildBoard(List<List<int>> terrain, List<Unit> units) {
  final tiles = <List<Tile>>[
    for (var y = 0; y < terrain.length; y++)
      [
        for (var x = 0; x < terrain[y].length; x++)
          Tile(position: Point(x, y), terrain: TerrainType.fromId(terrain[y][x]))
      ]
  ];
  return GameBoard(
    chapterName: 'test',
    width: terrain[0].length,
    height: terrain.length,
    tiles: tiles,
    units: units,
  );
}

Unit makeUnit({
  required String id,
  required UnitClass unitClass,
  required Faction faction,
  required Weapon weapon,
  required int x,
  required int y,
  int hp = 20,
  int strength = 5,
  int magic = 0,
  int skill = 5,
  int speed = 5,
  int luck = 0,
  int defense = 0,
  int resistance = 0,
  int con = 20,
  int? movement,
}) {
  return Unit(
    id: id,
    name: id,
    unitClass: unitClass,
    faction: faction,
    maxHp: hp,
    strength: strength,
    magic: magic,
    skill: skill,
    speed: speed,
    luck: luck,
    defense: defense,
    resistance: resistance,
    con: con,
    weapon: weapon,
    x: x,
    y: y,
    movement: movement,
  );
}

void main() {
  group('movement', () {
    test('flood fill reaches tiles within movement on open ground', () {
      final board = buildBoard(
        List.generate(5, (_) => List.filled(5, 0)),
        [],
      );
      final unit = makeUnit(
        id: 'a',
        unitClass: UnitClass.soldier,
        faction: Faction.player,
        weapon: Weapon.byId('ironLance'),
        x: 2,
        y: 2,
        movement: 4,
      );
      board.units.add(unit);

      final range = MovementSystem.movementRange(unit, board);
      expect(range.contains(const Point(2, 2)), isTrue);
      expect(range.contains(const Point(0, 2)), isTrue); // distance 2
      expect(range.contains(const Point(2, 0)), isTrue); // distance 2
    });

    test('forest costs more to enter, shrinking range', () {
      // Column x=1 is forest (cost 2). With 2 move, plains let you go 2 tiles
      // but forest eats the budget.
      final board = buildBoard([
        [0, 1, 0, 0],
      ], []);
      final unit = makeUnit(
        id: 'a',
        unitClass: UnitClass.soldier,
        faction: Faction.player,
        weapon: Weapon.byId('ironLance'),
        x: 0,
        y: 0,
        movement: 2,
      );
      board.units.add(unit);

      final range = MovementSystem.movementRange(unit, board);
      expect(range.contains(const Point(1, 0)), isTrue); // forest, cost 2 = ok
      expect(range.contains(const Point(2, 0)), isFalse); // would cost 3
    });

    test('water blocks passage', () {
      final board = buildBoard([
        [0, 4, 0],
      ], []);
      final unit = makeUnit(
        id: 'a',
        unitClass: UnitClass.soldier,
        faction: Faction.player,
        weapon: Weapon.byId('ironLance'),
        x: 0,
        y: 0,
        movement: 5,
      );
      board.units.add(unit);

      final range = MovementSystem.movementRange(unit, board);
      expect(range.contains(const Point(1, 0)), isFalse);
      expect(range.contains(const Point(2, 0)), isFalse);
    });
  });

  group('combat', () {
    test('weapon triangle shifts damage', () {
      final board = buildBoard([
        [0, 0],
      ], []);
      final sword = makeUnit(
        id: 'sword',
        unitClass: UnitClass.myrmidon,
        faction: Faction.player,
        weapon: Weapon.byId('ironSword'), // might 5
        x: 0,
        y: 0,
        strength: 5,
        defense: 0,
      );
      final axe = makeUnit(
        id: 'axe',
        unitClass: UnitClass.fighter,
        faction: Faction.enemy,
        weapon: Weapon.byId('ironAxe'), // might 8
        x: 1,
        y: 0,
        strength: 5,
        defense: 0,
      );
      board.units.addAll([sword, axe]);
      final combat = CombatSystem(board, rng: Random(1));

      // sword > axe: 5 - 0 + 5(might) + 1(advantage) = 11
      expect(combat.damage(sword, axe), 11);
      // axe < sword: 5 - 0 + 8(might) - 1(disadvantage) = 12
      expect(combat.damage(axe, sword), 12);
    });

    test('speed gap of 4+ grants a follow-up strike', () {
      final board = buildBoard([
        [0, 0],
      ], []);
      final fast = makeUnit(
        id: 'fast',
        unitClass: UnitClass.myrmidon,
        faction: Faction.player,
        weapon: Weapon.byId('ironSword'),
        x: 0,
        y: 0,
        speed: 10,
      );
      final slow = makeUnit(
        id: 'slow',
        unitClass: UnitClass.knight,
        faction: Faction.enemy,
        weapon: Weapon.byId('ironLance'),
        x: 1,
        y: 0,
        speed: 5,
      );
      board.units.addAll([fast, slow]);
      final combat = CombatSystem(board, rng: Random(1));

      expect(combat.doubles(fast, slow), isTrue);
      expect(combat.doubles(slow, fast), isFalse);
    });

    test('a lethal blow kills and records a casualty', () {
      final board = buildBoard([
        [0, 0],
      ], []);
      final attacker = makeUnit(
        id: 'atk',
        unitClass: UnitClass.fighter,
        faction: Faction.enemy,
        weapon: Weapon.byId('ironAxe'),
        x: 0,
        y: 0,
        strength: 20,
        skill: 50, // accuracy clamps to 100, so the strike always lands
      );
      final victim = makeUnit(
        id: 'vic',
        unitClass: UnitClass.soldier,
        faction: Faction.player,
        weapon: Weapon.byId('ironLance'),
        x: 1,
        y: 0,
        hp: 10,
        defense: 0,
        speed: 0,
        luck: 0,
      );
      board.units.addAll([attacker, victim]);
      final combat = CombatSystem(board, rng: Random(1));

      final result = combat.resolve(attacker, victim);
      expect(result.strikes.first.hit, isTrue);
      expect(victim.isAlive, isFalse);
      expect(result.casualties.map((u) => u.id), contains('vic'));
    });
  });

  group('ai', () {
    test('greedy AI chooses to attack an adjacent-reachable player', () {
      final board = buildBoard([
        [0, 0, 0, 0, 0],
      ], []);
      final enemy = makeUnit(
        id: 'e',
        unitClass: UnitClass.fighter,
        faction: Faction.enemy,
        weapon: Weapon.byId('ironAxe'),
        x: 0,
        y: 0,
        movement: 5,
      );
      final player = makeUnit(
        id: 'p',
        unitClass: UnitClass.soldier,
        faction: Faction.player,
        weapon: Weapon.byId('ironLance'),
        x: 3,
        y: 0,
      );
      board.units.addAll([enemy, player]);
      final combat = CombatSystem(board, rng: Random(1));

      final decision = EnemyAi(board, combat).decideFor(enemy);
      expect(decision.target, isNotNull);
      expect(decision.target!.id, 'p');
      // It should stop adjacent to the player (within weapon range 1).
      expect(MovementSystem.manhattan(decision.destination, player.position), 1);
    });
  });

  group('effectiveness & weight', () {
    test('bows triple their might against fliers', () {
      final board = buildBoard([
        [0, 0, 0],
      ], []);
      final archer = makeUnit(
        id: 'arc',
        unitClass: UnitClass.archer,
        faction: Faction.player,
        weapon: Weapon.byId('ironBow'), // might 6, effective vs flying
        x: 0,
        y: 0,
        strength: 8,
      );
      final flier = makeUnit(
        id: 'fly',
        unitClass: UnitClass.wyvernRider, // flying
        faction: Faction.enemy,
        weapon: Weapon.byId('ironLance'),
        x: 2,
        y: 0,
        defense: 5,
      );
      final footSoldier = makeUnit(
        id: 'foot',
        unitClass: UnitClass.soldier, // not flying
        faction: Faction.enemy,
        weapon: Weapon.byId('ironLance'),
        x: 1,
        y: 0,
        defense: 5,
      );
      board.units.addAll([archer, flier, footSoldier]);
      final combat = CombatSystem(board, rng: Random(1));

      // 8 + (6*3) - 5 = 21 against the flier; 8 + 6 - 5 = 9 against the footman.
      expect(combat.isEffective(archer, flier), isTrue);
      expect(combat.damage(archer, flier), 21);
      expect(combat.isEffective(archer, footSoldier), isFalse);
      expect(combat.damage(archer, footSoldier), 9);
    });

    test('a weapon heavier than CON lowers attack speed', () {
      final heavy = makeUnit(
        id: 'h',
        unitClass: UnitClass.fighter,
        faction: Faction.player,
        weapon: Weapon.byId('hammer'), // weight 12
        x: 0,
        y: 0,
        speed: 10,
        con: 8, // 12 - 8 = 4 penalty
      );
      expect(heavy.attackSpeed, 6);

      final strong = makeUnit(
        id: 's',
        unitClass: UnitClass.fighter,
        faction: Faction.player,
        weapon: Weapon.byId('hammer'),
        x: 0,
        y: 0,
        speed: 10,
        con: 14, // no penalty
      );
      expect(strong.attackSpeed, 10);
    });
  });

  group('stat caps', () {
    test('unpromoted classes clamp combat stats at 20', () {
      final u = makeUnit(
        id: 'u',
        unitClass: UnitClass.soldier,
        faction: Faction.player,
        weapon: Weapon.byId('ironLance'),
        x: 0,
        y: 0,
        strength: 25,
        speed: 24,
      );
      u.clampToCaps();
      expect(u.strength, 20);
      expect(u.speed, 20);
    });

    test('a General can exceed 20 defense (cap 30)', () {
      final g = makeUnit(
        id: 'g',
        unitClass: UnitClass.general,
        faction: Faction.player,
        weapon: Weapon.byId('ironLance'),
        x: 0,
        y: 0,
        defense: 35,
      );
      g.clampToCaps();
      expect(g.defense, 30);
    });
  });

  group('promotion', () {
    Unit promotable() {
      final u = makeUnit(
        id: 'm',
        unitClass: UnitClass.myrmidon,
        faction: Faction.player,
        weapon: Weapon.byId('swiftEdge'),
        x: 0,
        y: 0,
        strength: 10,
        defense: 5,
      );
      u.level = 10;
      u.heldItems.add('heroCrest');
      return u;
    }

    test('requires level 10 and the right seal', () {
      final u = promotable();

      u.level = 9;
      expect(PromotionSystem.optionsFor(u), isEmpty);

      u.level = 10;
      u.heldItems.clear();
      expect(PromotionSystem.optionsFor(u), isEmpty);

      u.heldItems.add('heroCrest');
      final options = PromotionSystem.optionsFor(u);
      expect(options.map((p) => p.to),
          containsAll([UnitClass.swordmaster, UnitClass.assassin]));
    });

    test('applying a branch swaps class, adds bonus, consumes the seal', () {
      final u = promotable();
      final toSwordmaster = u.unitClass.promotions
          .firstWhere((p) => p.to == UnitClass.swordmaster);

      PromotionSystem.apply(u, toSwordmaster);

      expect(u.unitClass, UnitClass.swordmaster);
      expect(u.level, 1);
      expect(u.heldItems, isEmpty);
      expect(u.strength, 12); // +2 from the bonus
      expect(u.defense, 7); // +2 from the bonus
    });
  });

  group('class skills', () {
    test('crit +15 skill raises crit chance', () {
      final board = buildBoard([
        [0, 0],
      ], []);
      final swordmaster = makeUnit(
        id: 'sm',
        unitClass: UnitClass.swordmaster, // has crit15
        faction: Faction.player,
        weapon: Weapon.byId('swiftEdge'), // crit 25
        x: 0,
        y: 0,
        skill: 10,
      );
      final target = makeUnit(
        id: 't',
        unitClass: UnitClass.soldier,
        faction: Faction.enemy,
        weapon: Weapon.byId('ironLance'),
        x: 1,
        y: 0,
      );
      board.units.addAll([swordmaster, target]);
      final combat = CombatSystem(board);
      // 25 (weapon) + 5 (skill/2) + 15 (crit15) - 0 (luck) = 45
      expect(combat.critChance(swordmaster, target), 45);
    });

    test('Pierce / ignore-defense raises damage', () {
      final board = buildBoard([
        [0, 0],
      ], []);
      final wyvern = makeUnit(
        id: 'wk',
        unitClass: UnitClass.wyvernKnight,
        faction: Faction.player,
        weapon: Weapon.byId('ironLance'),
        x: 0,
        y: 0,
        strength: 12,
      );
      final tank = makeUnit(
        id: 'tk',
        unitClass: UnitClass.knight,
        faction: Faction.enemy,
        weapon: Weapon.byId('ironLance'),
        x: 1,
        y: 0,
        defense: 10,
      );
      board.units.addAll([wyvern, tank]);
      final combat = CombatSystem(board);
      expect(combat.damage(wyvern, tank, ignoreDefense: true),
          greaterThan(combat.damage(wyvern, tank)));
    });

    test('Great Shield can negate an incoming hit', () {
      final board = buildBoard([
        [0, 0],
      ], []);
      final attacker = makeUnit(
        id: 'atk',
        unitClass: UnitClass.myrmidon,
        faction: Faction.player,
        weapon: Weapon.byId('ironSword'),
        x: 0,
        y: 0,
        strength: 12,
        skill: 50, // guarantees the hit lands
      );
      final general = makeUnit(
        id: 'gen',
        unitClass: UnitClass.general, // has Great Shield
        faction: Faction.enemy,
        weapon: Weapon.byId('ironLance'),
        x: 1,
        y: 0,
        hp: 30,
        defense: 8,
      );
      general.skill = 100; // forces the Great Shield proc
      board.units.addAll([attacker, general]);
      final combat = CombatSystem(board, rng: Random(3));

      final before = general.hp;
      final result = combat.resolve(attacker, general);
      expect(result.strikes.first.blocked, isTrue);
      expect(general.hp, before); // took no damage
    });

    test('Silencer can instantly fell the target', () {
      final board = buildBoard([
        [0, 0],
      ], []);
      final assassin = makeUnit(
        id: 'asn',
        unitClass: UnitClass.assassin, // has Silencer
        faction: Faction.player,
        weapon: Weapon.byId('ironSword'),
        x: 0,
        y: 0,
        skill: 200, // forces the hit and the (skill/2)% proc
      );
      final victim = makeUnit(
        id: 'vic',
        unitClass: UnitClass.soldier,
        faction: Faction.enemy,
        weapon: Weapon.byId('ironLance'),
        x: 1,
        y: 0,
        hp: 20,
        defense: 30, // normal damage would be ~0, so only Silencer can kill
      );
      board.units.addAll([assassin, victim]);
      final combat = CombatSystem(board, rng: Random(5));

      final result = combat.resolve(assassin, victim);
      expect(result.strikes.first.lethal, isTrue);
      expect(victim.isAlive, isFalse);
    });
  });

  group('support / healing', () {
    test('staff restores base + magic and clamps to max HP', () {
      final board = buildBoard([
        [0, 0],
      ], []);
      final cleric = makeUnit(
        id: 'c',
        unitClass: UnitClass.cleric,
        faction: Faction.player,
        weapon: Weapon.byId('healStaff'), // heal 10
        x: 0,
        y: 0,
        magic: 7,
      );
      final ally = makeUnit(
        id: 'a',
        unitClass: UnitClass.knight,
        faction: Faction.player,
        weapon: Weapon.byId('ironLance'),
        x: 1,
        y: 0,
        hp: 30,
      );
      ally.hp = 10;
      board.units.addAll([cleric, ally]);

      expect(cleric.weapon.isStaff, isTrue);
      expect(HealSystem.staffHealAmount(cleric), 17); // 10 + magic 7
      expect(HealSystem.heal(ally, 17), 17);
      expect(ally.hp, 27);
      expect(HealSystem.heal(ally, 100), 3); // clamped to 30
      expect(ally.hp, 30);
    });

    test('heal targets are only wounded, in-range allies', () {
      final board = buildBoard([
        [0, 0],
        [0, 0],
      ], []);
      final cleric = makeUnit(
        id: 'c',
        unitClass: UnitClass.cleric,
        faction: Faction.player,
        weapon: Weapon.byId('healStaff'),
        x: 0,
        y: 0,
      );
      final hurt = makeUnit(
        id: 'h',
        unitClass: UnitClass.knight,
        faction: Faction.player,
        weapon: Weapon.byId('ironLance'),
        x: 1,
        y: 0,
        hp: 30,
      )..hp = 10;
      final fullHp = makeUnit(
        id: 'f',
        unitClass: UnitClass.archer,
        faction: Faction.player,
        weapon: Weapon.byId('ironBow'),
        x: 0,
        y: 1,
      );
      final woundedEnemy = makeUnit(
        id: 'e',
        unitClass: UnitClass.fighter,
        faction: Faction.enemy,
        weapon: Weapon.byId('ironAxe'),
        x: 1,
        y: 1,
        hp: 20,
      )..hp = 5;
      board.units.addAll([cleric, hurt, fullHp, woundedEnemy]);

      expect(HealSystem.healTargets(cleric, board).map((u) => u.id), ['h']);
    });

    test('vulnerary needs the item and a wound', () {
      final board = buildBoard([
        [0],
      ], []);
      final u = makeUnit(
        id: 'u',
        unitClass: UnitClass.myrmidon,
        faction: Faction.player,
        weapon: Weapon.byId('ironSword'),
        x: 0,
        y: 0,
        hp: 20,
      );
      board.units.add(u);

      expect(HealSystem.canUseVulnerary(u), isFalse); // no item
      u.heldItems.add(HealSystem.vulnerary);
      expect(HealSystem.canUseVulnerary(u), isFalse); // full HP
      u.hp = 10;
      expect(HealSystem.canUseVulnerary(u), isTrue);
      expect(HealSystem.heal(u, HealSystem.vulneraryHeal), 10);
      expect(u.hp, 20);
    });
  });
}
