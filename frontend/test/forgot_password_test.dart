import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/providers/auth_provider.dart';
import 'package:jimatmy/screens/login_screen.dart';
import 'package:jimatmy/services/api_service.dart';
import 'package:provider/provider.dart';

Future<void> _tapResetSubmit(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const ValueKey('reset-submit')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('reset-submit')));
}

void main() {
  testWidgets('login screen shows a right-aligned Forgot password? link', (
    tester,
  ) async {
    final api = _FakeResetApi();
    await tester.pumpWidget(_app(api));
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('forgot password validates the email before sending', (
    tester,
  ) async {
    final api = _FakeResetApi();
    await tester.pumpWidget(_app(api));
    await tester.tap(find.byKey(const ValueKey('forgot-password-link')));
    await tester.pumpAndSettle();
    expect(find.text('Forgot password'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('forgot-submit')));
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(api.forgotCalls, 0);
  });

  testWidgets(
    'forgot password disables submit while sending and navigates to reset',
    (tester) async {
      final api = _FakeResetApi(sendDelay: const Duration(milliseconds: 300));
      await tester.pumpWidget(_app(api));
      await tester.tap(find.byKey(const ValueKey('forgot-password-link')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'user@example.com',
      );
      await tester.tap(find.byKey(const ValueKey('forgot-submit')));
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('forgot-submit')))
            .onPressed,
        isNull,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(api.forgotCalls, 1);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('reset-submit')), findsOneWidget);
    },
  );

  testWidgets('reset password validates the code and password confirmation', (
    tester,
  ) async {
    final api = _FakeResetApi();
    await tester.pumpWidget(_app(api));
    await tester.tap(find.byKey(const ValueKey('forgot-password-link')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('forgot-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reset-submit')), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), '12');
    await tester.enterText(fields.at(2), 'StrongPass1');
    await tester.enterText(fields.at(3), 'Different1');
    await _tapResetSubmit(tester);
    await tester.pump();
    expect(find.text('Enter the six-digit code.'), findsOneWidget);
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(api.resetCalls, 0);
  });

  testWidgets(
    'successful reset returns to login and shows the success message',
    (tester) async {
      final api = _FakeResetApi();
      await tester.pumpWidget(_app(api));
      await tester.tap(find.byKey(const ValueKey('forgot-password-link')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'user@example.com',
      );
      await tester.tap(find.byKey(const ValueKey('forgot-submit')));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(1), '123456');
      await tester.enterText(fields.at(2), 'StrongPass1');
      await tester.enterText(fields.at(3), 'StrongPass1');
      await _tapResetSubmit(tester);
      await tester.pumpAndSettle();
      expect(api.resetCalls, 1);
      expect(api.lastCode, '123456');
      expect(api.lastNewPassword, 'StrongPass1');
      expect(
        find.byKey(const ValueKey('forgot-password-link')),
        findsOneWidget,
      );
      expect(find.text('Password reset. Please log in.'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a backend error on reset stays on the reset screen', (
    tester,
  ) async {
    final api = _FakeResetApi()..failReset = true;
    await tester.pumpWidget(_app(api));
    await tester.tap(find.byKey(const ValueKey('forgot-password-link')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('forgot-submit')));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), '123456');
    await tester.enterText(fields.at(2), 'StrongPass1');
    await tester.enterText(fields.at(3), 'StrongPass1');
    await _tapResetSubmit(tester);
    await tester.pumpAndSettle();
    expect(api.resetCalls, 1);
    expect(
      find.text('That reset code is invalid or has expired.'),
      findsWidgets,
    );
    expect(find.byKey(const ValueKey('reset-submit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reopening the reset flow does not leak disposed controllers', (
    tester,
  ) async {
    final api = _FakeResetApi();
    await tester.pumpWidget(_app(api));
    await tester.tap(find.byKey(const ValueKey('forgot-password-link')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'user@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('forgot-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('forgot-submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reset-submit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeResetApi extends ApiService {
  _FakeResetApi({this.sendDelay = Duration.zero});

  final Duration sendDelay;
  int forgotCalls = 0;
  int resetCalls = 0;
  bool failForgot = false;
  bool failReset = false;
  String? lastEmail;
  String? lastCode;
  String? lastNewPassword;

  @override
  Future<String> forgotPassword(String email) async {
    forgotCalls += 1;
    lastEmail = email;
    if (sendDelay > Duration.zero) {
      await Future<void>.delayed(sendDelay);
    }
    if (failForgot) {
      throw const ApiException(
        'Too many password reset requests. Try again later.',
        code: 'RATE_LIMIT',
        statusCode: 429,
      );
    }
    return 'If an account exists for that email, a reset code has been sent.';
  }

  @override
  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    resetCalls += 1;
    lastEmail = email;
    lastCode = code;
    lastNewPassword = newPassword;
    if (failReset) {
      throw const ApiException(
        'That reset code is invalid or has expired.',
        code: 'INVALID_RESET_CODE',
        statusCode: 400,
      );
    }
    return 'Your password has been reset. You can now log in.';
  }
}

Widget _app(_FakeResetApi api) => MultiProvider(
  providers: [
    Provider<ApiService>.value(value: api),
    ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider(api)),
  ],
  child: const MaterialApp(home: LoginScreen()),
);
