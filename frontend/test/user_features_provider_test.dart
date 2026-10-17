import 'package:flutter_test/flutter_test.dart';
import 'package:jimatmy/models/item.dart';
import 'package:jimatmy/models/user_features.dart';
import 'package:jimatmy/providers/profile_provider.dart';
import 'package:jimatmy/services/api_service.dart';

void main() {
  const item = Item(
    itemCode: 1,
    itemName: 'AYAM BERSIH - STANDARD',
    unit: '1kg',
    itemGroup: 'BARANGAN SEGAR',
    itemCategory: 'AYAM',
  );

  test('favourite JSON accepts PostgreSQL numeric strings', () {
    final favorite = FavoriteItem.fromJson({
      'itemCode': 1,
      'itemName': 'AYAM BERSIH - STANDARD',
      'unit': '1kg',
      'itemGroup': 'BARANGAN SEGAR',
      'itemCategory': 'AYAM',
      'favoritedAt': '2026-09-01T10:00:00.000Z',
      'latestLowestPrice': '8.99',
      'premiseCount': 12,
    });

    expect(favorite.lowestPrice, 8.99);
    expect(favorite.premiseCount, 12);
  });

  test(
    'load uses one batched favourites request and publishes real counts',
    () async {
      final api = _UserFeaturesApi();
      final provider = ProfileProvider(api);

      await provider.load();

      expect(provider.summary?.favoriteItemCount, 0);
      expect(provider.summary?.historyCount, 0);
      expect(provider.summary?.shoppingListCount, 2);
      expect(api.favoriteListRequests, 1);
      expect(api.historyListRequests, 1);
    },
  );

  test(
    'favourite changes optimistically and rolls back a failed request',
    () async {
      final api = _UserFeaturesApi();
      final provider = ProfileProvider(api);
      await provider.load();

      await provider.setFavorite(item, true);
      expect(provider.isFavorite(1), isTrue);
      expect(provider.summary?.favoriteItemCount, 1);

      api.failFavorite = true;
      final error = await provider.setFavorite(item, false);
      expect(error, 'Favourite request failed.');
      expect(provider.isFavorite(1), isTrue);
      expect(provider.summary?.favoriteItemCount, 1);
    },
  );

  test('known heart status works while the favourite list loads', () async {
    final api = _UserFeaturesApi();
    final provider = ProfileProvider(api)
      ..summary = const ProfileSummary(
        favoriteItemCount: 3,
        historyCount: 0,
        shoppingListCount: 0,
      );

    await provider.setFavorite(item, false, knownCurrent: true);

    expect(api.removedItemCodes, [1]);
    expect(provider.summary?.favoriteItemCount, 2);
  });

  test('repeated views update one row and counts remain stable', () async {
    final api = _UserFeaturesApi();
    final provider = ProfileProvider(api);
    await provider.load();

    await provider.recordView(item);
    await provider.recordView(item);

    expect(provider.history, hasLength(1));
    expect(provider.history.single.itemCode, 1);
    expect(provider.summary?.historyCount, 1);
    expect(api.recordedItemCodes, [1, 1]);
  });

  test('clear history is optimistic and rolls back on failure', () async {
    final api = _UserFeaturesApi();
    final provider = ProfileProvider(api);
    await provider.load();
    await provider.recordView(item);

    api.failClear = true;
    final error = await provider.clearHistory();

    expect(error, 'Clear failed.');
    expect(provider.history, hasLength(1));
    expect(provider.summary?.historyCount, 1);
  });

  test('clear removes all cached private user data', () async {
    final api = _UserFeaturesApi();
    final provider = ProfileProvider(api);
    await provider.load();
    await provider.setFavorite(item, true);
    await provider.recordView(item);

    provider.clear();

    expect(provider.summary, isNull);
    expect(provider.favorites, isEmpty);
    expect(provider.history, isEmpty);
  });

  test('history failure does not suppress loaded favourites', () async {
    final api = _UserFeaturesApi()
      ..favoriteItems = const [
        FavoriteItem(
          itemCode: 1,
          itemName: 'AYAM BERSIH - STANDARD',
          unit: '1kg',
          itemGroup: 'BARANGAN SEGAR',
          itemCategory: 'AYAM',
          lowestPrice: 8.99,
        ),
      ]
      ..failHistory = true;
    final provider = ProfileProvider(api);

    await provider.load();

    expect(provider.favorites, hasLength(1));
    expect(provider.favorites.single.itemCode, 1);
    expect(provider.errorMessage, 'Recent views failed.');
  });
}

class _UserFeaturesApi extends ApiService {
  int favoriteListRequests = 0;
  int historyListRequests = 0;
  bool failFavorite = false;
  bool failClear = false;
  bool failHistory = false;
  List<FavoriteItem> favoriteItems = const [];
  final List<int> recordedItemCodes = [];
  final List<int> removedItemCodes = [];

  @override
  Future<ProfileSummary> getProfileSummary() async => const ProfileSummary(
    favoriteItemCount: 0,
    historyCount: 0,
    shoppingListCount: 2,
  );

  @override
  Future<List<FavoriteItem>> getFavoriteItems() async {
    favoriteListRequests++;
    return favoriteItems;
  }

  @override
  Future<List<SearchHistoryEntry>> getSearchHistory() async {
    historyListRequests++;
    if (failHistory) throw const ApiException('Recent views failed.');
    return const [];
  }

  @override
  Future<bool> addFavoriteItem(int itemCode) async {
    if (failFavorite) throw const ApiException('Favourite request failed.');
    return true;
  }

  @override
  Future<bool> removeFavoriteItem(int itemCode) async {
    if (failFavorite) throw const ApiException('Favourite request failed.');
    removedItemCodes.add(itemCode);
    return false;
  }

  @override
  Future<SearchHistoryEntry> recordItemView(int itemCode) async {
    recordedItemCodes.add(itemCode);
    return SearchHistoryEntry(
      historyId: 'view-$itemCode',
      itemCode: itemCode,
      itemName: 'AYAM BERSIH - STANDARD',
      unit: '1kg',
      itemGroup: 'BARANGAN SEGAR',
      itemCategory: 'AYAM',
      lastViewedAt: DateTime.now(),
      wasCreated: recordedItemCodes.length == 1,
    );
  }

  @override
  Future<int> clearSearchHistory() async {
    if (failClear) throw const ApiException('Clear failed.');
    return 1;
  }
}
