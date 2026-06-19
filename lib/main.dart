import 'package:flutter/material.dart';

import 'screens/title_screen.dart';

void main() {
  runApp(const EmberTacticsApp());
}

class EmberTacticsApp extends StatelessWidget {
  const EmberTacticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ember Tactics',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFFB5462E),
      ),
      home: const TitleScreen(),
    );
  }
}
