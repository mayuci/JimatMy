import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static const androidEmulatorBaseUrl = 'http://10.0.2.2:3000/api';
  static const webBaseUrl = 'http://localhost:3000/api';
  static const _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    return kIsWeb ? webBaseUrl : androidEmulatorBaseUrl;
  }

  static const requestTimeout = Duration(seconds: 12);

  static String mediaUrl(String relativePath) {
    final apiUri = Uri.parse(baseUrl);
    final origin = apiUri.replace(path: '', query: null, fragment: null);
    return origin.resolve(relativePath).toString();
  }
}
