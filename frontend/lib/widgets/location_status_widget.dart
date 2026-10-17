import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../services/location_service.dart';

class LocationStatusWidget extends StatelessWidget {
  const LocationStatusWidget({
    required this.failure,
    required this.onRetry,
    this.onOpenSettings,
    this.onOpenLocationSettings,
    super.key,
  });
  final LocationFailure failure;
  final VoidCallback onRetry;
  final Future<bool> Function()? onOpenSettings;
  final Future<bool> Function()? onOpenLocationSettings;

  String get message => switch (failure) {
    LocationFailure.serviceDisabled =>
      'Location services are disabled. Turn on location services to continue.',
    LocationFailure.denied =>
      'Location permission was denied. You can choose an area manually.',
    LocationFailure.deniedForever =>
      kIsWeb
          ? 'Location is blocked. Allow it in your browser site settings.'
          : 'Location permission is blocked. Open settings to allow it.',
    LocationFailure.unavailable =>
      kIsWeb
          ? 'Location is unavailable. Check browser permissions and use localhost or HTTPS.'
          : 'Your location is unavailable on this device.',
    LocationFailure.timeout =>
      kIsWeb
          ? 'Location took too long to respond. You can try again when ready.'
          : 'No location received. Set a location in the Android emulator and retry.',
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_disabled_outlined,
            color: colors.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
          if (failure == LocationFailure.deniedForever &&
              !kIsWeb &&
              onOpenSettings != null)
            TextButton(
              onPressed: onOpenSettings,
              child: const Text('Open settings'),
            )
          else if (failure == LocationFailure.serviceDisabled &&
              !kIsWeb &&
              onOpenLocationSettings != null)
            TextButton(
              onPressed: onOpenLocationSettings,
              child: const Text('Turn on location services'),
            )
          else
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
