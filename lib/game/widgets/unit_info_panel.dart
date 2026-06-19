import 'package:flutter/material.dart';

import '../../data/models/unit.dart';

/// Compact read-out of the active unit's stats, shown while it is selected.
class UnitInfoPanel extends StatelessWidget {
  const UnitInfoPanel({super.key, required this.unit});

  final Unit unit;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black.withValues(alpha: 0.75),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${unit.name}  ·  ${unit.unitClass.label}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Text('HP  ${unit.hp}/${unit.maxHp}   Lv ${unit.level}',
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
                _stat('Mov', unit.movement),
              ],
            ),
            const SizedBox(height: 6),
            Text('${unit.weapon.name}  (Mt ${unit.weapon.might} / Hit ${unit.weapon.hit}'
                '${unit.weapon.crit > 0 ? ' / Crit ${unit.weapon.crit}' : ''})',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, int value) => Text('$label $value',
      style: const TextStyle(fontSize: 11, color: Colors.white70));
}
