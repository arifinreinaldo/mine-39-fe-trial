import 'package:ember_tactics/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots and shows the title bar', (tester) async {
    await tester.pumpWidget(const EmberTacticsApp());
    await tester.pump();
    expect(find.text('Ember Tactics'), findsOneWidget);
  });
}
