import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'map_loader.dart';

class MapsConfigService {
  MapsConfigService({
    String? webApiKey,
    bool? isWeb,
    Future<void> Function(String)? scriptLoader,
  }) : _webApiKey =
           webApiKey ?? const String.fromEnvironment('GOOGLE_MAPS_WEB_API_KEY'),
       _isWeb = isWeb ?? kIsWeb,
       _scriptLoader = scriptLoader ?? loadGoogleMapsScript;

  final String _webApiKey;
  final bool _isWeb;
  final Future<void> Function(String) _scriptLoader;
  static const _channel = MethodChannel('jimatmy/maps_config');
  Future<String?>? _preparation;

  Future<String?> prepare() => _preparation ??= _prepare();

  String? runtimeError() {
    if (_isWeb && hasGoogleMapsAuthorizationFailure()) {
      return 'Google Maps could not be authorized. Check Maps JavaScript API access, billing, and allowed Web referrers.';
    }
    return null;
  }

  Future<String?> _prepare() async {
    if (_isWeb) {
      if (_webApiKey.trim().isEmpty) {
        return 'The Web map key is missing. Run JimatMY with the documented GOOGLE_MAPS_WEB_API_KEY setting.';
      }
      try {
        await _scriptLoader(_webApiKey).timeout(const Duration(seconds: 10));
        return runtimeError();
      } catch (error) {
        final category = error.toString();
        if (category.contains('MAPS_AUTH_FAILURE')) {
          return 'Google Maps could not be authorized. Check Maps JavaScript API access, billing, and allowed Web referrers.';
        }
        if (category.contains('MAPS_SCRIPT_TIMEOUT') ||
            error is TimeoutException) {
          return 'Google Maps took too long to load. Check the network connection and Web key setup.';
        }
        return 'Google Maps could not load its map script. Check the network connection and Web key setup.';
      }
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final configured = await _channel.invokeMethod<bool>('isConfigured');
        if (configured != true) {
          return 'Google Maps is not configured for Android. Add the local key before running the app.';
        }
      } on PlatformException {
        return 'Google Maps configuration could not be verified on this device.';
      }
    }
    return null;
  }
}
