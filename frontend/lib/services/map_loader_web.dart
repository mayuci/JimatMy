import 'dart:js_interop';
import 'dart:js_interop_unsafe';

Future<void> loadGoogleMapsScript(String apiKey) async {
  final normalizedKey = apiKey.trim();
  if (normalizedKey.isEmpty) {
    throw ArgumentError('MAPS_KEY_MISSING');
  }
  final encodedKey = Uri.encodeQueryComponent(normalizedKey);
  final script =
      '''
    (() => {
      if (globalThis.google?.maps) return Promise.resolve();
      if (globalThis.__jimatmyMapsPromise) return globalThis.__jimatmyMapsPromise;
      globalThis.__jimatmyMapsPromise = new Promise((resolve, reject) => {
        let settled = false;
        let authFailed = false;
        globalThis.__jimatmyMapsAuthFailed = false;
        const rejectOnce = (code) => {
          if (settled) return;
          settled = true;
          reject(new Error(code));
        };
        const previousAuthFailure = globalThis.gm_authFailure;
        globalThis.gm_authFailure = () => {
          authFailed = true;
          globalThis.__jimatmyMapsAuthFailed = true;
          rejectOnce('MAPS_AUTH_FAILURE');
          if (typeof previousAuthFailure === 'function') previousAuthFailure();
        };
        const finishLoading = () => setTimeout(() => {
          if (authFailed) return rejectOnce('MAPS_AUTH_FAILURE');
          if (!globalThis.google?.maps) return rejectOnce('MAPS_SCRIPT_INVALID');
          if (settled) return;
          settled = true;
          resolve();
        }, 1000);
        const failLoading = () => rejectOnce('MAPS_SCRIPT_LOAD_FAILED');
        const existing = Array.from(document.scripts).find((candidate) =>
          candidate.src?.startsWith('https://maps.googleapis.com/maps/api/js')
        );
        if (existing) {
          existing.addEventListener('load', finishLoading, { once: true });
          existing.addEventListener('error', failLoading, { once: true });
          setTimeout(() => {
            if (globalThis.google?.maps) finishLoading();
            else rejectOnce('MAPS_SCRIPT_TIMEOUT');
          }, 8000);
          return;
        }
        const element = document.createElement('script');
        element.src = 'https://maps.googleapis.com/maps/api/js?key=$encodedKey';
        element.async = true;
        element.dataset.jimatmyMaps = 'true';
        element.addEventListener('load', finishLoading, { once: true });
        element.addEventListener('error', failLoading, { once: true });
        document.head.appendChild(element);
      });
      return globalThis.__jimatmyMapsPromise;
    })()
  ''';
  final promise = globalContext.callMethod<JSPromise<JSAny?>>(
    'eval'.toJS,
    script.toJS,
  );
  await promise.toDart;
}

bool hasGoogleMapsAuthorizationFailure() {
  final result = globalContext.callMethod<JSBoolean>(
    'eval'.toJS,
    'Boolean(globalThis.__jimatmyMapsAuthFailed)'.toJS,
  );
  return result.toDart;
}
