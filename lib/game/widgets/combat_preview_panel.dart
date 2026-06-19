import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/game_bloc.dart';
import '../bloc/game_event.dart';
import '../logic/combat.dart';

/// The battle forecast shown before committing to an attack: each side's
/// damage, hit %, crit %, and whether they strike twice.
class CombatPreviewPanel extends StatelessWidget {
  const CombatPreviewPanel({super.key, required this.forecast});

  final CombatForecast forecast;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GameBloc>();
    return Card(
      color: Colors.black.withValues(alpha: 0.85),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _side(
                  name: forecast.attacker.name,
                  hp: '${forecast.attacker.hp}/${forecast.attacker.maxHp}',
                  damage: forecast.attackerDamage,
                  hit: forecast.attackerHit,
                  crit: forecast.attackerCrit,
                  doubles: forecast.attackerDoubles,
                  effective: forecast.attackerEffective,
                  canAct: true,
                  highlight: Colors.lightBlueAccent,
                ),
                Container(width: 1, height: 104, color: Colors.white24),
                _side(
                  name: forecast.defender.name,
                  hp: '${forecast.defender.hp}/${forecast.defender.maxHp}',
                  damage: forecast.defenderDamage,
                  hit: forecast.defenderHit,
                  crit: forecast.defenderCrit,
                  doubles: forecast.defenderDoubles,
                  effective: forecast.defenderEffective,
                  canAct: forecast.defenderCanCounter,
                  highlight: Colors.redAccent,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.shade200),
                  onPressed: () => bloc.add(const CombatConfirmed()),
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Attack'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => bloc.add(const SelectionCancelled()),
                  child: const Text('Back'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _side({
    required String name,
    required String hp,
    required int damage,
    required int hit,
    required int crit,
    required bool doubles,
    required bool effective,
    required bool canAct,
    required Color highlight,
  }) {
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: TextStyle(fontWeight: FontWeight.bold, color: highlight)),
          Text('HP $hp', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          if (canAct) ...[
            Text('Dmg  $damage${doubles ? '  ×2' : ''}',
                style: const TextStyle(fontSize: 13)),
            Text('Hit  $hit%', style: const TextStyle(fontSize: 13)),
            Text('Crit $crit%', style: const TextStyle(fontSize: 13)),
            if (effective)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text('Effective ×3!',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFC107))),
              ),
          ] else
            const Text('No counter',
                style: TextStyle(fontSize: 12, color: Colors.white54)),
        ],
      ),
    );
  }
}
