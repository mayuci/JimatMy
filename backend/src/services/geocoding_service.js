const ApiError = require('../utils/api_error');

const GEOCODING_URL = 'https://maps.googleapis.com/maps/api/geocode/json';

async function geocodeMalaysianAddress({
  address,
  placeId,
  apiKey = process.env.GOOGLE_GEOCODING_API_KEY,
  fetchImpl = fetch,
  timeoutMs = 5000,
}) {
  if (!apiKey) {
    throw new ApiError(
      503,
      'GEOCODING_NOT_CONFIGURED',
      'Store location lookup is not configured',
    );
  }

  const url = new URL(GEOCODING_URL);
  if (placeId) {
    url.searchParams.set('place_id', placeId);
  } else {
    url.searchParams.set('address', address);
  }
  url.searchParams.set('components', 'country:MY');
  url.searchParams.set('region', 'my');
  url.searchParams.set('key', apiKey);
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  let response;
  try {
    response = await fetchImpl(url, {
      method: 'GET',
      headers: { Accept: 'application/json' },
      signal: controller.signal,
    });
  } catch (error) {
    if (error.name === 'AbortError') {
      throw new ApiError(504, 'GEOCODING_TIMEOUT', 'Store location lookup timed out');
    }
    throw new ApiError(
      502,
      'GEOCODING_NETWORK_ERROR',
      'The backend could not reach Google Geocoding',
    );
  } finally {
    clearTimeout(timeout);
  }

  if (response.status === 429) {
    throw new ApiError(
      429,
      'GEOCODING_RATE_LIMITED',
      'Store location lookup rate limit was reached',
    );
  }
  if (!response.ok) {
    const isClientError = response.status >= 400 && response.status < 500;
    throw new ApiError(
      502,
      isClientError ? 'GEOCODING_HTTP_CLIENT_ERROR' : 'GEOCODING_HTTP_SERVER_ERROR',
      isClientError
        ? 'Google Geocoding rejected the HTTP request'
        : 'Google Geocoding returned a server error',
    );
  }

  let payload;
  try {
    payload = await response.json();
  } catch (_) {
    throw new ApiError(
      502,
      'GEOCODING_INVALID_RESPONSE',
      'Store location lookup returned an invalid response',
    );
  }

  if (payload.status === 'ZERO_RESULTS') return null;
  if (payload.status === 'OVER_QUERY_LIMIT') {
    throw new ApiError(
      429,
      'GEOCODING_RATE_LIMITED',
      'Store location lookup rate limit was reached',
    );
  }
  if (payload.status === 'REQUEST_DENIED') {
    throw new ApiError(
      503,
      'GEOCODING_REQUEST_DENIED',
      'Google denied the location lookup; check API enablement, billing, and key restrictions',
    );
  }
  if (payload.status === 'OVER_DAILY_LIMIT') {
    throw new ApiError(
      429,
      'GEOCODING_DAILY_LIMIT',
      'The Google Geocoding daily limit or billing allowance was reached',
    );
  }
  if (payload.status === 'INVALID_REQUEST') {
    throw new ApiError(
      502,
      'GEOCODING_INVALID_REQUEST',
      'Google rejected the location lookup parameters',
    );
  }
  if (payload.status !== 'OK') {
    throw new ApiError(
      502,
      'GEOCODING_UPSTREAM_ERROR',
      'Google Geocoding could not process the location lookup',
    );
  }

  const first = payload.results?.[0];
  const latitude = first?.geometry?.location?.lat;
  const longitude = first?.geometry?.location?.lng;
  if (
    typeof latitude !== 'number' ||
    typeof longitude !== 'number' ||
    typeof first.formatted_address !== 'string'
  ) {
    throw new ApiError(
      502,
      'GEOCODING_INVALID_RESPONSE',
      'Store location lookup returned incomplete location data',
    );
  }
  return {
    latitude,
    longitude,
    formattedAddress: first.formatted_address,
    partialMatch: first.partial_match === true,
    locationType: typeof first.geometry.location_type === 'string'
      ? first.geometry.location_type
      : null,
    placeId: typeof first.place_id === 'string' ? first.place_id : null,
  };
}

module.exports = { geocodeMalaysianAddress };
