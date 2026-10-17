import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/models/best_places_models.dart';

Map<String, dynamic> _json() => {
  'listId': 'list-1',
  'listName': 'Weekly groceries',
  'itemCount': 2,
  'requestedItems': [
    {
      'itemCode': 1,
      'itemName': '100 PLUS (ORIGINAL)',
      'unit': '1.5 LITER',
      'requestedQuantity': 1,
    },
    {
      'itemCode': 2,
      'itemName': 'AYAM BERSIH - STANDARD',
      'unit': '1 KG',
      'requestedQuantity': 1,
    },
  ],
  'summary': {
    'totalPremises': 2,
    'completePremises': 1,
    'incompletePremises': 1,
    'lowestCompleteTotal': 10.85,
    'highestCompleteTotal': 10.85,
  },
  'stores': [
    {
      'premiseCode': 10,
      'premiseName': 'AEON BIG',
      'premiseType': 'HYPERMARKET',
      'address': 'Official address',
      'district': 'Petaling',
      'state': 'Selangor',
      'coveredItemCount': 2,
      'totalItemCount': 2,
      'isComplete': true,
      'basketTotal': 10.85,
      'partialTotal': null,
      'latestPriceDate': '2026-07-31',
      'items': [
        {
          'itemCode': 1,
          'itemName': '100 PLUS (ORIGINAL)',
          'unit': '1.5 LITER',
          'requestedQuantity': 1,
          'unitPrice': 2.9,
          'lineTotal': 2.9,
          'priceDate': '2026-07-31',
          'available': true,
        },
        {
          'itemCode': 2,
          'itemName': 'AYAM BERSIH - STANDARD',
          'unit': '1 KG',
          'requestedQuantity': 1,
          'unitPrice': 7.95,
          'lineTotal': 7.95,
          'priceDate': '2026-07-31',
          'available': true,
        },
      ],
      'missingItems': <dynamic>[],
    },
    {
      'premiseCode': 11,
      'premiseName': 'ECONSAVE',
      'premiseType': 'SUPERMARKET',
      'address': 'Other address',
      'district': 'Klang',
      'state': 'Selangor',
      'coveredItemCount': 1,
      'totalItemCount': 2,
      'isComplete': false,
      'basketTotal': null,
      'partialTotal': 2.9,
      'latestPriceDate': '2026-07-30',
      'items': [
        {
          'itemCode': 1,
          'itemName': '100 PLUS (ORIGINAL)',
          'unit': '1.5 LITER',
          'requestedQuantity': 1,
          'unitPrice': 2.9,
          'lineTotal': 2.9,
          'priceDate': '2026-07-30',
          'available': true,
        },
      ],
      'missingItems': [
        {
          'itemCode': 2,
          'itemName': 'AYAM BERSIH - STANDARD',
          'requestedQuantity': 1,
        },
      ],
    },
  ],
  'twoStoreCombination': null,
  'pagination': {'page': 1, 'limit': 20, 'totalResults': 2, 'totalPages': 1},
  'filterOptions': {
    'states': ['Selangor'],
    'districts': [
      {'state': 'Selangor', 'district': 'Klang'},
      {'state': 'Selangor', 'district': 'Petaling'},
    ],
  },
};

void main() {
  test('typed response keeps requested quantities and complete totals', () {
    final response = BestPlacesResponse.fromJson(_json());

    expect(response.requestedItems.map((item) => item.requestedQuantity), [
      1,
      1,
    ]);
    expect(response.stores.first.basketTotal, 10.85);
    expect(response.stores.first.partialTotal, isNull);
    expect(response.stores.first.items.last.lineTotal, 7.95);
  });

  test(
    'incomplete response uses partial total and preserves missing items',
    () {
      final response = BestPlacesResponse.fromJson(_json());
      final incomplete = response.stores.last;

      expect(incomplete.isComplete, isFalse);
      expect(incomplete.basketTotal, isNull);
      expect(incomplete.partialTotal, 2.9);
      expect(incomplete.missingItems.single.itemName, 'AYAM BERSIH - STANDARD');
    },
  );

  test('filter API values stay restricted to the documented options', () {
    expect(BestPlacesCoverage.complete.apiValue, 'complete');
    expect(BestPlacesCoverage.incomplete.apiValue, 'incomplete');
    expect(BestPlacesSort.priceAsc.apiValue, 'price_asc');
    expect(BestPlacesSort.priceDesc.apiValue, 'price_desc');
    expect(BestPlacesSort.coverage.apiValue, 'coverage');
  });
}
