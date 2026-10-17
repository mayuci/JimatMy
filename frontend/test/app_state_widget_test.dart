import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/models/premise.dart';
import 'package:jimatmy/widgets/premise_map_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('compact map configuration error fits within short height', (
    tester,
  ) async {
    const channel = MethodChannel('jimatmy/maps_config');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => false,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              key: ValueKey('map-container'),
              width: 360,
              height: 210,
              child: PremiseMapWidget(
                compact: true,
                premises: [
                  Premise(
                    premiseCode: 1,
                    premiseName: 'Mapped premise',
                    address: 'Official address',
                    postcode: null,
                    premiseType: 'Store',
                    district: 'District',
                    state: 'Selangor',
                    latitude: 3.1,
                    longitude: 101.6,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Map could not be displayed'), findsOneWidget);
    expect(find.text('Retry map'), findsNothing);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(
      tester.getBottomRight(find.text('Map could not be displayed')).dy,
      lessThanOrEqualTo(
        tester.getBottomRight(find.byKey(const ValueKey('map-container'))).dy,
      ),
    );
  });
}
