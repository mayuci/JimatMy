import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jimatmy/providers/auth_provider.dart';
import 'package:jimatmy/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('login stores session and logout clears it', () async {
    SharedPreferences.setMockInitialValues({});
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], isNull);
      return http.Response(
        '{"success":true,"data":{"token":"test-token","user":{"userId":"u1","name":"Aina","email":"aina@example.com","createdAt":"2026-08-17T00:00:00Z","updatedAt":"2026-08-17T00:00:00Z"}}}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = ApiService(client: client);
    final auth = AuthProvider(api);
    await auth.restoreSession();

    expect(await auth.login('aina@example.com', 'StrongPass9'), isNull);
    expect(auth.isAuthenticated, isTrue);
    expect(auth.user?.name, 'Aina');

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('jimatmy.auth_token'), 'test-token');
    await auth.logout();
    expect(auth.isAuthenticated, isFalse);
    expect(preferences.getString('jimatmy.auth_token'), isNull);
  });

  test('invalid protected session is cleared during restore', () async {
    SharedPreferences.setMockInitialValues({'jimatmy.auth_token': 'expired'});
    final client = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer expired');
      return http.Response(
        '{"success":false,"error":{"code":"TOKEN_EXPIRED","message":"Token has expired"}}',
        401,
        headers: {'content-type': 'application/json'},
      );
    });
    final api = ApiService(client: client);
    final auth = AuthProvider(api);
    await auth.restoreSession();
    expect(auth.isAuthenticated, isFalse);
    expect(
      (await SharedPreferences.getInstance()).getString('jimatmy.auth_token'),
      isNull,
    );
  });
}
