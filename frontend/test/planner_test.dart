import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/models/auth_user.dart';
import 'package:jimatmy/models/planner_models.dart';
import 'package:jimatmy/providers/shopping_list_provider.dart';
import 'package:jimatmy/providers/auth_provider.dart';
import 'package:jimatmy/providers/planner_provider.dart';
import 'package:jimatmy/screens/planner_screen.dart';
import 'package:jimatmy/services/api_service.dart';
import 'package:jimatmy/widgets/budget_summary_widget.dart';
import 'package:jimatmy/widgets/shopping_list_summary_widget.dart';
import 'package:jimatmy/widgets/shopping_list_item_widget.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('budget card shows remaining and over-budget warning', (
    tester,
  ) async {
    final overview = PlannerOverview(
      month: '2026-08',
      lists: const [],
      plannerEstimatedTotal: 15.90,
      budget: const MonthlyBudget(month: '2026-08', amount: 10),
      remainingBudget: -5.90,
      overBudget: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BudgetSummaryWidget(overview: overview, onEdit: () {}),
        ),
      ),
    );

    expect(find.text('Over budget'), findsOneWidget);
    expect(find.text('Over budget by RM 5.90'), findsOneWidget);
  });

  testWidgets('list items distinguish estimated and unavailable prices', (
    tester,
  ) async {
    const priced = ShoppingListItem(
      listItemId: 'one',
      itemCode: 1,
      itemName: 'AYAM BERSIH - STANDARD',
      unit: '1 kg',
      quantity: 2,
      isChecked: false,
      bestPrice: 7.95,
      estimatedLineTotal: 15.90,
      cheapestPremise: CheapestPremise(premiseName: 'LOTUSS STORES'),
    );
    const unavailable = ShoppingListItem(
      listItemId: 'two',
      itemCode: 2,
      itemName: 'UNAVAILABLE ITEM',
      unit: '1 unit',
      quantity: 1,
      isChecked: false,
      bestPrice: null,
      estimatedLineTotal: null,
      cheapestPremise: null,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              ShoppingListItemWidget(
                item: priced,
                busy: false,
                onCompleted: (_) {},
                onQuantityChanged: (_) {},
                onRemove: () {},
              ),
              ShoppingListItemWidget(
                item: unavailable,
                busy: false,
                onCompleted: (_) {},
                onQuantityChanged: (_) {},
                onRemove: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Line total RM 15.90'), findsOneWidget);
    expect(find.text('Price unavailable'), findsOneWidget);
  });

  test('quantity validation enforces minimum one', () {
    expect(ShoppingListProvider.validateQuantity(0), isNotNull);
    expect(ShoppingListProvider.validateQuantity(0.5), isNotNull);
    expect(ShoppingListProvider.validateQuantity(1), isNull);
    expect(ShoppingListProvider.validateQuantity(2), isNull);
  });

  testWidgets('completed items remain readable and visually dimmed', (
    tester,
  ) async {
    const completed = ShoppingListItem(
      listItemId: 'done',
      itemCode: 1,
      itemName: 'AYAM BERSIH - STANDARD',
      unit: '1 kg',
      quantity: 1,
      isChecked: true,
      bestPrice: 7.95,
      estimatedLineTotal: 7.95,
      cheapestPremise: CheapestPremise(premiseName: 'PASAR PUDU'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShoppingListItemWidget(
            item: completed,
            busy: false,
            onCompleted: (_) {},
            onQuantityChanged: (_) {},
            onRemove: () {},
          ),
        ),
      ),
    );

    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      greaterThan(0.5),
    );
    expect(find.text('AYAM BERSIH - STANDARD'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
  });

  testWidgets('empty list summary has zero completion progress', (
    tester,
  ) async {
    const summary = ShoppingListSummary(
      shoppingListId: 'empty',
      name: 'Weekend groceries',
      itemCount: 0,
      completedItemCount: 0,
      unavailableItemCount: 0,
      estimatedTotal: 0,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShoppingListSummaryWidget(
            list: summary,
            onTap: () {},
            onRename: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    expect(find.text('0 items'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0,
    );
  });

  testWidgets('logged-out planner shows a clear login action', (tester) async {
    final api = ApiService();
    final auth = AuthProvider(api)..isRestoring = false;
    final planner = PlannerProvider(api);
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<PlannerProvider>.value(value: planner),
        ],
        child: const MaterialApp(home: PlannerScreen()),
      ),
    );

    expect(find.text('Sign in to create shopping lists'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Log in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('budget dialog validates, saves and reopens without a disposed '
      'controller error', (tester) async {
    final api = _BudgetApi();
    final auth = AuthProvider(api)..isRestoring = false;
    auth.user = const AuthUser(
      userId: 'u1',
      name: 'Test User',
      email: 'test@example.com',
      createdAt: null,
      updatedAt: null,
    );
    api.setAuthToken('test-token');
    final planner = PlannerProvider(api);
    planner.overview = PlannerOverview(
      month: '2026-08',
      lists: const [],
      plannerEstimatedTotal: 15.90,
      budget: const MonthlyBudget(month: '2026-08', amount: 100),
      remainingBudget: 84.10,
      overBudget: false,
    );

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<PlannerProvider>.value(value: planner),
        ],
        child: const MaterialApp(home: PlannerScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit budget'), findsOneWidget);

    // Open the editor and submit an invalid amount -> validation stays open.
    await tester.tap(find.text('Edit budget'));
    await tester.pumpAndSettle();
    expect(find.text('Edit monthly budget'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pump();
    expect(find.text('Enter a positive RM amount.'), findsOneWidget);
    expect(api.setBudgetCalls, 0);

    // Correct the value and save -> dialog closes and provider updates.
    await tester.enterText(find.byType(TextField), '50.00');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(api.setBudgetCalls, 1);
    expect(find.text('Edit budget'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Reopen (repeated editing) pre-fills the saved value and saves again.
    await tester.tap(find.text('Edit budget'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '50.00',
    );
    await tester.enterText(find.byType(TextField), '75.00');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(api.setBudgetCalls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('budget dialog cancels cleanly and can be reopened', (
    tester,
  ) async {
    final api = _BudgetApi();
    final auth = AuthProvider(api)..isRestoring = false;
    auth.user = const AuthUser(
      userId: 'u1',
      name: 'Test User',
      email: 'test@example.com',
      createdAt: null,
      updatedAt: null,
    );
    api.setAuthToken('test-token');
    final planner = PlannerProvider(api);
    planner.overview = PlannerOverview(
      month: '2026-08',
      lists: const [],
      plannerEstimatedTotal: 15.90,
      budget: const MonthlyBudget(month: '2026-08', amount: 100),
      remainingBudget: 84.10,
      overBudget: false,
    );

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>.value(value: api),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<PlannerProvider>.value(value: planner),
        ],
        child: const MaterialApp(home: PlannerScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Cancel closes the modal without saving or erroring.
    await tester.tap(find.text('Edit budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(api.setBudgetCalls, 0);
    expect(tester.takeException(), isNull);

    // Navigation-away via the back button also cleans up the modal.
    await tester.tap(find.text('Edit budget'));
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();
    expect(api.setBudgetCalls, 0);
    expect(tester.takeException(), isNull);
    expect(find.text('Edit budget'), findsOneWidget);
  });
}

class _BudgetApi extends ApiService {
  double? budgetAmount;
  int setBudgetCalls = 0;

  @override
  Future<List<BasketTemplate>> getBasketTemplates() async => const [];

  @override
  Future<PlannerOverview> getPlannerOverview() async {
    final budget = budgetAmount;
    return PlannerOverview(
      month: '2026-08',
      lists: const [],
      plannerEstimatedTotal: 15.90,
      budget: budget == null
          ? null
          : MonthlyBudget(month: '2026-08', amount: budget),
      remainingBudget: budget == null ? null : budget - 15.90,
      overBudget: budget != null && budget < 15.90,
    );
  }

  @override
  Future<void> setBudget(String month, double amount) async {
    setBudgetCalls += 1;
    budgetAmount = amount;
  }
}
