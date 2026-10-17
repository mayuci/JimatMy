class PriceReliability {
  const PriceReliability({
    required this.latestRecordDate,
    required this.ageDays,
    required this.premiseCount,
    required this.freshnessStatus,
    required this.coverageStatus,
  });

  final DateTime? latestRecordDate;
  final int? ageDays;
  final int premiseCount;
  final String freshnessStatus;
  final String coverageStatus;

  factory PriceReliability.fromJson(
    Map<String, dynamic>? json, {
    String? fallbackRecordDate,
    int fallbackPremiseCount = 0,
  }) {
    if (json == null) {
      return PriceReliability.fromRecordDate(
        fallbackRecordDate,
        premiseCount: fallbackPremiseCount,
      );
    }
    return PriceReliability(
      latestRecordDate: DateTime.tryParse(
        json['latestRecordDate'] as String? ?? '',
      ),
      ageDays: (json['ageDays'] as num?)?.toInt(),
      premiseCount: (json['premiseCount'] as num?)?.toInt() ?? 0,
      freshnessStatus: json['freshnessStatus'] as String? ?? 'unavailable',
      coverageStatus: json['coverageStatus'] as String? ?? 'unavailable',
    );
  }

  factory PriceReliability.fromRecordDate(
    String? recordDate, {
    int premiseCount = 0,
    DateTime? now,
  }) {
    final parsed = DateTime.tryParse(recordDate ?? '');
    if (parsed == null) return PriceReliability.unavailable;
    final today = now ?? DateTime.now();
    final dateOnly = DateTime.utc(parsed.year, parsed.month, parsed.day);
    final todayOnly = DateTime.utc(today.year, today.month, today.day);
    final ageDays = todayOnly.difference(dateOnly).inDays.clamp(0, 999999);
    final freshness = ageDays <= 7
        ? 'fresh'
        : ageDays <= 30
        ? 'recent'
        : 'old';
    final coverage = premiseCount <= 0
        ? 'unavailable'
        : premiseCount < 5
        ? 'limited'
        : premiseCount < 20
        ? 'moderate'
        : 'wide';
    return PriceReliability(
      latestRecordDate: parsed,
      ageDays: ageDays,
      premiseCount: premiseCount,
      freshnessStatus: freshness,
      coverageStatus: coverage,
    );
  }

  static const unavailable = PriceReliability(
    latestRecordDate: null,
    ageDays: null,
    premiseCount: 0,
    freshnessStatus: 'unavailable',
    coverageStatus: 'unavailable',
  );
}
