import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app language selection and persists it locally.
class LocaleProvider extends ChangeNotifier {
  LocaleProvider(this._preferences);

  static const _preferencesKey = 'app_locale';
  static const supportedLanguages = <String>['en', 'ms', 'zh'];

  final SharedPreferences _preferences;
  Locale? _locale;

  /// Resolves to English until a saved choice is restored.
  Locale get locale => _locale ?? const Locale('en');

  /// Loads the persisted language choice from local storage.
  static Future<LocaleProvider> load() async {
    final preferences = await SharedPreferences.getInstance();
    final provider = LocaleProvider(preferences).._restore();
    return provider;
  }

  void _restore() {
    final code = _preferences.getString(_preferencesKey);
    if (code == null) return;
    for (final languageCode in supportedLanguages) {
      if (languageCode == code) {
        _locale = Locale(languageCode);
        return;
      }
    }
  }

  /// Switches the app language and saves the choice.
  Future<void> setLanguage(String languageCode) async {
    if (!supportedLanguages.contains(languageCode)) return;
    final next = Locale(languageCode);
    if (next == _locale) return;
    _locale = next;
    notifyListeners();
    await _preferences.setString(_preferencesKey, languageCode);
  }
}
