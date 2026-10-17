import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('configured PromotionCarousel assets can be loaded', () async {
    const assets = [
      'assets/images/featured/ayam_bersih.webp',
      'assets/images/featured/kangkung.webp',
      'assets/images/featured/telur_ayam_gred_a.webp',
      'assets/images/featured/beras_jasmine.webp',
      'assets/images/featured/bawang_besar_india.webp',
    ];

    for (final asset in assets) {
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(0), reason: asset);
    }
  });
}
