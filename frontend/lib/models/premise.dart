class Premise {
  const Premise({
    required this.premiseCode,
    required this.premiseName,
    required this.address,
    required this.postcode,
    required this.premiseType,
    required this.district,
    required this.state,
    required this.latitude,
    required this.longitude,
    this.distanceKm,
    this.coordinateAccuracy,
  });

  final int premiseCode;
  final String premiseName;
  final String address;
  final String? postcode;
  final String premiseType;
  final String district;
  final String state;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final String? coordinateAccuracy;
  ({double latitude, double longitude})? get coordinates {
    final safeLatitude = latitude;
    final safeLongitude = longitude;
    if (safeLatitude == null || safeLongitude == null) return null;
    if (!safeLatitude.isFinite || !safeLongitude.isFinite) return null;
    if (safeLatitude == 0 && safeLongitude == 0) return null;
    if (safeLatitude < -90 ||
        safeLatitude > 90 ||
        safeLongitude < -180 ||
        safeLongitude > 180) {
      return null;
    }
    return (latitude: safeLatitude, longitude: safeLongitude);
  }

  bool get hasCoordinates => coordinates != null;

  static const _retailerStopWords = {
    'SDN',
    'BHD',
    'BERHAD',
    'HOLDINGS',
    'HOLDING',
    'ENTERPRISE',
    'ENTERPRISES',
    'TRADING',
    'SUPERMARKET',
    'SUPERSTORE',
    'SUPER',
    'PASAR',
    'RAYA',
    'PASARAYA',
    'MARKET',
    'MINI',
    'STORE',
    'STORES',
    'OUTLET',
    'SHOP',
    'SHOPS',
    'GROUP',
    'CORPORATION',
  };

  /// Best-effort store brand/chain name derived from the official premise
  /// name. PriceCatcher does not ship a separate retailer field, so the
  /// leading brand tokens are extracted (for example "AEON BIG",
  /// "99 SPEED MART", "LOTUS'S"). Used only to populate the retailer filter
  /// options dynamically from the loaded premise data.
  String get retailer {
    final cleaned = premiseName
        .toUpperCase()
        .replaceAll(RegExp(r'\s*\([^)]*\)\s*'), ' ')
        .replaceAll(RegExp(r"[^A-Z0-9' .&/-]"), ' ')
        .trim();
    final tokens = cleaned
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return premiseName.trim();
    final brand = <String>[];
    for (final token in tokens) {
      if (brand.isNotEmpty && _retailerStopWords.contains(token)) break;
      brand.add(token);
      if (brand.length >= 3) break;
    }
    return brand.join(' ');
  }

  Premise withDistance(double? value) => Premise(
    premiseCode: premiseCode,
    premiseName: premiseName,
    address: address,
    postcode: postcode,
    premiseType: premiseType,
    district: district,
    state: state,
    latitude: latitude,
    longitude: longitude,
    distanceKm: value,
    coordinateAccuracy: coordinateAccuracy,
  );

  Premise withResolvedLocation(ResolvedPremiseLocation location) => Premise(
    premiseCode: premiseCode,
    premiseName: premiseName,
    address: address,
    postcode: postcode,
    premiseType: premiseType,
    district: district,
    state: state,
    latitude: location.latitude,
    longitude: location.longitude,
    distanceKm: distanceKm,
    coordinateAccuracy: location.matchConfidence,
  );

  factory Premise.fromJson(Map<String, dynamic> json) => Premise(
    premiseCode: json['premiseCode'] as int,
    premiseName: json['premiseName'] as String,
    address: json['address'] as String,
    postcode: json['postcode'] as String?,
    premiseType: json['premiseType'] as String,
    district: json['district'] as String,
    state: json['state'] as String,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    coordinateAccuracy: json['coordinateAccuracy'] as String?,
  );
}

class ResolvedPremiseLocation {
  const ResolvedPremiseLocation({
    required this.resolutionStatus,
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    this.matchConfidence,
    this.partialMatch,
    this.locationType,
  });
  final String resolutionStatus;

