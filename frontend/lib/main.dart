import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/l10n.dart';
import 'providers/health_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/app_location_provider.dart';
import 'providers/item_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/planner_provider.dart';
import 'providers/profile_provider.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'services/location_service.dart';
import 'widgets/jimatmy_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeProvider = await LocaleProvider.load();
  runApp(JimatMyApp(localeProvider: localeProvider));
}

class JimatMyApp extends StatelessWidget {
  const JimatMyApp({required this.localeProvider, super.key});

  final LocaleProvider localeProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProvider(
          create: (_) => AppLocationProvider(LocationService())..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => ProfileProvider(context.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => PlannerProvider(context.read<ApiService>())
            ..onListCountChanged = context
                .read<ProfileProvider>()
                .refreshSummary,
        ),
        ChangeNotifierProvider(
          create: (context) => HealthProvider(context.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ItemProvider(context.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (context) {
            final auth = AuthProvider(context.read<ApiService>());
            auth.onSessionStarted = () =>
                context.read<ProfileProvider>().load(force: true);
            auth.onSessionCleared = () {
              context.read<PlannerProvider>().clear();
              context.read<ProfileProvider>().clear();
            };
            return auth..restoreSession();
          },
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, locale, _) => MaterialApp(
          title: 'JimatMY',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(),
          locale: locale.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const SplashScreen(),
        ),
      ),
    );
  }

  ThemeData _buildTheme() {
    final colors = ColorScheme.fromSeed(seedColor: JimatMyColors.green)
        .copyWith(
          primary: JimatMyColors.green,
          onPrimary: Colors.white,
          secondary: JimatMyColors.yellow,
          surface: JimatMyColors.cream,
          surfaceContainerLowest: Colors.white,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: JimatMyColors.cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: JimatMyColors.cream,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          side: BorderSide(color: Color(0xFFE0EAE2)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: Color(0xFFD5DED8)),
        ),
      ),
    );
  }
}
