import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/game_bloc.dart';
import '../bloc/game_event.dart';

/// Post-move menu: Attack (only when a target is in range), Wait, or Cancel
/// (which sends the unit back to where it started this turn).
class ActionMenu extends StatelessWidget {
  const ActionMenu({super.key, required this.canAttack});

  final bool canAttack;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GameBloc>();
    return Card(
      color: Colors.black.withValues(alpha: 0.8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canAttack) ...[
              ElevatedButton.icon(
                onPressed: () => bloc.add(const ActionSelected(BattleAction.attack)),
                icon: const Icon(Icons.gps_fixed),
                label: const Text('Attack'),
              ),
              const SizedBox(width: 8),
            ],
            ElevatedButton.icon(
              onPressed: () => bloc.add(const ActionSelected(BattleAction.wait)),
              icon: const Icon(Icons.hourglass_bottom),
              label: const Text('Wait'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => bloc.add(const SelectionCancelled()),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
