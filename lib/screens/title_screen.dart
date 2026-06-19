import 'package:flutter/material.dart';

import '../l10n/game_strings.dart';
import 'battle_screen.dart';

/// Simple front-end: the game title, a Start button into the campaign, and a
/// language toggle that flips the active locale.
class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  void _cycleLocale() {
    final all = GameStrings.all;
    final next = all[(all.indexOf(GameStrings.current) + 1) % all.length];
    setState(() => GameStrings.current = next);
  }

  @override
  Widget build(BuildContext context) {
    final strings = GameStrings.current;
    return Scaffold(
      backgroundColor: const Color(0xFF14151B),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department,
                size: 72, color: Color(0xFFE0843C)),
            const SizedBox(height: 8),
            const Text('Ember Tactics',
                style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF2D8B0))),
            const SizedBox(height: 4),
            Text(strings.ui('subtitle'),
                style: const TextStyle(fontSize: 14, color: Colors.white60)),
            const SizedBox(height: 36),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                backgroundColor: const Color(0xFFB5462E),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BattleScreen()),
              ),
              icon: const Icon(Icons.play_arrow),
              label: Text(strings.ui('startCampaign'),
                  style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _cycleLocale,
              icon: const Icon(Icons.translate, size: 18),
              label: Text(strings.localeCode.toUpperCase()),
            ),
          ],
        ),
      ),
    );
  }
}
