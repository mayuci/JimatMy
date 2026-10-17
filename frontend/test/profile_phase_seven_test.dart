import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:jimatmy/models/auth_user.dart';
import 'package:jimatmy/models/item.dart';
import 'package:jimatmy/models/user_features.dart';
import 'package:jimatmy/providers/auth_provider.dart';
import 'package:jimatmy/providers/planner_provider.dart';
import 'package:jimatmy/providers/profile_provider.dart';
import 'package:jimatmy/screens/item_detail_screen.dart';
import 'package:jimatmy/screens/profile_screen.dart';
import 'package:jimatmy/services/api_service.dart';
import 'package:jimatmy/widgets/avatar_action_sheet_widget.dart';
import 'package:jimatmy/widgets/profile_avatar_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('guest profile exposes only public account actions', (
    tester,
  ) async {
    final harness = _Harness(authenticated: false);
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    expect(find.text('Save your shopping plans'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('About JimatMY'), findsOneWidget);
    expect(find.text('My Favourites'), findsNothing);
  });

  testWidgets(
    'authenticated profile has required hierarchy without narrow overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = _Harness(
        name:
            'A very long Malaysian consumer profile display name that must fit',
      );
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();

      expect(find.textContaining('Hi, A very long'), findsOneWidget);
      expect(find.text('Compare smarter and save more.'), findsOneWidget);
      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Budget Planner'), findsOneWidget);
      expect(find.text('My Favourites'), findsOneWidget);
      expect(find.text('Recent Views'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('initial fallback and preset selection update the avatar', (
    tester,
  ) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profile-avatar-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose built-in avatar'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Select apple yellow avatar'));
    await tester.pump();
    await tester.tap(find.text('Save avatar'));
    await tester.pumpAndSettle();

    expect(harness.auth.user?.avatarType, 'preset');
    expect(harness.auth.user?.avatarValue, 'apple_yellow');
    expect(find.byIcon(Icons.apple_rounded), findsWidgets);
  });

  testWidgets('cancelling preset selection preserves the stored avatar', (
    tester,
  ) async {
    final harness = _Harness(avatarType: 'preset', avatarValue: 'basket_green');
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-avatar-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose built-in avatar'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Select apple yellow avatar'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(harness.auth.user?.avatarValue, 'basket_green');
  });

  testWidgets('edit profile validates and refreshes the profile header', (
    tester,
  ) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Profile'));
    await tester.pumpAndSettle();
    final nameField = find.widgetWithText(TextFormField, 'Aina');
    await tester.enterText(nameField, '  Nur Aina  ');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Hi, Nur Aina!'), findsOneWidget);
    expect(harness.api.nameUpdateCount, 1);
  });

  testWidgets('failed profile update preserves the saved user and form input', (
    tester,
  ) async {
    final harness = _Harness()..api.failNameUpdate = true;
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Profile'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Aina'),
      'Retry Name',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(harness.auth.user?.name, 'Aina');
    expect(find.text('Retry Name'), findsOneWidget);
    expect(find.text('Profile update failed.'), findsOneWidget);
  });

  testWidgets('budget action uses the existing planner destination callback', (
    tester,
  ) async {
    var plannerOpened = false;
    final harness = _Harness(onOpenPlanner: () => plannerOpened = true);
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Budget Planner'));
    expect(plannerOpened, isTrue);
  });

  testWidgets('favourite and history destinations reopen the real item code', (
    tester,
  ) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Favourites'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).last);
    await tester.pumpAndSettle();
    expect(find.byType(ItemDetailScreen), findsOneWidget);
    expect(
      tester.widget<ItemDetailScreen>(find.byType(ItemDetailScreen)).itemCode,
      1,
    );

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recent views'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).last);
    await tester.pumpAndSettle();
    expect(
      tester.widget<ItemDetailScreen>(find.byType(ItemDetailScreen)).itemCode,
      1,
    );
  });

  testWidgets('profile data is loaded once across rebuilds', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    harness.auth.notifyListeners();
    await tester.pump();
    expect(harness.api.summaryRequests, 1);
    expect(harness.api.favoriteRequests, 1);
    expect(harness.api.historyRequests, 1);
  });

  testWidgets('logout clears authenticated and protected state', (
    tester,
  ) async {
    final harness = _Harness();
    var protectedStateCleared = false;
    harness.auth.onSessionCleared = () => protectedStateCleared = true;
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(harness.auth.user, isNull);
    expect(protectedStateCleared, isTrue);
    expect(find.text('Save your shopping plans'), findsOneWidget);
  });

  testWidgets('oversized upload reports a friendly error before an API call', (
    tester,
  ) async {
    final harness = _Harness();
    final oversized = XFile.fromData(
      Uint8List(5 * 1024 * 1024 + 1),
      mimeType: 'image/png',
      name: 'large.png',
    );
    await tester.pumpWidget(
      harness.app(
        child: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAvatarActionSheet(
                context,
                pickImage: () async => oversized,
              ),
              child: const Text('Change avatar'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Change avatar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload from device'));
    await tester.pumpAndSettle();

    expect(find.textContaining('smaller than 5 MB'), findsOneWidget);
    expect(harness.api.avatarUploadCount, 0);
  });

  testWidgets(
    'valid uploaded image flow updates authenticated avatar metadata',
    (tester) async {
      final harness = _Harness();
      final png = Uint8List.fromList([
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        0,
        0,
        0,
        0,
      ]);
      await harness.auth.uploadAvatar(
        png,
        filename: 'avatar.png',
        mimeType: 'image/png',
      );
      expect(harness.auth.user?.avatarType, 'upload');
      expect(harness.api.avatarUploadCount, 1);
    },
  );

  testWidgets('broken uploaded image renders initial fallback', (tester) async {
    final user = _user(
      avatarType: 'upload',
      avatarValue: '/media/avatars/missing.png',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProfileAvatarWidget(user: user)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
  });
}

class _Harness {
  _Harness({
    this.authenticated = true,
    this.name = 'Aina',
    this.avatarType = 'initial',
    this.avatarValue,
    this.onOpenPlanner,
  }) {
    auth = AuthProvider(api)..isRestoring = false;
    if (authenticated) {
      api.setAuthToken('test-token');
      auth.user = _user(
        name: name,
        avatarType: avatarType,
        avatarValue: avatarValue,
      );
    }
    planner = PlannerProvider(api);
    profile = ProfileProvider(api);
  }

  final bool authenticated;
  final String name;
  final String avatarType;
  final String? avatarValue;
  final VoidCallback? onOpenPlanner;
  final _FakeApi api = _FakeApi();
  late final AuthProvider auth;
  late final PlannerProvider planner;
  late final ProfileProvider profile;

  Widget app({Widget? child}) => MultiProvider(
    providers: [
      Provider<ApiService>.value(value: api),
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<PlannerProvider>.value(value: planner),
      ChangeNotifierProvider<ProfileProvider>.value(value: profile),
    ],
    child: MaterialApp(
      home: child ?? ProfileScreen(onOpenPlanner: onOpenPlanner),
    ),
  );
}

class _FakeApi extends ApiService {
  int summaryRequests = 0;
  int favoriteRequests = 0;
  int historyRequests = 0;
  int nameUpdateCount = 0;
  int avatarUploadCount = 0;
  bool failNameUpdate = false;

  @override
  Future<ProfileSummary> getProfileSummary() async {
    summaryRequests++;
    return const ProfileSummary(
      favoriteItemCount: 1,
      historyCount: 1,
      shoppingListCount: 2,
    );
  }

  @override
  Future<List<FavoriteItem>> getFavoriteItems() async {
    favoriteRequests++;
    return const [
      FavoriteItem(
        itemCode: 1,
        itemName: 'AYAM BERSIH - STANDARD',
        unit: '1kg',
        itemGroup: 'BARANGAN SEGAR',
        itemCategory: 'AYAM',
        lowestPrice: 8.99,
        premiseCount: 4,
      ),
    ];
  }

  @override
  Future<List<SearchHistoryEntry>> getSearchHistory() async {
    historyRequests++;
    return [
      SearchHistoryEntry(
        historyId: 'history-1',
        itemCode: 1,
        itemName: 'AYAM BERSIH - STANDARD',
        unit: '1kg',
        itemGroup: 'BARANGAN SEGAR',
        itemCategory: 'AYAM',
        lastViewedAt: DateTime(2026, 8, 30, 10, 30),
      ),
    ];
  }

  @override
  Future<AuthUser> updateCurrentUserName(String name) async {
    nameUpdateCount++;
    if (failNameUpdate) throw const ApiException('Profile update failed.');
    return _user(name: name);
  }

  @override
  Future<AuthUser> updateCurrentUser({
    String? name,
    String? avatarType,
    String? avatarValue,
  }) async {
    return _user(
      name: name ?? 'Aina',
      avatarType: avatarType ?? 'initial',
      avatarValue: avatarValue,
    );
  }

  @override
  Future<AuthUser> uploadCurrentUserAvatar(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) async {
    avatarUploadCount++;
    return _user(avatarType: 'upload', avatarValue: '/media/avatars/test.png');
  }

  @override
  Future<AuthUser> removeCurrentUserAvatar() async => _user();

  @override
  Future<bool> removeFavoriteItem(int itemCode) async => false;

  @override
  Future<bool> getFavoriteStatus(int itemCode) async => true;

  @override
  Future<SearchHistoryEntry> recordItemView(int itemCode) async =>
      (await getSearchHistory()).first;

  @override
  Future<int> clearSearchHistory() async => 1;

  @override
  Future<Item> getItem(int itemCode) async => const Item(
    itemCode: 1,
    itemName: 'AYAM BERSIH - STANDARD',
    unit: '1kg',
    itemGroup: 'BARANGAN SEGAR',
    itemCategory: 'AYAM',
  );
}

AuthUser _user({
  String name = 'Aina',
  String avatarType = 'initial',
  String? avatarValue,
}) => AuthUser(
  userId: '11111111-1111-4111-8111-111111111111',
  name: name,
  email: 'aina@example.com',
  avatarType: avatarType,
  avatarValue: avatarValue,
  createdAt: DateTime(2026, 8, 1),
  updatedAt: DateTime(2026, 8, 31),
);
