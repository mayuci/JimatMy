enum BestPlacesCoverage { all, complete, incomplete }

enum BestPlacesSort { priceAsc, priceDesc, coverage }

extension BestPlacesCoverageValue on BestPlacesCoverage {
  String get apiValue => switch (this) {
    BestPlacesCoverage.all => 'all',
    BestPlacesCoverage.complete => 'complete',
    BestPlacesCoverage.incomplete => 'incomplete',
  };

  String get label => switch (this) {
    BestPlacesCoverage.all => 'All shops',
    BestPlacesCoverage.complete => 'Complete basket',
    BestPlacesCoverage.incomplete => 'Incomplete',
  };
}

extension BestPlacesSortValue on BestPlacesSort {
  String get apiValue => switch (this) {
    BestPlacesSort.priceAsc => 'price_asc',
    BestPlacesSort.priceDesc => 'price_desc',
    BestPlacesSort.coverage => 'coverage',
  };

  String get label => switch (this) {
    BestPlacesSort.priceAsc => 'Lowest total',
    BestPlacesSort.priceDesc => 'Highest total',
    BestPlacesSort.coverage => 'Best coverage',
  };
}

class BestPlacesFilters {
  const BestPlacesFilters({
    this.coverage = BestPlacesCoverage.all,
    this.sort = BestPlacesSort.priceAsc,
    this.state,
    this.district,
    this.maxTotal,
    this.latitude,
    this.longitude,
    this.radiusKm,
  });

  final BestPlacesCoverage coverage;
  final BestPlacesSort sort;
  final String? state;
  final String? district;
  final double? maxTotal;
  final double? latitude;
  final double? longitude;
  final int? radiusKm;

  bool get hasLocation => latitude != null && longitude != null;

  bool get isDefault =>
      coverage == BestPlacesCoverage.all &&
      sort == BestPlacesSort.priceAsc &&
      state == null &&
      district == null &&
      maxTotal == null &&
      !hasLocation &&
      radiusKm == null;
}

class RequestedBasketItem {
  const RequestedBasketItem({
    required this.itemCode,
    required this.itemName,
    required this.unit,
    required this.requestedQuantity,
  });

  final int itemCode;
  final String itemName;
  final String unit;
  final double requestedQuantity;

  factory RequestedBasketItem.fromJson(Map<String, dynamic> json) =>
      RequestedBasketItem(
        itemCode: (json['itemCode'] as num).toInt(),
        itemName: json['itemName'] as String,
        unit: json['unit'] as String,
        requestedQuantity: (json['requestedQuantity'] as num).toDouble(),
      );
}

class BasketStoreItem extends RequestedBasketItem {
  const BasketStoreItem({
    required super.itemCode,
    required super.itemName,
    required super.unit,
    required super.requestedQuantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.priceDate,
  });

  final double unitPrice;
  final double lineTotal;
  final String priceDate;

  factory BasketStoreItem.fromJson(Map<String, dynamic> json) =>
      BasketStoreItem(
        itemCode: (json['itemCode'] as num).toInt(),
        itemName: json['itemName'] as String,
        unit: json['unit'] as String,
        requestedQuantity: (json['requestedQuantity'] as num).toDouble(),
        unitPrice: (json['unitPrice'] as num).toDouble(),
        lineTotal: (json['lineTotal'] as num).toDouble(),
        priceDate: json['priceDate'] as String,
      );
}

class MissingBasketItem {
  const MissingBasketItem({
    required this.itemCode,
    required this.itemName,
    required this.requestedQuantity,
  });

  final int itemCode;
  final String itemName;
  final double requestedQuantity;

  factory MissingBasketItem.fromJson(Map<String, dynamic> json) =>
      MissingBasketItem(
        itemCode: (json['itemCode'] as num).toInt(),
        itemName: json['itemName'] as String,
        requestedQuantity: (json['requestedQuantity'] as num).toDouble(),
      );
}

class BasketStore {
  const BasketStore({
    required this.premiseCode,
    required this.premiseName,
    required this.premiseType,
    required this.address,
    required this.district,
    required this.state,
    required this.coveredItemCount,
    required this.totalItemCount,
    required this.isComplete,
    required this.basketTotal,
    required this.partialTotal,
    required this.latestPriceDate,
    required this.items,
    required this.missingItems,
    this.distanceKm,
  });

