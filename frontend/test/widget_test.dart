import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/screens/placeholder_screen.dart';

void main() {
  testWidgets('placeholder screen identifies future modules', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PlaceholderScreen(title: 'Planner', icon: Icons.list_alt),
      ),
    );
    expect(find.text('Planner'), findsOneWidget);
    expect(find.text('Coming next'), findsOneWidget);
  });
}