  final double? latitude;
  final double? longitude;
  final String? formattedAddress;
  final String? matchConfidence;
  final bool? partialMatch;
  final String? locationType;

  ({double latitude, double longitude})? get coordinates {
    final safeLatitude = latitude;
    final safeLongitude = longitude;
    if (safeLatitude == null || safeLongitude == null) return null;
    if (!safeLatitude.isFinite || !safeLongitude.isFinite) return null;
    if (safeLatitude < -90 ||
        safeLatitude > 90 ||
        safeLongitude < -180 ||
        safeLongitude > 180) {
      return null;
    }
    return (latitude: safeLatitude, longitude: safeLongitude);
  }

  bool get hasValidMalaysianCoordinates {
    final value = coordinates;
    if (value == null) return false;
    return value.latitude >= 0.5 &&
        value.latitude <= 7.5 &&
        value.longitude >= 99 &&
        value.longitude <= 120.5;
  }

  bool get isResolved =>
      resolutionStatus == 'resolved' && hasValidMalaysianCoordinates;

  bool get isPreciseMatch {
    if (!isResolved || partialMatch == true) return false;
    final type = locationType?.trim().toUpperCase();
    if (type == 'ROOFTOP') return true;
    if (type == 'RANGE_INTERPOLATED' && matchConfidence == 'high') return true;
    return type == null && matchConfidence == 'high';
  }

  factory ResolvedPremiseLocation.fromJson(Map<String, dynamic> json) =>
      ResolvedPremiseLocation(
        resolutionStatus: json['resolutionStatus'] as String,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        formattedAddress: json['formattedAddress'] as String?,
        matchConfidence: json['matchConfidence'] as String?,
        partialMatch: json['partialMatch'] as bool?,
        locationType: json['locationType'] as String?,
      );
}

class PremisePage {
  const PremisePage({required this.premises, required this.total});
  final List<Premise> premises;
  final int total;
}

class PremiseFilterGroup {
  const PremiseFilterGroup({required this.state, required this.districts});
  final String state;
  final List<String> districts;

  factory PremiseFilterGroup.fromJson(Map<String, dynamic> json) =>
      PremiseFilterGroup(
        state: json['state'] as String,
        districts: (json['districts'] as List<dynamic>).cast<String>(),
      );
}

String formatDistance(double? distanceKm) {
  if (distanceKm == null) return 'Distance unavailable';
  if (distanceKm < 1) return '${(distanceKm * 1000).round()} m away';
  return '${distanceKm.toStringAsFixed(distanceKm < 10 ? 1 : 0)} km away';
}

/// Compact distance label for store list rows. Callers omit the label entirely
/// when the distance is unknown instead of showing a placeholder like
/// "Distance unavailable" or "Official coordinates unavailable".
String formatDistanceCompact(double distanceKm) {
  if (distanceKm < 1) return '${(distanceKm * 1000).round()} m';
  return '${distanceKm.toStringAsFixed(distanceKm < 10 ? 1 : 0)} km';
}

/// Result of the backend `resolve-navigation` endpoint. A confirmed result
/// carries the Google Place ID needed to open driving directions directly to
/// the exact store branch.
class ResolvedPremiseNavigation {
  const ResolvedPremiseNavigation({
    required this.confirmed,
    this.placeId,
    this.displayName,
    this.formattedAddress,
    this.latitude,
    this.longitude,
  });

  final bool confirmed;
  final String? placeId;
  final String? displayName;
  final String? formattedAddress;
  final double? latitude;
  final double? longitude;

  factory ResolvedPremiseNavigation.fromJson(Map<String, dynamic> json) =>
      ResolvedPremiseNavigation(
        confirmed: json['confirmed'] as bool? ?? false,
        placeId: json['placeId'] as String?,
        displayName: json['displayName'] as String?,
        formattedAddress: json['formattedAddress'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}