  final int premiseCode;
  final String premiseName;
  final String premiseType;
  final String address;
  final String district;
  final String state;
  final int coveredItemCount;
  final int totalItemCount;
  final bool isComplete;
  final double? basketTotal;
  final double? partialTotal;
  final String? latestPriceDate;
  final List<BasketStoreItem> items;
  final List<MissingBasketItem> missingItems;
  final double? distanceKm;

  double? get displayedTotal => isComplete ? basketTotal : partialTotal;

  factory BasketStore.fromJson(Map<String, dynamic> json) => BasketStore(
    premiseCode: (json['premiseCode'] as num).toInt(),
    premiseName: json['premiseName'] as String,
    premiseType: json['premiseType'] as String,
    address: json['address'] as String,
    district: json['district'] as String,
    state: json['state'] as String,
    coveredItemCount: (json['coveredItemCount'] as num).toInt(),
    totalItemCount: (json['totalItemCount'] as num).toInt(),
    isComplete: json['isComplete'] as bool,
    basketTotal: (json['basketTotal'] as num?)?.toDouble(),
    partialTotal: (json['partialTotal'] as num?)?.toDouble(),
    latestPriceDate: json['latestPriceDate'] as String?,
    items: (json['items'] as List<dynamic>)
        .map((value) => BasketStoreItem.fromJson(value as Map<String, dynamic>))
        .toList(growable: false),
    missingItems: (json['missingItems'] as List<dynamic>)
        .map(
          (value) => MissingBasketItem.fromJson(value as Map<String, dynamic>),
        )
        .toList(growable: false),
    distanceKm: (json['distanceKm'] as num?)?.toDouble(),
  );
}

class BestPlacesSummary {
  const BestPlacesSummary({
    required this.totalPremises,
    required this.completePremises,
    required this.incompletePremises,
    required this.lowestCompleteTotal,
    required this.highestCompleteTotal,
  });

  final int totalPremises;
  final int completePremises;
  final double? lowestCompleteTotal;
  final double? highestCompleteTotal;
  final int incompletePremises;

  factory BestPlacesSummary.fromJson(Map<String, dynamic> json) =>
      BestPlacesSummary(
        totalPremises: (json['totalPremises'] as num).toInt(),
        completePremises: (json['completePremises'] as num).toInt(),
        incompletePremises: (json['incompletePremises'] as num).toInt(),
        lowestCompleteTotal: (json['lowestCompleteTotal'] as num?)?.toDouble(),
        highestCompleteTotal: (json['highestCompleteTotal'] as num?)
            ?.toDouble(),
      );
}

