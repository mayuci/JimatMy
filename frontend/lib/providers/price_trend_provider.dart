import 'package:flutter/foundation.dart';

import '../models/price_trend.dart';
import '../services/api_service.dart';

enum TrendRange { sevenDays, thirtyDays, threeMonths, sixMonths }

extension TrendRangeLabel on TrendRange {
  String get label => switch (this) {
    TrendRange.sevenDays => '7 days',
    TrendRange.thirtyDays => '30 days',
    TrendRange.threeMonths => '3 months',
    TrendRange.sixMonths => '6 months',
  };
}

class PriceTrendProvider extends ChangeNotifier {
  PriceTrendProvider(this._apiService, this.itemCode);

  final ApiService _apiService;
  final int itemCode;
  int _requestVersion = 0;
  PriceTrend? _allTrend;

  TrendRange selectedRange = TrendRange.threeMonths;
  String? errorMessage;
  bool isLoading = false;

  PriceTrend? get trend {
    final source = _allTrend;
    if (source == null || source.points.isEmpty) return source;
    final latest = source.points.last.recordDate;
    final from = _rangeStart(latest, selectedRange);
    return PriceTrend(
      item: source.item,
      points: source.points
          .where((point) => !point.recordDate.isBefore(from))
          .toList(growable: false),
    );
  }

  bool isRangeAvailable(TrendRange range) {
    final source = _allTrend;
    if (source == null || source.points.length < 2) return false;
    final coverage = source.points.last.recordDate
        .difference(source.points.first.recordDate)
        .inDays;
    final requiredCoverage = switch (range) {
      TrendRange.sevenDays => 5,
      TrendRange.thirtyDays => 21,
      TrendRange.threeMonths => 60,
      TrendRange.sixMonths => 150,
    };
    if (coverage < requiredCoverage) return false;
    final from = _rangeStart(source.points.last.recordDate, range);
    return source.points
            .where((point) => !point.recordDate.isBefore(from))
            .length >=
        2;
  }

  Future<void> load() => _fetch();

  void selectRange(TrendRange range) {
    if (selectedRange == range || !isRangeAvailable(range)) return;
    selectedRange = range;
    notifyListeners();
  }

  Future<void> retry() => _fetch();

  Future<void> _fetch() async {
    final version = ++_requestVersion;
    isLoading = true;
    errorMessage = null;
    _allTrend = null;
    notifyListeners();
    try {
      final result = await _apiService.getPriceTrend(itemCode);
      if (version != _requestVersion) return;
      _allTrend = result;
      if (!isRangeAvailable(selectedRange)) {
        selectedRange = TrendRange.values.firstWhere(
          isRangeAvailable,
          orElse: () => selectedRange,
        );
      }
    } on ApiException catch (error) {
      if (version != _requestVersion) return;
      errorMessage = error.message;
    } finally {
      if (version == _requestVersion) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  DateTime _rangeStart(DateTime latest, TrendRange range) => switch (range) {
    TrendRange.sevenDays => latest.subtract(const Duration(days: 6)),
    TrendRange.thirtyDays => latest.subtract(const Duration(days: 29)),
    TrendRange.threeMonths => _monthsBefore(latest, 3),
    TrendRange.sixMonths => _monthsBefore(latest, 6),
  };

  DateTime _monthsBefore(DateTime date, int months) {
    final targetMonth = DateTime(date.year, date.month - months);
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    return DateTime(
      targetMonth.year,
      targetMonth.month,
      date.day > lastDay ? lastDay : date.day,
    );
  }
}
