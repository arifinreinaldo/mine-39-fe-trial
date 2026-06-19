import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../l10n/game_strings.dart';
import '../bloc/game_bloc.dart';
import '../bloc/game_event.dart';

/// Post-move menu: Attack (only when a target is in range), Promote (only when
/// eligible), Wait, or Cancel (which sends the unit back to where it started).
class ActionMenu extends StatelessWidget {
  const ActionMenu({
    super.key,
    required this.canAttack,
    required this.canPromote,
    required this.canHeal,
    required this.canUseItem,
  });

  final bool canAttack;
  final bool canPromote;
  final bool canHeal;
  final bool canUseItem;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GameBloc>();
    final strings = GameStrings.current;
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
                label: Text(strings.ui('attack')),
              ),
              const SizedBox(width: 8),
            ],
            if (canHeal) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E8E5A)),
                onPressed: () => bloc.add(const ActionSelected(BattleAction.heal)),
                icon: const Icon(Icons.healing),
                label: Text(strings.ui('heal')),
              ),
              const SizedBox(width: 8),
            ],
            if (canUseItem) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3E7A8E)),
                onPressed: () => bloc.add(const ActionSelected(BattleAction.item)),
                icon: const Icon(Icons.local_drink),
                label: Text(strings.ui('item')),
              ),
              const SizedBox(width: 8),
            ],
            if (canPromote) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB58A2E)),
                onPressed: () => bloc.add(const ActionSelected(BattleAction.promote)),
                icon: const Icon(Icons.auto_awesome),
                label: Text(strings.ui('promote')),
              ),
              const SizedBox(width: 8),
            ],
            ElevatedButton.icon(
              onPressed: () => bloc.add(const ActionSelected(BattleAction.wait)),
              icon: const Icon(Icons.hourglass_bottom),
              label: Text(strings.ui('wait')),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => bloc.add(const SelectionCancelled()),
              child: Text(strings.ui('cancel')),
            ),
          ],
        ),
      ),
    );
  }
}
