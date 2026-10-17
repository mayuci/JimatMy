import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/widgets/jimatmy_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('JimatMY branding assets are bundled and loadable', () async {
    for (final path in const [
      JimatMyBrandAssets.mark,
      JimatMyBrandAssets.wordmark,
    ]) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(0), reason: path);
    }
  });

  testWidgets('brand mark and wordmark fit a narrow mobile layout', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 568)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  JimatMyMark(),
                  SizedBox(height: 16),
                  JimatMyLogoBadge(size: 104),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final assetNames = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => (image.image as AssetImage).assetName);
    expect(assetNames, contains(JimatMyBrandAssets.wordmark));
    expect(assetNames, contains(JimatMyBrandAssets.mark));
    expect(tester.takeException(), isNull);
  });
}
