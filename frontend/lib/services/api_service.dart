import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import '../models/item.dart';
import '../models/auth_user.dart';
import '../models/planner_models.dart';
import '../models/best_places_models.dart';
import '../models/premise.dart';
import '../models/price_comparison.dart';
import '../models/price_trend.dart';
import '../models/user_features.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.code, this.statusCode});
  final String message;
  final String? code;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  String? _authToken;
  void Function()? onUnauthorized;

  bool get hasAuthToken => _authToken != null && _authToken!.isNotEmpty;
  void setAuthToken(String token) => _authToken = token;
  void clearAuthToken() => _authToken = null;

  Future<AuthSession> login(String email, String password) async {
    final json = await _request('POST', '/auth/login', {
      'email': email.trim(),
      'password': password,
    });
    return _sessionFromJson(json);
  }

  Future<AuthSession> register(
    String name,
    String email,
    String password,
  ) async {
    final json = await _request('POST', '/auth/register', {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
    });
    return _sessionFromJson(json);
  }

  Future<String> forgotPassword(String email) async {
    final json = await _request('POST', '/auth/forgot-password', {
      'email': email.trim(),
    });
    return json['message'] as String? ??
        'If an account exists for that email, a reset code has been sent.';
  }

  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final json = await _request('POST', '/auth/reset-password', {
      'email': email.trim(),
      'code': code.trim(),
      'newPassword': newPassword,
    });
    return json['message'] as String? ??
        'Your password has been reset. You can now log in.';
  }

  Future<AuthUser> getCurrentUser() async {
    final json = await _get('/auth/me');
    return AuthUser.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<AuthUser> updateCurrentUserName(String name) async {
    return updateCurrentUser(name: name);
  }

  Future<AuthUser> updateCurrentUser({
    String? name,
    String? avatarType,
    String? avatarValue,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name.trim();
    if (avatarType != null) body['avatarType'] = avatarType;
    if (avatarValue != null) body['avatarValue'] = avatarValue;
    final json = await _request('PATCH', '/auth/me', body);
    return AuthUser.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<AuthUser> uploadCurrentUserAvatar(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/me/avatar');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers())
      ..files.add(
        http.MultipartFile.fromBytes(
          'avatar',
          bytes,
          filename: filename,
          contentType: MediaType.parse(mimeType),
        ),
      );
    return _sendStreamed(request);
  }

  Future<AuthUser> removeCurrentUserAvatar() async {
    final json = await _request('DELETE', '/auth/me/avatar');
    return AuthUser.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<ProfileSummary> getProfileSummary() async {
    final json = await _get('/auth/me/summary');
    return ProfileSummary.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<FavoriteItem>> getFavoriteItems() async {
    final json = await _get('/auth/me/favorites/items');
    return (json['data'] as List<dynamic>)
        .map((value) => FavoriteItem.fromJson(value as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<bool> getFavoriteStatus(int itemCode) async {
    final json = await _get('/auth/me/favorites/items/$itemCode');
    return (json['data'] as Map<String, dynamic>)['isFavorite'] as bool;
  }

  Future<bool> addFavoriteItem(int itemCode) async {
    final json = await _request('PUT', '/auth/me/favorites/items/$itemCode');
    return (json['data'] as Map<String, dynamic>)['isFavorite'] as bool;
  }

  Future<bool> removeFavoriteItem(int itemCode) async {
    final json = await _request('DELETE', '/auth/me/favorites/items/$itemCode');
    return (json['data'] as Map<String, dynamic>)['isFavorite'] as bool;
  }

  Future<SearchHistoryEntry> recordItemView(int itemCode) async {
    final json = await _request('POST', '/auth/me/history', {
      'itemCode': itemCode,
    });
    return SearchHistoryEntry.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<SearchHistoryEntry>> getSearchHistory() async {
    final json = await _get('/auth/me/history');
    return (json['data'] as List<dynamic>)
        .map(
          (value) => SearchHistoryEntry.fromJson(value as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<int> clearSearchHistory() async {
    final json = await _request('DELETE', '/auth/me/history');
    return ((json['data'] as Map<String, dynamic>)['clearedCount'] as num)
        .toInt();
  }

  AuthSession _sessionFromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return AuthSession(
      token: data['token'] as String,
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<void> checkHealth() async {
    final json = await _get('/health');
    final data = json['data'] as Map<String, dynamic>?;
    if (data?['database'] != 'connected') {
      throw const ApiException('The grocery data service is unavailable.');
    }
  }

  Future<ItemPage> getItems({
    String query = '',
    required int limit,
    required int offset,
    String? category,
    String? state,
    String? district,
    bool pricedOnly = false,
  }) async {
    final json = await _get('/items', {
      'limit': '$limit',
      'offset': '$offset',
      if (query.trim().isNotEmpty) 'q': query.trim(),
      ...?(category == null ? null : <String, String>{'category': category}),
      ...?(state == null ? null : <String, String>{'state': state}),
      ...?(district == null ? null : <String, String>{'district': district}),
      if (pricedOnly) 'pricedOnly': 'true',
    });
    final values = json['data'] as List<dynamic>;
    final meta = json['meta'] as Map<String, dynamic>;
    return ItemPage(
      items: values
          .map((value) => Item.fromJson(value as Map<String, dynamic>))
          .toList(growable: false),
      total: meta['total'] as int,
    );
  }

  Future<Item> getItem(int itemCode) async {
    final json = await _get('/items/$itemCode');
    return Item.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<PriceComparison> getPriceComparison(
    int itemCode, {
    String? state,
    String? district,
  }) async {
    final parameters = <String, String>{};
    if (state != null) parameters['state'] = state;
    if (district != null) parameters['district'] = district;
    final json = await _get('/items/$itemCode/comparison', parameters);
    return PriceComparison.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<PriceTrend> getPriceTrend(
    int itemCode, {
    DateTime? from,
    DateTime? to,
  }) async {
    String formatDate(DateTime date) {
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      return '${date.year}-$month-$day';
    }

    final parameters = <String, String>{};
    if (from != null) parameters['from'] = formatDate(from);
    if (to != null) parameters['to'] = formatDate(to);
    final json = await _get('/items/$itemCode/trends', parameters);
    return PriceTrend.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<PlannerOverview> getPlannerOverview() async {
    final json = await _get('/planner/overview');
    return PlannerOverview.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<BasketTemplate>> getBasketTemplates() async {
    final json = await _get('/planner/templates');
    return (json['data'] as List<dynamic>)
        .map((value) => BasketTemplate.fromJson(value as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<ShoppingListDetail> createBasketFromTemplate(
    String templateKey,
  ) async {
    final json = await _request(
      'POST',
      '/planner/templates/$templateKey/create',
    );
    return ShoppingListDetail.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<ShoppingListSummary> createShoppingList(String name) async {
    final json = await _request('POST', '/shopping-lists', {'name': name});
    return ShoppingListSummary.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<ShoppingListDetail> getShoppingList(String listId) async {
    final json = await _get('/shopping-lists/$listId');
    return ShoppingListDetail.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<BestPlacesResponse> getBestPlaces(
    String listId, {
    BestPlacesFilters filters = const BestPlacesFilters(),
    int page = 1,
    int limit = 20,
  }) async {
    final json = await _get('/shopping-lists/$listId/best-places', {
      'coverage': filters.coverage.apiValue,
      'sort': filters.sort.apiValue,
      if (filters.state != null) 'state': filters.state!,
      if (filters.district != null) 'district': filters.district!,
      if (filters.maxTotal != null)
        'maxTotal': filters.maxTotal!.toStringAsFixed(2),
      if (filters.hasLocation) 'latitude': '${filters.latitude}',
      if (filters.hasLocation) 'longitude': '${filters.longitude}',
      if (filters.hasLocation && filters.radiusKm != null)
        'radiusKm': '${filters.radiusKm}',
      'page': '$page',
      'limit': '$limit',
    });
    return BestPlacesResponse.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> renameShoppingList(String listId, String name) async {
    await _request('PATCH', '/shopping-lists/$listId', {'name': name});
  }

  Future<void> deleteShoppingList(String listId) async {
    await _request('DELETE', '/shopping-lists/$listId');
  }

  Future<void> addShoppingListItem(
    String listId,
    int itemCode,
    double quantity,
  ) async {
    await _request('POST', '/shopping-lists/$listId/items', {
      'itemCode': itemCode,
      'quantity': quantity,
    });
  }

  Future<void> updateShoppingListItem(
    String listId,
    String listItemId, {
    double? quantity,
    bool? isChecked,
  }) async {
    final updates = <String, dynamic>{};
    if (quantity != null) updates['quantity'] = quantity;
    if (isChecked != null) updates['isChecked'] = isChecked;
    await _request(
      'PATCH',
      '/shopping-lists/$listId/items/$listItemId',
      updates,
    );
  }

  Future<void> deleteShoppingListItem(String listId, String listItemId) async {
    await _request('DELETE', '/shopping-lists/$listId/items/$listItemId');
  }

  Future<void> setBudget(String month, double amount) async {
    await _request('PUT', '/budget', {'month': month, 'amount': amount});
  }

  Future<PremisePage> getPremises({
    String query = '',
    String? state,
    String? district,
    bool coordinatesOnly = false,
    required int limit,
    required int offset,
  }) async {
    final parameters = <String, String>{
      'limit': '$limit',
      'offset': '$offset',
      if (query.trim().isNotEmpty) 'q': query.trim(),
      if (coordinatesOnly) 'coordinatesOnly': 'true',
    };
    if (state != null) parameters['state'] = state;
    if (district != null) parameters['district'] = district;
    final json = await _get('/premises', parameters);
    final values = json['data'] as List<dynamic>;
    final meta = json['meta'] as Map<String, dynamic>;
    return PremisePage(
      premises: values
          .map((value) => Premise.fromJson(value as Map<String, dynamic>))
          .toList(growable: false),
      total: meta['total'] as int,
    );
  }

  Future<PremisePage> getNearbyPremises({
    required double latitude,
    required double longitude,
    String query = '',
    String? state,
    String? district,
    double? radiusKm,
    required int limit,
    required int offset,
  }) async {
    final parameters = <String, String>{
      'latitude': '$latitude',
      'longitude': '$longitude',
      'limit': '$limit',
      'offset': '$offset',
      if (query.trim().isNotEmpty) 'q': query.trim(),
      if (radiusKm != null) 'radiusKm': '$radiusKm',
    };
    if (state != null) parameters['state'] = state;
    if (district != null) parameters['district'] = district;
    final json = await _get('/premises/nearby', parameters);
    final values = json['data'] as List<dynamic>;
    final meta = json['meta'] as Map<String, dynamic>;
    return PremisePage(
      premises: values
          .map((value) => Premise.fromJson(value as Map<String, dynamic>))
          .toList(growable: false),
      total: meta['total'] as int,
    );
  }

  Future<List<PremiseFilterGroup>> getPremiseFilters() async {
    final json = await _get('/premises/filters');
    final data = json['data'] as Map<String, dynamic>;
    return (data['states'] as List<dynamic>)
        .map(
          (value) => PremiseFilterGroup.fromJson(value as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<Premise> getPremise(int premiseCode) async {
    final json = await _get('/premises/$premiseCode');
    return Premise.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<ResolvedPremiseLocation> resolvePremiseLocation(
    int premiseCode,
  ) async {
    final json = await _request(
      'POST',
      '/premises/$premiseCode/resolve-location',
    );
    return ResolvedPremiseLocation.fromJson(
      json['data'] as Map<String, dynamic>,
    );
  }

  Future<ResolvedPremiseNavigation> resolvePremiseNavigation(
    int premiseCode,
  ) async {
    final json = await _request(
      'POST',
      '/premises/$premiseCode/resolve-navigation',
    );
    return ResolvedPremiseNavigation.fromJson(
      json['data'] as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String>? queryParameters,
  ]) async {
    final baseUri = Uri.parse('${ApiConfig.baseUrl}$path');
    final uri = queryParameters == null
        ? baseUri
        : baseUri.replace(queryParameters: queryParameters);
    return _send(() => _client.get(uri, headers: _headers()));
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = _headers(json: true);
    return _send(() {
      final encoded = body == null ? null : jsonEncode(body);
      return switch (method) {
        'POST' => _client.post(uri, headers: headers, body: encoded),
        'PATCH' => _client.patch(uri, headers: headers, body: encoded),
        'PUT' => _client.put(uri, headers: headers, body: encoded),
        'DELETE' => _client.delete(uri, headers: headers),
        _ => throw ArgumentError('Unsupported HTTP method: $method'),
      };
    });
  }

  Map<String, String> _headers({bool json = false}) => {
    'Accept': 'application/json',
    if (json) 'Content-Type': 'application/json',
    if (hasAuthToken) 'Authorization': 'Bearer $_authToken',
  };

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() send,
  ) async {
    try {
      final response = await send().timeout(ApiConfig.requestTimeout);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = body['error'] as Map<String, dynamic>?;
        if (response.statusCode == 401) onUnauthorized?.call();
        throw ApiException(
          error?['message'] as String? ?? 'The request could not be completed.',
          code: error?['code'] as String?,
          statusCode: response.statusCode,
        );
      }
      return body;
    } on TimeoutException {
      throw const ApiException('The server took too long to respond.');
    } on FormatException {
      throw const ApiException('The server returned an unreadable response.');
    } on http.ClientException {
      throw const ApiException('Cannot reach the JimatMY server.');
    }
  }

  Future<AuthUser> _sendStreamed(http.MultipartRequest request) async {
    try {
      final streamed = await _client
          .send(request)
          .timeout(ApiConfig.requestTimeout);
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = body['error'] as Map<String, dynamic>?;
        if (response.statusCode == 401) onUnauthorized?.call();
        throw ApiException(
          error?['message'] as String? ?? 'The picture could not be uploaded.',
          code: error?['code'] as String?,
          statusCode: response.statusCode,
        );
      }
      return AuthUser.fromJson(body['data'] as Map<String, dynamic>);
    } on TimeoutException {
      throw const ApiException('The upload took too long. Please try again.');
    } on FormatException {
      throw const ApiException('The server returned an unreadable response.');
    } on http.ClientException {
      throw const ApiException('Cannot reach the JimatMY server.');
    }
  }
}
