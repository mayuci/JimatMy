import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jimatmy/models/premise.dart';
import 'package:jimatmy/services/maps_config_service.dart';
import 'package:jimatmy/widgets/premise_map_widget.dart';

const _mapped = Premise(
  premiseCode: 22063,
  premiseName: 'OFFICIAL TEST PREMISE',
  address: 'NO 1, JALAN TEST',
  postcode: '47301',
  premiseType: 'Pasar Raya / Supermarket',
  district: 'Petaling Jaya',
  state: 'Selangor',
  latitude: 3.1073,
  longitude: 101.6067,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('jimatmy/maps_config');

  void mockChannel(Object? result) {
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => result);
  }

  void clearChannel() {
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  }

  tearDown(() {
    clearChannel();
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'Android uses the native configuration check, never the Web loader',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      mockChannel(true);
      var loaderCalls = 0;
      final config = MapsConfigService(
        webApiKey: 'web-only-key',
        isWeb: false,
        scriptLoader: (_) async => loaderCalls += 1,
      );
      expect(await config.prepare(), isNull);
      expect(loaderCalls, 0);
    },
  );

  test('Android missing key reports a native configuration error', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    mockChannel(false);
    final config = MapsConfigService(
      webApiKey: 'web-only-key',
      isWeb: false,
      scriptLoader: (_) async {},
    );
    final error = await config.prepare();
    expect(error, isNotNull);
    expect(error, contains('not configured for Android'));
    expect(error, isNot(contains('GOOGLE_MAPS_WEB_API_KEY')));
  });

  testWidgets('Android map widget builds the native GoogleMap', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      mockChannel(true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 203,
              child: PremiseMapWidget(
                premises: const [_mapped],
                selectedPremise: _mapped,
                compact: true,
                mapsConfigService: MapsConfigService(isWeb: false),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(GoogleMap), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
