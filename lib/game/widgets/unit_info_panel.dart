import 'package:flutter/material.dart';

import '../../data/models/unit.dart';
import '../../data/models/unit_class.dart';
import '../../l10n/game_strings.dart';

/// Compact read-out of the active unit's stats, shown while it is selected.
class UnitInfoPanel extends StatelessWidget {
  const UnitInfoPanel({super.key, required this.unit});

  final Unit unit;

  @override
  Widget build(BuildContext context) {
    final strings = GameStrings.current;
    final traits = unit.unitClass.traits
        .map((t) => strings.traitLabel(t))
        .join(' · ');

    return Card(
      color: Colors.black.withValues(alpha: 0.75),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${unit.name}  ·  ${strings.className(unit.unitClass)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Text('HP  ${unit.hp}/${unit.maxHp}   Lv ${unit.level}'
                '${traits.isNotEmpty ? '   [$traits]' : ''}',
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 2,
              children: [
                _stat('Str', unit.strength),
                _stat('Mag', unit.magic),
                _stat('Skl', unit.skill),
                _stat('Spd', unit.speed),
                _stat('Lck', unit.luck),
                _stat('Def', unit.defense),
                _stat('Res', unit.resistance),
                _stat('Con', unit.con),
                _stat('Mov', unit.movement),
              ],
            ),
            const SizedBox(height: 6),
            Text(
                '${unit.weapon.name} · ${strings.weaponTypeLabel(unit.weapon.type)}'
                '  (Mt ${unit.weapon.might} / Hit ${unit.weapon.hit}'
                '${unit.weapon.crit > 0 ? ' / Crit ${unit.weapon.crit}' : ''})',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
            if (unit.unitClass.skill != ClassSkill.none) ...[
              const SizedBox(height: 2),
              Text('${strings.ui('skill')}: ${strings.skillLabel(unit.unitClass.skill)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFFFD27A))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, int value) => Text('$label $value',
      style: const TextStyle(fontSize: 11, color: Colors.white70));
}
