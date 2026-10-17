import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/l10n/l10n.dart';
import 'package:jimatmy/providers/locale_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults to English and persists a chosen language', () async {
    final provider = await LocaleProvider.load();
    expect(provider.locale.languageCode, 'en');

    await provider.setLanguage('ms');
    expect(provider.locale.languageCode, 'ms');
    expect(
      (await SharedPreferences.getInstance()).getString('app_locale'),
      'ms',
    );

    final restored = await LocaleProvider.load();
    expect(restored.locale.languageCode, 'ms');
  });

  test('ignores unsupported language codes', () async {
    final provider = await LocaleProvider.load();
    await provider.setLanguage('fr');
    expect(provider.locale.languageCode, 'en');
  });

  testWidgets('switching language updates UI text in place', (tester) async {
    final provider = await LocaleProvider.load();
    await tester.pumpWidget(
      ChangeNotifierProvider<LocaleProvider>.value(
        value: provider,
        child: Consumer<LocaleProvider>(
          builder: (context, locale, _) => MaterialApp(
            locale: locale.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(context.l10n.retry),
                    TextButton(
                      onPressed: () =>
                          context.read<LocaleProvider>().setLanguage('ms'),
                      child: const Text('switch'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('switch'));
    await tester.pumpAndSettle();

    expect(find.text('Cuba lagi'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });
}
