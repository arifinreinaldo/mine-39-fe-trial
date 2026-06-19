import 'dart:math';

import '../../data/models/game_board.dart';
import '../../data/models/unit.dart';
import '../../data/models/weapon.dart';
import 'movement.dart';

/// A single blow within a combat exchange — used to drive the hit-by-hit
/// animation and a future battle log.
class CombatStrike {
  CombatStrike({
    required this.attacker,
    required this.defender,
    required this.hit,
    required this.crit,
    required this.damage,
    required this.defenderHpAfter,
    required this.defenderDied,
  });

  final Unit attacker;
  final Unit defender;
  final bool hit;
  final bool crit;
  final int damage;
  final int defenderHpAfter;
  final bool defenderDied;
}

/// The full resolution of one combat: the ordered strikes, who died, and the
/// HP each combatant started with (so the UI can animate bars down from the
/// pre-combat value even though the model already holds the final HP).
class CombatResult {
  CombatResult({
    required this.attacker,
    required this.defender,
    required this.strikes,
    required this.casualties,
    required this.startingHp,
  });

  final Unit attacker;
  final Unit defender;
  final List<CombatStrike> strikes;
  final List<Unit> casualties;
  final Map<String, int> startingHp;
}

/// A non-committal look at what an attack would do, shown before the player
/// confirms.
class CombatForecast {
  CombatForecast({
    required this.attacker,
    required this.defender,
    required this.attackerDamage,
    required this.attackerHit,
    required this.attackerCrit,
    required this.attackerDoubles,
    required this.defenderCanCounter,
    required this.defenderDamage,
    required this.defenderHit,
    required this.defenderCrit,
    required this.defenderDoubles,
    required this.attackerEffective,
    required this.defenderEffective,
  });

  final Unit attacker;
  final Unit defender;
  final int attackerDamage;
  final int attackerHit;
  final int attackerCrit;
  final bool attackerDoubles;
  final bool defenderCanCounter;
  final int defenderDamage;
  final int defenderHit;
  final int defenderCrit;
  final bool defenderDoubles;
  final bool attackerEffective;
  final bool defenderEffective;
}

/// Combat math and resolution.
///
/// Formulas (extending the researched base with weapon hit + the triangle):
///   hit    = wHit + skill*2 + luck~/2 + triHit - (def.spd*2 + def.luck~/2 + terrainAvoid)
///   damage = (magic ? mag-res : str-def) + might + triMight - terrainDef
///   crit   = wCrit + skill~/2 - def.luck
///   double = attacker.speed - defender.speed >= 4   (a second strike)
class CombatSystem {
  CombatSystem(this.board, {Random? rng}) : _rng = rng ?? Random();

  final GameBoard board;
  final Random _rng;

  int hitChance(Unit a, Unit d) {
    final tri = Weapon.triangle(a.weapon.type, d.weapon.type);
    final triHit = switch (tri) {
      TriangleResult.advantage => 15,
      TriangleResult.disadvantage => -15,
      TriangleResult.neutral => 0,
    };
    final accuracy = a.weapon.hit + a.skill * 2 + a.luck ~/ 2 + triHit;
    final avoid = d.speed * 2 + d.luck ~/ 2 + board.tileAt(d.position).avoidBonus;
    return (accuracy - avoid).clamp(0, 100);
  }

  /// Whether [a]'s weapon is "effective" (triple might) against [d]'s body type.
  bool isEffective(Unit a, Unit d) =>
      a.weapon.effectiveVs.any(d.unitClass.traits.contains);

  int damage(Unit a, Unit d) {
    final tri = Weapon.triangle(a.weapon.type, d.weapon.type);
    final triMight = switch (tri) {
      TriangleResult.advantage => 1,
      TriangleResult.disadvantage => -1,
      TriangleResult.neutral => 0,
    };
    final might =
        a.weapon.might * (isEffective(a, d) ? Weapon.effectiveMultiplier : 1);
    final base = a.weapon.isMagic ? a.magic - d.resistance : a.strength - d.defense;
    final raw = base + might + triMight - board.tileAt(d.position).defenseBonus;
    return raw.clamp(0, 99);
  }

  int critChance(Unit a, Unit d) =>
      (a.weapon.crit + a.skill ~/ 2 - d.luck).clamp(0, 100);

  /// Doubling uses *attack speed* (speed minus the weight-over-CON penalty),
  /// so heavy weapons can cost a unit its follow-up.
  bool doubles(Unit a, Unit d) => a.attackSpeed - d.attackSpeed >= 4;

  bool canCounter(Unit defender, Unit attacker) =>
      defender.isAlive &&
      defender.weapon.reaches(MovementSystem.manhattan(defender.position, attacker.position));

  CombatForecast forecast(Unit a, Unit d) {
    final dist = MovementSystem.manhattan(a.position, d.position);
    final defCanCounter = d.weapon.reaches(dist);
    return CombatForecast(
      attacker: a,
      defender: d,
      attackerDamage: damage(a, d),
      attackerHit: hitChance(a, d),
      attackerCrit: critChance(a, d),
      attackerDoubles: doubles(a, d),
      attackerEffective: isEffective(a, d),
      defenderEffective: defCanCounter && isEffective(d, a),
      defenderCanCounter: defCanCounter,
      defenderDamage: defCanCounter ? damage(d, a) : 0,
      defenderHit: defCanCounter ? hitChance(d, a) : 0,
      defenderCrit: defCanCounter ? critChance(d, a) : 0,
      defenderDoubles: defCanCounter && doubles(d, a),
    );
  }

  /// Resolves combat, mutating HP / [Unit.isAlive] on the participants and
  /// returning the blow-by-blow result.
  CombatResult resolve(Unit attacker, Unit defender) {
    final strikes = <CombatStrike>[];
    final startingHp = {attacker.id: attacker.hp, defender.id: defender.hp};

    void strike(Unit atk, Unit def) {
      if (!atk.isAlive || !def.isAlive) return;
      final didHit = _rng.nextInt(100) < hitChance(atk, def);
      var didCrit = false;
      var dmg = 0;
      if (didHit) {
        didCrit = _rng.nextInt(100) < critChance(atk, def);
        dmg = damage(atk, def);
        if (didCrit) dmg *= 3;
        def.hp -= dmg;
        def.clampHp();
      }
      strikes.add(CombatStrike(
        attacker: atk,
        defender: def,
        hit: didHit,
        crit: didCrit,
        damage: dmg,
        defenderHpAfter: def.hp,
        defenderDied: !def.isAlive,
      ));
    }

    // 1) Attacker strikes. 2) Defender counters if in range. 3 & 4) Either side
    // that is fast enough lands a follow-up.
    strike(attacker, defender);
    if (defender.isAlive && canCounter(defender, attacker)) {
      strike(defender, attacker);
    }
    if (attacker.isAlive && defender.isAlive && doubles(attacker, defender)) {
      strike(attacker, defender);
    }
    if (attacker.isAlive &&
        defender.isAlive &&
        canCounter(defender, attacker) &&
        doubles(defender, attacker)) {
      strike(defender, attacker);
    }

    final casualties = <Unit>[
      if (!attacker.isAlive) attacker,
      if (!defender.isAlive) defender,
    ];

    return CombatResult(
      attacker: attacker,
      defender: defender,
      strikes: strikes,
      casualties: casualties,
      startingHp: startingHp,
    );
  }
}
