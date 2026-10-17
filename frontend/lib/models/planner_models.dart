import 'price_reliability.dart';

class MonthlyBudget {
  const MonthlyBudget({required this.month, required this.amount});

  final String month;
  final double amount;

  factory MonthlyBudget.fromJson(Map<String, dynamic> json) => MonthlyBudget(
    month: json['month'] as String,
    amount: (json['amount'] as num).toDouble(),
  );
}

class ShoppingListSummary {
  const ShoppingListSummary({
    required this.shoppingListId,
    required this.name,
    required this.itemCount,
    required this.completedItemCount,
    required this.unavailableItemCount,
    required this.estimatedTotal,
    this.createdAt,
    this.updatedAt,
  });

  final String shoppingListId;
  final String name;
  final int itemCount;
  final int completedItemCount;
  final int unavailableItemCount;
  final double estimatedTotal;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ShoppingListSummary.fromJson(Map<String, dynamic> json) =>
      ShoppingListSummary(
        shoppingListId: json['shoppingListId'] as String,
        name: json['name'] as String,
        itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
        completedItemCount: (json['completedItemCount'] as num?)?.toInt() ?? 0,
        unavailableItemCount:
            (json['unavailableItemCount'] as num?)?.toInt() ?? 0,
        estimatedTotal: (json['estimatedTotal'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );
}

class PlannerOverview {
  const PlannerOverview({
    required this.month,
    required this.lists,
    required this.plannerEstimatedTotal,
    required this.budget,
    required this.remainingBudget,
    required this.overBudget,
  });

  final String month;
  final List<ShoppingListSummary> lists;
  final double plannerEstimatedTotal;
  final MonthlyBudget? budget;
  final double? remainingBudget;
  final bool overBudget;

  factory PlannerOverview.fromJson(Map<String, dynamic> json) {
    final budgetJson = json['currentMonthlyBudget'] as Map<String, dynamic>?;
    return PlannerOverview(
      month: json['month'] as String,
      lists: (json['activeShoppingLists'] as List<dynamic>)
          .map(
            (value) =>
                ShoppingListSummary.fromJson(value as Map<String, dynamic>),
          )
          .toList(growable: false),
      plannerEstimatedTotal: (json['plannerEstimatedTotal'] as num).toDouble(),
      budget: budgetJson == null ? null : MonthlyBudget.fromJson(budgetJson),
      remainingBudget: (json['remainingBudget'] as num?)?.toDouble(),
      overBudget: json['overBudget'] as bool,
    );
  }
}

class CheapestPremise {
  const CheapestPremise({
    required this.premiseName,
    this.premiseCode,
    this.address,
    this.district,
    this.state,
  });
  final String premiseName;
  final int? premiseCode;
  final String? address;
  final String? district;
  final String? state;

  factory CheapestPremise.fromJson(Map<String, dynamic> json) =>
      CheapestPremise(
        premiseName: json['premiseName'] as String,
        premiseCode: (json['premiseCode'] as num?)?.toInt(),
        address: json['address'] as String?,
        district: json['district'] as String?,
        state: json['state'] as String?,
      );
}

class ShoppingListItem {
  const ShoppingListItem({
    required this.listItemId,
    required this.itemCode,
    required this.itemName,
    required this.unit,
    required this.quantity,
    required this.isChecked,
    required this.bestPrice,
    required this.estimatedLineTotal,
    required this.cheapestPremise,
    this.reliability = PriceReliability.unavailable,
  });

  final String listItemId;
  final int itemCode;
  final String itemName;
  final String unit;
  final double quantity;
  final bool isChecked;
  final double? bestPrice;
  final double? estimatedLineTotal;
  final CheapestPremise? cheapestPremise;
  final PriceReliability reliability;
  bool get isPriceAvailable => bestPrice != null;

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    final premise = json['cheapestPremise'] as Map<String, dynamic>?;
    return ShoppingListItem(
      listItemId: json['listItemId'] as String,
      itemCode: json['itemCode'] as int,
      itemName: json['itemName'] as String,
      unit: json['unit'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      isChecked: json['isChecked'] as bool,
      bestPrice: (json['bestPrice'] as num?)?.toDouble(),
      estimatedLineTotal: (json['estimatedLineTotal'] as num?)?.toDouble(),
      cheapestPremise: premise == null
          ? null
          : CheapestPremise.fromJson(premise),
      reliability: PriceReliability.fromJson(
        json['reliability'] as Map<String, dynamic>?,
      ),
    );
  }
}

class BasketTemplateItem {
  const BasketTemplateItem({
    required this.itemCode,
    required this.itemName,
    required this.unit,
    required this.quantity,
    required this.bestPrice,
    required this.estimatedLineTotal,
  });
  final int itemCode;
  final String itemName;
  final String unit;
  final double quantity;
  final double? bestPrice;
  final double? estimatedLineTotal;

  factory BasketTemplateItem.fromJson(Map<String, dynamic> json) =>
      BasketTemplateItem(
        itemCode: (json['itemCode'] as num).toInt(),
        itemName: json['itemName'] as String,
        unit: json['unit'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        bestPrice: (json['bestPrice'] as num?)?.toDouble(),
        estimatedLineTotal: (json['estimatedLineTotal'] as num?)?.toDouble(),
      );
}

class BasketTemplate {
  const BasketTemplate({
    required this.templateKey,
    required this.name,
    required this.household,
    required this.itemCount,
    required this.estimatedTotal,
    required this.unavailableItemCount,
    required this.reliability,
    required this.items,
  });
  final String templateKey;
  final String name;
  final String household;
  final int itemCount;
  final double estimatedTotal;
  final int unavailableItemCount;
  final PriceReliability reliability;
  final List<BasketTemplateItem> items;

  factory BasketTemplate.fromJson(Map<String, dynamic> json) => BasketTemplate(
    templateKey: json['templateKey'] as String,
    name: json['name'] as String,
    household: json['household'] as String,
    itemCount: (json['itemCount'] as num).toInt(),
    estimatedTotal: (json['estimatedTotal'] as num).toDouble(),
    unavailableItemCount: (json['unavailableItemCount'] as num).toInt(),
    reliability: PriceReliability.fromJson(
      json['reliability'] as Map<String, dynamic>?,
    ),
    items: (json['items'] as List<dynamic>)
        .map(
          (value) => BasketTemplateItem.fromJson(value as Map<String, dynamic>),
        )
        .toList(growable: false),
  );
}

class ShoppingListDetail {
  const ShoppingListDetail({
    required this.shoppingListId,
    required this.name,
    required this.itemCount,
    required this.completedItemCount,
    required this.estimatedTotal,
    required this.items,
    this.createdAt,
    this.updatedAt,
  });

  final String shoppingListId;
  final String name;
  final int itemCount;
  final int completedItemCount;
  final double estimatedTotal;
  final List<ShoppingListItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ShoppingListDetail.fromJson(Map<String, dynamic> json) =>
      ShoppingListDetail(
        shoppingListId: json['shoppingListId'] as String,
        name: json['name'] as String,
        itemCount: (json['itemCount'] as num).toInt(),
        completedItemCount: (json['completedItemCount'] as num).toInt(),
        estimatedTotal: (json['estimatedTotal'] as num).toDouble(),
        items: (json['items'] as List<dynamic>)
            .map(
              (value) =>
                  ShoppingListItem.fromJson(value as Map<String, dynamic>),
            )
            .toList(growable: false),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );
}
