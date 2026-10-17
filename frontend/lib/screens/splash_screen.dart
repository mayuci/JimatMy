import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/health_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/jimatmy_ui.dart';
import '../widgets/mobile_content.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkHealth());
  }

  Future<void> _checkHealth() async {
    final auth = context.read<AuthProvider>();
    final health = context.read<HealthProvider>();
    await auth.restoreSession();
    final connected = await health.check();
    if (!mounted || !connected) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MobileContent(
        safeArea: true,
        child: Consumer<HealthProvider>(
          builder: (context, health, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(flex: 3),
                const JimatMyLogoBadge(size: 104),
                const SizedBox(height: 22),
                Text(
                  'JimatMY',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: JimatMyColors.deepGreen,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.appTagline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(flex: 2),
                if (health.status == HealthStatus.failed)
                  _SplashErrorCard(onRetry: _checkHealth)
                else
                  const _SplashLoadingStatus(),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashLoadingStatus extends StatelessWidget {
  const _SplashLoadingStatus();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
      const SizedBox(height: 14),
      Text(context.l10n.splashConnecting),
    ],
  );
}

class _SplashErrorCard extends StatelessWidget {
  const _SplashErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE0EAE2)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_off_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.splashErrorTitle,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.splashErrorMessage,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(context.l10n.retry),
        ),
      ],
    ),
  );
}
