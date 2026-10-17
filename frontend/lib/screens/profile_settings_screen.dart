import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/app_location_provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/jimatmy_ui.dart';
import '../widgets/location_onboarding_widget.dart';
import '../widgets/mobile_content.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.settingsTitle)),
    body: MobileContent(
      child: Consumer<AppLocationProvider>(
        builder: (context, location, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.l10n.settingsLocationSection,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                minTileHeight: 70,
                leading: const Icon(Icons.location_on_outlined),
                title: Text(context.l10n.settingsSelectedArea),
                subtitle: Text(location.locationLabel),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showManualLocationSelector(context),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                minTileHeight: 70,
                leading: const Icon(Icons.my_location_rounded),
                title: Text(context.l10n.settingsUseDeviceLocation),
                subtitle: Text(
                  location.hasDeviceLocation
                      ? context.l10n.settingsPermissionActive
                      : context.l10n.settingsPermissionRequested,
                ),
                trailing: location.isRequesting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right_rounded),
                onTap: location.isRequesting
                    ? null
                    : () async {
                        final result = await location.requestCurrentLocation();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result.location == null
                                    ? context.l10n.settingsLocationFailed
                                    : context.l10n.settingsLocationEnabled,
                              ),
                            ),
                          );
                        }
                      },
              ),
            ),
            const SizedBox(height: 22),
            Text(
              context.l10n.settingsLanguageSection,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Consumer<LocaleProvider>(
              builder: (context, locale, _) => Card(
                child: Column(
                  children: [
                    _LanguageTile(
                      label: context.l10n.languageEnglish,
                      selected: locale.locale.languageCode == 'en',
                      onTap: () => locale.setLanguage('en'),
                    ),
                    const Divider(height: 1, indent: 56),
                    _LanguageTile(
                      label: context.l10n.languageMalay,
                      selected: locale.locale.languageCode == 'ms',
                      onTap: () => locale.setLanguage('ms'),
                    ),
                    const Divider(height: 1, indent: 56),
                    _LanguageTile(
                      label: context.l10n.languageChinese,
                      selected: locale.locale.languageCode == 'zh',
                      onTap: () => locale.setLanguage('zh'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              context.l10n.settingsAppInfoSection,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('JimatMY'),
                subtitle: Text(context.l10n.settingsVersion),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 56,
    leading: const Icon(Icons.translate_rounded),
    title: Text(label),
    trailing: selected
        ? const Icon(Icons.check_circle_rounded, color: JimatMyColors.green)
        : null,
    onTap: onTap,
  );
}

