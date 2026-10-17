import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/l10n/l10n.dart';
import 'package:jimatmy/providers/auth_provider.dart';
import 'package:jimatmy/providers/health_provider.dart';
import 'package:jimatmy/screens/login_screen.dart';
import 'package:jimatmy/screens/register_screen.dart';
import 'package:jimatmy/screens/splash_screen.dart';
import 'package:jimatmy/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Splash shows branding and PriceCatcher connection status', (
    tester,
  ) async {
    final api = _HealthApi(wait: Completer<void>());
    await tester.pumpWidget(_splashApp(api));
    await tester.pump();

    expect(find.text('JimatMY'), findsOneWidget);
    expect(find.text('Compare prices. Save every day.'), findsOneWidget);
    expect(find.text('Connecting to PriceCatcher data…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Splash failure is compact and hides technical exceptions', (
    tester,
  ) async {
    const technical = 'ECONNREFUSED 127.0.0.1:3000';
    await tester.pumpWidget(_splashApp(_HealthApi(error: technical)));
    await tester.pumpAndSettle();

    expect(find.text('We could not connect'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('temporarily unavailable'), findsOneWidget);
    expect(find.textContaining(technical), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Login validates fields and exposes password visibility', (
    tester,
  ) async {
    final auth = AuthProvider(ApiService());
    await tester.pumpWidget(_authApp(auth, const LoginScreen()));

    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(find.byTooltip('Show password'), findsOneWidget);
  });

  testWidgets('Register validates strength and matching confirmation', (
    tester,
  ) async {
    final auth = AuthProvider(ApiService());
    await tester.pumpWidget(_authApp(auth, const RegisterScreen()));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'A');
    await tester.enterText(fields.at(1), 'not-an-email');
    await tester.enterText(fields.at(2), 'weak');
    await tester.enterText(fields.at(3), 'different');
    await tester.ensureVisible(find.byKey(const ValueKey('register-submit')));
    await tester.tap(find.byKey(const ValueKey('register-submit')));
    await tester.pump();

    expect(find.text('Enter at least 2 characters.'), findsOneWidget);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Use a stronger password.'), findsOneWidget);
    expect(find.text('Passwords do not match.'), findsOneWidget);
  });

  testWidgets('Auth loading and error states remain clear', (tester) async {
    final auth = AuthProvider(ApiService())
      ..isLoading = true
      ..errorMessage = 'Email or password is incorrect.';
    await tester.pumpWidget(_authApp(auth, const LoginScreen()));

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('login-submit')),
    );
    expect(button.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Email or password is incorrect.'), findsOneWidget);
  });

  testWidgets('Register remains scrollable with keyboard on narrow mobile', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1
      ..viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    final auth = AuthProvider(ApiService());
    await tester.pumpWidget(_authApp(auth, const RegisterScreen()));
    await tester.ensureVisible(find.byKey(const ValueKey('register-submit')));
    await tester.pump();

    expect(find.text('Create your JimatMY account'), findsOneWidget);
    expect(find.byKey(const ValueKey('register-submit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _splashApp(_HealthApi api) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider(api)),
    ChangeNotifierProvider(create: (_) => HealthProvider(api)),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const SplashScreen(),
  ),
);

Widget _authApp(AuthProvider auth, Widget screen) =>
    ChangeNotifierProvider.value(
      value: auth,
      child: MaterialApp(home: screen),
    );

class _HealthApi extends ApiService {
  _HealthApi({this.wait, this.error});

  final Completer<void>? wait;
  final String? error;

  @override
  Future<void> checkHealth() async {
    if (error case final message?) throw ApiException(message);
    await wait?.future;
  }
}
