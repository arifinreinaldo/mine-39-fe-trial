import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/unit_class.dart';
import '../../l10n/game_strings.dart';
import '../bloc/game_bloc.dart';
import '../bloc/game_event.dart';
import '../bloc/game_state.dart';

/// The promotion chooser: each branch the unit can take, with the resulting
/// class name, the seal consumed, and the stat bonus.
class PromotionMenu extends StatelessWidget {
  const PromotionMenu({super.key, required this.state});

  final ChoosingPromotion state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GameBloc>();
    final strings = GameStrings.current;

    return Card(
      color: Colors.black.withValues(alpha: 0.88),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${state.unit.name} · ${strings.ui('choosePromotion')}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final option in state.options) ...[
                    _OptionCard(
                      option: option,
                      onTap: () => bloc.add(PromotionChosen(option)),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => bloc.add(const SelectionCancelled()),
                child: Text(strings.ui('cancel')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.option, required this.onTap});

  final Promotion option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = GameStrings.current;
    final to = option.to;
    final traits = to.traits.map((t) => strings.traitLabel(t)).join(' · ');
    final delta = _deltaText(option.bonus);

    return SizedBox(
      width: 140,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFB58A2E)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(strings.className(to),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFFFFD27A))),
              const SizedBox(height: 2),
              Text('Mov ${to.baseMove}${traits.isNotEmpty ? '  ·  $traits' : ''}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70)),
              if (option.item != 'levelUp')
                Text(strings.itemLabel(option.item),
                    style: const TextStyle(fontSize: 11, color: Colors.white54)),
              if (delta.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(delta, style: const TextStyle(fontSize: 11)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _deltaText(StatDelta d) {
    final parts = <String>[
      if (d.hp != 0) '+${d.hp} HP',
      if (d.str != 0) '+${d.str} Str',
      if (d.mag != 0) '+${d.mag} Mag',
      if (d.skl != 0) '+${d.skl} Skl',
      if (d.spd != 0) '+${d.spd} Spd',
      if (d.def != 0) '+${d.def} Def',
      if (d.res != 0) '+${d.res} Res',
      if (d.con != 0) '+${d.con} Con',
    ];
    return parts.join('  ');
  }
}