class CombinationItem {
  const CombinationItem({
    required this.itemCode,
    required this.itemName,
    required this.requestedQuantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final int itemCode;
  final String itemName;
  final double requestedQuantity;
  final double unitPrice;
  final double lineTotal;

  factory CombinationItem.fromJson(Map<String, dynamic> json) =>
      CombinationItem(
        itemCode: (json['itemCode'] as num).toInt(),
        itemName: json['itemName'] as String,
        requestedQuantity: (json['requestedQuantity'] as num).toDouble(),
        unitPrice: (json['unitPrice'] as num).toDouble(),
        lineTotal: (json['lineTotal'] as num).toDouble(),
      );
}

class CombinationStore {
  const CombinationStore({
    required this.premiseCode,
    required this.premiseName,
    required this.itemTotal,
    required this.items,
  });

  final int premiseCode;
  final String premiseName;
  final double itemTotal;
  final List<CombinationItem> items;

  factory CombinationStore.fromJson(Map<String, dynamic> json) =>
      CombinationStore(
        premiseCode: (json['premiseCode'] as num).toInt(),
        premiseName: json['premiseName'] as String,
        itemTotal: (json['itemTotal'] as num).toDouble(),
        items: (json['items'] as List<dynamic>)
            .map(
              (value) =>
                  CombinationItem.fromJson(value as Map<String, dynamic>),
            )
            .toList(growable: false),
      );
}

class TwoStoreCombination {
  const TwoStoreCombination({
    required this.basketTotal,
    required this.savingVsBestSingle,
    required this.stores,
  });

  final double basketTotal;
  final double? savingVsBestSingle;
  final List<CombinationStore> stores;

  factory TwoStoreCombination.fromJson(Map<String, dynamic> json) =>
      TwoStoreCombination(
        basketTotal: (json['basketTotal'] as num).toDouble(),
        savingVsBestSingle: (json['savingVsBestSingle'] as num?)?.toDouble(),
        stores: (json['stores'] as List<dynamic>)
            .map(
              (value) =>
                  CombinationStore.fromJson(value as Map<String, dynamic>),
            )
            .toList(growable: false),
      );
}

class BestPlacesPagination {
  const BestPlacesPagination({
    required this.page,
    required this.limit,
    required this.totalResults,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int totalResults;
  final int totalPages;

  factory BestPlacesPagination.fromJson(Map<String, dynamic> json) =>
      BestPlacesPagination(
        page: (json['page'] as num).toInt(),
        limit: (json['limit'] as num).toInt(),
        totalResults: (json['totalResults'] as num).toInt(),
        totalPages: (json['totalPages'] as num).toInt(),
      );
}

class DistrictOption {
  const DistrictOption({required this.state, required this.district});
  final String state;
  final String district;

  factory DistrictOption.fromJson(Map<String, dynamic> json) => DistrictOption(
    state: json['state'] as String,
    district: json['district'] as String,
  );
}

class BestPlacesFilterOptions {
  const BestPlacesFilterOptions({
    required this.states,
    required this.districts,
  });
  final List<String> states;
  final List<DistrictOption> districts;

  factory BestPlacesFilterOptions.fromJson(Map<String, dynamic> json) =>
      BestPlacesFilterOptions(
        states: (json['states'] as List<dynamic>).cast<String>(),
        districts: (json['districts'] as List<dynamic>)
            .map(
              (value) => DistrictOption.fromJson(value as Map<String, dynamic>),
            )
            .toList(growable: false),
      );
}

class BestPlacesResponse {
  const BestPlacesResponse({
    required this.listId,
    required this.listName,
    required this.itemCount,
    required this.requestedItems,
    required this.summary,
    required this.stores,
    required this.twoStoreCombination,
    required this.pagination,
    required this.filterOptions,
  });

  final String listId;
  final String listName;
  final int itemCount;
  final List<RequestedBasketItem> requestedItems;
  final BestPlacesSummary summary;
  final List<BasketStore> stores;
  final TwoStoreCombination? twoStoreCombination;
  final BestPlacesPagination pagination;
  final BestPlacesFilterOptions filterOptions;

  bool get hasNextPage => pagination.page < pagination.totalPages;
  bool get hasNoActiveItems => itemCount == 0;
  bool get hasNoPriceData => itemCount > 0 && summary.totalPremises == 0;

  factory BestPlacesResponse.fromJson(Map<String, dynamic> json) =>
      BestPlacesResponse(
        listId: json['listId'] as String,
        listName: json['listName'] as String,
        itemCount: (json['itemCount'] as num).toInt(),
        requestedItems: (json['requestedItems'] as List<dynamic>)
            .map(
              (value) =>
                  RequestedBasketItem.fromJson(value as Map<String, dynamic>),
            )
            .toList(growable: false),
        summary: BestPlacesSummary.fromJson(
          json['summary'] as Map<String, dynamic>,
        ),
        stores: (json['stores'] as List<dynamic>)
            .map((value) => BasketStore.fromJson(value as Map<String, dynamic>))
            .toList(growable: false),
        twoStoreCombination: json['twoStoreCombination'] == null
            ? null
            : TwoStoreCombination.fromJson(
                json['twoStoreCombination'] as Map<String, dynamic>,
              ),
        pagination: BestPlacesPagination.fromJson(
          json['pagination'] as Map<String, dynamic>,
        ),
        filterOptions: BestPlacesFilterOptions.fromJson(
          json['filterOptions'] as Map<String, dynamic>,
        ),
      );
}
