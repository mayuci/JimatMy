import 'price_reliability.dart';

class LatestPrice {
  const LatestPrice({
    required this.premiseCode,
    required this.premiseName,
    required this.address,
    required this.state,
    required this.district,
    required this.price,
    required this.recordDate,
    this.reliability = PriceReliability.unavailable,
  });

  final int? premiseCode;
  final String premiseName;
  final String address;
  final String state;
  final String district;
  final double price;
  final String recordDate;
  final PriceReliability reliability;

  factory LatestPrice.fromJson(Map<String, dynamic> json) => LatestPrice(
    premiseCode: parsePremiseCode(json['premiseCode']),
    premiseName: json['premiseName'] as String,
    address: json['address'] as String,
    state: json['state'] as String,
    district: json['district'] as String,
    price: (json['price'] as num).toDouble(),
    recordDate: json['recordDate'] as String,
    reliability: PriceReliability.fromJson(
      json['reliability'] as Map<String, dynamic>?,
      fallbackRecordDate: json['recordDate'] as String?,
      fallbackPremiseCount: 1,
    ),
  );
}

int? parsePremiseCode(Object? value) {
  if (value is int) return value > 0 ? value : null;
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    final code = value.toInt();
    return code > 0 ? code : null;
  }
  if (value is String) {
    final code = int.tryParse(value.trim());
    return code != null && code > 0 ? code : null;
  }
  return null;
}
