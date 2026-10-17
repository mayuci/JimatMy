import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/providers/auth_provider.dart';
import 'package:jimatmy/screens/login_screen.dart';
import 'package:jimatmy/screens/register_screen.dart';
import 'package:jimatmy/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Register password can be corrected live and stale server error clears',
    (tester) async {
      final auth = AuthProvider(ApiService())
        ..isLoading = false
        ..errorMessage = 'Email is already registered.';
      await tester.pumpWidget(_authApp(auth, const RegisterScreen()));
      expect(find.text('Email is already registered.'), findsOneWidget);

      final fields = find.byType(TextFormField);

      // Editing any field dismisses the stale server error.
      await tester.enterText(fields.at(0), 'Ali');
      await tester.pump();
      expect(find.text('Email is already registered.'), findsNothing);

      // A weak password is flagged as soon as it is typed...
      await tester.enterText(fields.at(2), 'weak');
      await tester.pump();
      expect(find.text('Use a stronger password.'), findsOneWidget);
      expect(find.text('At least 10 characters'), findsOneWidget);

      // ...and the field stays editable: fixing it clears the error live.
      await tester.enterText(fields.at(2), 'StrongPass1');
      await tester.pump();
      expect(find.text('Use a stronger password.'), findsNothing);
      expect(find.text('Strong password'), findsOneWidget);
    },
  );

  testWidgets(
    'Register confirm password stays in sync when password is fixed',
    (tester) async {
      final auth = AuthProvider(ApiService());
      await tester.pumpWidget(_authApp(auth, const RegisterScreen()));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Ali');
      await tester.enterText(fields.at(1), 'ali@example.com');
      await tester.enterText(fields.at(2), 'weak');
      await tester.enterText(fields.at(3), 'weak');
      await tester.pump();

      expect(find.text('Use a stronger password.'), findsOneWidget);
      expect(find.text('Passwords do not match.'), findsNothing);

      // Correcting the main password immediately re-checks the confirmation.
      await tester.enterText(fields.at(2), 'StrongPass1');
      await tester.pump();
      expect(find.text('Use a stronger password.'), findsNothing);
      expect(find.text('Passwords do not match.'), findsOneWidget);

      await tester.enterText(fields.at(3), 'StrongPass1');
      await tester.pump();
      expect(find.text('Passwords do not match.'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Login error clears as soon as the user edits a field', (
    tester,
  ) async {
    final auth = AuthProvider(ApiService())
      ..isLoading = false
      ..errorMessage = 'Invalid email or password.';
    await tester.pumpWidget(_authApp(auth, const LoginScreen()));

    expect(find.text('Invalid email or password.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'ali@example.com');
    await tester.pump();
    expect(find.text('Invalid email or password.'), findsNothing);
  });

  testWidgets('Login re-validates fields as the user types', (tester) async {
    final auth = AuthProvider(ApiService());
    await tester.pumpWidget(_authApp(auth, const LoginScreen()));

    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'ali@example.com');
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsNothing);
    expect(find.text('Enter your password.'), findsOneWidget);
  });
}

Widget _authApp(AuthProvider auth, Widget screen) =>
    ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp(home: screen),
    );
