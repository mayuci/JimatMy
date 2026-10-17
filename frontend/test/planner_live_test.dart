import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/services/api_service.dart';

void main() {
  const runLiveTests = bool.fromEnvironment('RUN_PLANNER_LIVE_TEST');

  test(
    'planner flow works against the live API',
    () async {
      final api = ApiService();
      String? listId;
      try {
        await api.checkHealth();
        final created = await api.createShoppingList(
          'Flutter live verification ${DateTime.now().millisecondsSinceEpoch}',
        );
        listId = created.shoppingListId;

        await api.addShoppingListItem(listId, 1, 1);
        var detail = await api.getShoppingList(listId);
        expect(detail.items.single.itemCode, 1);
        expect(detail.items.single.bestPrice, isNotNull);

        final itemId = detail.items.single.listItemId;
        await api.updateShoppingListItem(listId, itemId, quantity: 2);
        await api.updateShoppingListItem(listId, itemId, isChecked: true);
        detail = await api.getShoppingList(listId);
        expect(detail.items.single.quantity, 2);
        expect(detail.items.single.isChecked, isTrue);

        final lowBudget = detail.estimatedTotal > 0
            ? detail.estimatedTotal / 2
            : 1.0;
        final now = DateTime.now();
        final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
        await api.setBudget(month, lowBudget);
        final overview = await api.getPlannerOverview();
        expect(overview.overBudget, isTrue);
        expect(overview.remainingBudget, isNegative);

        await api.deleteShoppingListItem(listId, itemId);
        await api.deleteShoppingList(listId);
        listId = null;
      } finally {
        if (listId != null) {
          await api.deleteShoppingList(listId);
        }
      }
    },
    skip: runLiveTests
        ? false
        : 'Set RUN_PLANNER_LIVE_TEST for live API verification.',
  );
}
