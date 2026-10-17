import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';
import 'generated/app_localizations_en.dart';

export 'generated/app_localizations.dart';

/// Convenience accessor so widgets can write `context.l10n.keyName`.
///
/// Falls back to English when the localizations delegates are not wired up,
/// for example in widget tests that pump a bare `MaterialApp`. The real app
/// always configures `AppLocalizations.localizationsDelegates` in `main.dart`.
extension L10n on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      AppLocalizationsEn();
}
