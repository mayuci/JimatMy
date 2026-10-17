import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/premise.dart';
import '../providers/app_location_provider.dart';
import '../services/api_service.dart';
import 'jimatmy_ui.dart';
import 'location_status_widget.dart';

class LocationOnboardingHost extends StatefulWidget {
  const LocationOnboardingHost({required this.child, super.key});

  final Widget child;

  @override
  State<LocationOnboardingHost> createState() => _LocationOnboardingHostState();
}

class _LocationOnboardingHostState extends State<LocationOnboardingHost> {
  AppLocationProvider? _provider;
  bool _promptScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<AppLocationProvider?>(context, listen: false);
    if (provider == null) return;
    if (!identical(provider, _provider)) {
      _provider?.removeListener(_schedulePromptIfNeeded);
      _provider = provider..addListener(_schedulePromptIfNeeded);
    }
    _schedulePromptIfNeeded();
  }

  void _schedulePromptIfNeeded() {
    final provider = _provider;
    if (_promptScheduled || provider?.shouldShowOnboarding != true) return;
    _promptScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || provider?.shouldShowOnboarding != true) return;
      await showLocationOnboardingSheet(context);
    });
  }

  @override
  void dispose() {
    _provider?.removeListener(_schedulePromptIfNeeded);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Future<void> showLocationOnboardingSheet(BuildContext context) async {
  final provider = context.read<AppLocationProvider>();
  await showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => ChangeNotifierProvider.value(
      value: provider,
      child: _LocationPermissionSheet(parentContext: context),
    ),
  );
}

class _LocationPermissionSheet extends StatelessWidget {
  const _LocationPermissionSheet({required this.parentContext});

  final BuildContext parentContext;

  Future<void> _allow(BuildContext context) async {
    final provider = context.read<AppLocationProvider>();
    final result = await provider.requestCurrentLocation();
    if (!context.mounted || result.location == null) return;
    Navigator.pop(context);
    if (parentContext.mounted) {
      ScaffoldMessenger.of(parentContext)
          .showSnackBar(const SnackBar(content: Text('Location enabled')));
    }
  }

  Future<void> _chooseManually(BuildContext context) async {
    final provider = context.read<AppLocationProvider>();
    await provider.markOnboardingSeen();
    if (!context.mounted) return;
    Navigator.pop(context);
    if (parentContext.mounted) {
      await showManualLocationSelector(parentContext);
    }
  }

  Future<void> _notNow(BuildContext context) async {
    await context.read<AppLocationProvider>().markOnboardingSeen();
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Consumer<AppLocationProvider>(
    builder: (context, provider, _) => Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          18,
          24,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 22),
              const _LocationIllustration(),
              const SizedBox(height: 18),
              Text(
                'Find better prices near you',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              const Text(
                'Location helps JimatMY show nearby stores and calculate distance. It is only used while you are using the app.',
                textAlign: TextAlign.center,
              ),
              if (provider.failure case final failure?) ...[
                const SizedBox(height: 14),
                LocationStatusWidget(
                  failure: failure,
                  onRetry: () => _allow(context),
                  onOpenSettings: provider.openAppSettings,
                  onOpenLocationSettings: provider.openLocationSettings,
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: provider.isRequesting
                      ? null
                      : () => _allow(context),
                  icon: provider.isRequesting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    provider.isRequesting
                        ? 'Finding your location…'
                        : 'Allow location',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: provider.isRequesting
                      ? null
                      : () => _chooseManually(context),
                  icon: const Icon(Icons.edit_location_alt_outlined),
                  label: const Text('Choose location manually'),
                ),
              ),
              TextButton(
                onPressed: provider.isRequesting
                    ? null
                    : () => _notNow(context),
                child: const Text('Not now'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LocationIllustration extends StatelessWidget {
  const _LocationIllustration();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Nearby store location illustration',
    image: true,
    child: Container(
      width: 84,
      height: 84,
      decoration: const BoxDecoration(
        color: JimatMyColors.mint,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.location_on_rounded,
            size: 42,
            color: JimatMyColors.green,
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: JimatMyColors.yellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_rounded,
                size: 16,
                color: JimatMyColors.deepGreen,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> showManualLocationSelector(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MultiProvider(
        providers: [
          Provider<ApiService>.value(value: context.read<ApiService>()),
          ChangeNotifierProvider<AppLocationProvider>.value(
            value: context.read<AppLocationProvider>(),
          ),
        ],
        child: const _ManualLocationSheet(),
      ),
    );

class _ManualLocationSheet extends StatefulWidget {
  const _ManualLocationSheet();

  @override
  State<_ManualLocationSheet> createState() => _ManualLocationSheetState();
}

class _ManualLocationSheetState extends State<_ManualLocationSheet> {
  late final Future<List<PremiseFilterGroup>> _filters;
  String? _state;
  String? _district;

  @override
  void initState() {
    super.initState();
    final location = context.read<AppLocationProvider>();
    _state = location.manualState;
    _district = location.manualDistrict;
    _filters = context.read<ApiService>().getPremiseFilters();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      16,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: FutureBuilder<List<PremiseFilterGroup>>(
      future: _filters,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const SizedBox(
            height: 220,
            child: Center(
              child: Text('Locations could not be loaded. Please try again.'),
            ),
          );
        }
        final filters = snapshot.data!;
        final states = filters.map((group) => group.state).toList();
        if (!states.contains(_state)) {
          _state = null;
          _district = null;
        }
        final districts = _state == null
            ? const <String>[]
            : filters
                  .where((group) => group.state == _state)
                  .expand((group) => group.districts)
                  .toList();
        if (!districts.contains(_district)) _district = null;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose your area',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select a PriceCatcher area without sharing your device location.',
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _state,
              decoration: const InputDecoration(labelText: 'State'),
              items: states
                  .map(
                    (state) =>
                        DropdownMenuItem(value: state, child: Text(state)),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _state = value;
                _district = null;
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_state),
              initialValue: _district,
              decoration: const InputDecoration(
                labelText: 'District (optional)',
              ),
              items: districts
                  .map(
                    (district) => DropdownMenuItem(
                      value: district,
                      child: Text(district),
                    ),
                  )
                  .toList(),
              onChanged: _state == null
                  ? null
                  : (value) => setState(() => _district = value),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _state == null
                  ? null
                  : () async {
                      await context
                          .read<AppLocationProvider>()
                          .chooseManualArea(_state!, _district);
                      if (context.mounted) Navigator.pop(context);
                    },
              child: const Text('Use this area'),
            ),
          ],
        );
      },
    ),
  );
}
