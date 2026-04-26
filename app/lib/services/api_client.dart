import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/config.dart';
import '../models/models.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._().._init();

  late final Dio _dio;
  static const _storage = FlutterSecureStorage();
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kHousehold = 'household_id';

  String? _access;
  String? _refresh;
  String? _householdId;

  void _init() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: const {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (opts, h) async {
        await _hydrate();
        // Re-pick up the current base URL each request — user can change it
        // from Settings → "Sunucu" without restarting the app.
        opts.baseUrl = AppConfig.apiBaseUrl;
        if (_access != null) opts.headers['Authorization'] = 'Bearer $_access';
        if (_householdId != null) opts.headers['X-Household-Id'] = _householdId;
        h.next(opts);
      },
      onError: (err, h) async {
        if (err.response?.statusCode == 401 && _refresh != null && err.requestOptions.path != '/auth/refresh') {
          try {
            final refreshed = await refreshTokens();
            if (refreshed) {
              final cloned = await _dio.fetch(err.requestOptions
                ..headers['Authorization'] = 'Bearer $_access');
              return h.resolve(cloned);
            }
          } catch (_) {}
        }
        h.next(err);
      },
    ));
  }

  Future<void> _hydrate() async {
    if (_access != null) return;
    _access = await _storage.read(key: _kAccess);
    _refresh = await _storage.read(key: _kRefresh);
    _householdId = await _storage.read(key: _kHousehold);
  }

  /// Public hydrate, called from main() before the router runs.
  Future<void> hydrate() => _hydrate();

  bool get isLoggedIn => _access != null;

  Future<void> _saveTokens(TokenPair pair) async {
    _access = pair.accessToken;
    _refresh = pair.refreshToken;
    await _storage.write(key: _kAccess, value: _access);
    await _storage.write(key: _kRefresh, value: _refresh);
  }

  Future<void> _saveHousehold(String id) async {
    _householdId = id;
    await _storage.write(key: _kHousehold, value: id);
  }

  Future<void> clear() async {
    _access = null;
    _refresh = null;
    _householdId = null;
    await _storage.deleteAll();
  }

  // ----- Auth -----
  Future<TokenPair> register({
    required String email,
    required String password,
    required String displayName,
    required String householdName,
  }) async {
    final r = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'display_name': displayName,
      'household_name': householdName,
    });
    final pair = TokenPair.fromJson(r.data as Map<String, dynamic>);
    await _saveTokens(pair);
    return pair;
  }

  Future<TokenPair> login({required String email, required String password}) async {
    final r = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    final pair = TokenPair.fromJson(r.data as Map<String, dynamic>);
    await _saveTokens(pair);
    return pair;
  }

  Future<bool> refreshTokens() async {
    if (_refresh == null) return false;
    try {
      final r = await _dio.post('/auth/refresh', queryParameters: {'refresh_token': _refresh});
      final pair = TokenPair.fromJson(r.data as Map<String, dynamic>);
      await _saveTokens(pair);
      return true;
    } on DioException catch (e) {
      // Only log the user out on a *real* auth failure (401/403).
      // Network errors, timeouts, etc. should leave tokens intact so the
      // user isn't kicked out just because the backend is briefly down.
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        await clear();
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<UserMe> me() async {
    final r = await _dio.get('/auth/me');
    return UserMe.fromJson(r.data as Map<String, dynamic>);
  }

  Future<UserMe> patchMe(Map<String, dynamic> body) async {
    final r = await _dio.patch('/auth/me', data: body);
    return UserMe.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    if (_refresh != null) {
      try {
        await _dio.post('/auth/logout', queryParameters: {'refresh_token': _refresh});
      } catch (_) {}
    }
    await clear();
  }

  // ----- Household -----
  Future<Household> household() async {
    final r = await _dio.get('/household');
    final hh = Household.fromJson(r.data as Map<String, dynamic>);
    await _saveHousehold(hh.id);
    return hh;
  }

  Future<Household> patchHousehold(Map<String, dynamic> body) async {
    final r = await _dio.patch('/household', data: body);
    return Household.fromJson(r.data as Map<String, dynamic>);
  }

  Future<HouseholdMember> patchMember(String userId, Map<String, dynamic> body) async {
    final r = await _dio.patch('/household/members/$userId', data: body);
    return HouseholdMember.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> removeMember(String userId) async {
    await _dio.delete('/household/members/$userId');
  }

  Future<List<HouseholdMember>> members() async {
    final r = await _dio.get('/household/members');
    return (r.data as List).cast<Map<String, dynamic>>().map(HouseholdMember.fromJson).toList();
  }

  Future<Map<String, dynamic>> createInvite({String? email, String role = 'member'}) async {
    final r = await _dio.post('/household/invite', data: {
      if (email != null) 'email': email,
      'role': role,
    });
    return r.data as Map<String, dynamic>;
  }

  Future<Household> acceptInvite(String code) async {
    final r = await _dio.post('/household/accept', data: {'code': code});
    return Household.fromJson(r.data as Map<String, dynamic>);
  }

  // ----- Categories -----
  Future<List<Category>> categories() async {
    final r = await _dio.get('/categories');
    return (r.data as List).cast<Map<String, dynamic>>().map(Category.fromJson).toList();
  }

  Future<Category> createCategory(Map<String, dynamic> body) async {
    final r = await _dio.post('/categories', data: body);
    return Category.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Category> patchCategory(String id, Map<String, dynamic> body) async {
    final r = await _dio.patch('/categories/$id', data: body);
    return Category.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> archiveCategory(String id) async => _dio.delete('/categories/$id');

  // ----- Accounts -----
  Future<List<Account>> accounts() async {
    final r = await _dio.get('/accounts');
    return (r.data as List).cast<Map<String, dynamic>>().map(Account.fromJson).toList();
  }

  Future<Account> createAccount(Map<String, dynamic> body) async {
    final r = await _dio.post('/accounts', data: body);
    return Account.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Account> patchAccount(String id, Map<String, dynamic> body) async {
    final r = await _dio.patch('/accounts/$id', data: body);
    return Account.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> archiveAccount(String id) async => _dio.delete('/accounts/$id');

  // ----- Recurring -----
  Future<List<RecurringTemplate>> recurring() async {
    final r = await _dio.get('/recurring');
    return (r.data as List).cast<Map<String, dynamic>>().map(RecurringTemplate.fromJson).toList();
  }

  Future<RecurringTemplate> createRecurring(Map<String, dynamic> body) async {
    final r = await _dio.post('/recurring', data: body);
    return RecurringTemplate.fromJson(r.data as Map<String, dynamic>);
  }

  Future<RecurringTemplate> patchRecurring(String id, Map<String, dynamic> body) async {
    final r = await _dio.patch('/recurring/$id', data: body);
    return RecurringTemplate.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> deleteRecurring(String id) async => _dio.delete('/recurring/$id');

  Future<Transaction> runRecurring(String id) async {
    final r = await _dio.post('/recurring/$id/run');
    return Transaction.fromJson(r.data as Map<String, dynamic>);
  }

  // ----- Notifications -----
  Future<List<AppNotification>> notifications({bool onlyUnread = false}) async {
    final r = await _dio.get('/notifications', queryParameters: {'only_unread': onlyUnread});
    return (r.data as List).cast<Map<String, dynamic>>().map(AppNotification.fromJson).toList();
  }

  Future<void> markNotificationRead(String id) async => _dio.post('/notifications/$id/read');
  Future<void> markAllNotificationsRead() async => _dio.post('/notifications/read-all');

  // ----- Export -----
  String csvExportUrl({DateTime? since, DateTime? until}) {
    final params = <String, String>{
      if (since != null) 'since': since.toUtc().toIso8601String(),
      if (until != null) 'until': until.toUtc().toIso8601String(),
    };
    final qs = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
    return '${AppConfig.apiBaseUrl}/transactions/export.csv${qs.isEmpty ? '' : '?$qs'}';
  }

  Future<String> exportCsvText() async {
    final r = await _dio.get(
      '/transactions/export.csv',
      options: Options(responseType: ResponseType.plain),
    );
    return r.data.toString();
  }

  // ----- Single transaction -----
  Future<Transaction> getTransaction(String id) async {
    final r = await _dio.get('/transactions/$id');
    return Transaction.fromJson(r.data as Map<String, dynamic>);
  }

  // ----- Search shortcut -----
  Future<List<Transaction>> searchTransactions(String query) async {
    final r = await _dio.get('/transactions', queryParameters: {'q': query, 'limit': 100});
    return (r.data as List).cast<Map<String, dynamic>>().map(Transaction.fromJson).toList();
  }

  // ----- Transactions -----
  Future<List<Transaction>> transactions({
    String? kind,
    String? actorUserId,
    String? categoryId,
    DateTime? since,
    DateTime? until,
    int limit = 100,
  }) async {
    final r = await _dio.get('/transactions', queryParameters: {
      if (kind != null) 'kind': kind,
      if (actorUserId != null) 'actor_user_id': actorUserId,
      if (categoryId != null) 'category_id': categoryId,
      if (since != null) 'since': since.toUtc().toIso8601String(),
      if (until != null) 'until': until.toUtc().toIso8601String(),
      'limit': limit,
    });
    return (r.data as List).cast<Map<String, dynamic>>().map(Transaction.fromJson).toList();
  }

  Future<Transaction> createTransaction(Map<String, dynamic> body) async {
    final r = await _dio.post('/transactions', data: body);
    return Transaction.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<Transaction>> createBulk(List<Map<String, dynamic>> items) async {
    final r = await _dio.post('/transactions/bulk', data: items);
    return (r.data as List).cast<Map<String, dynamic>>().map(Transaction.fromJson).toList();
  }

  Future<void> deleteTransaction(String id) async => _dio.delete('/transactions/$id');

  Future<Transaction> patchTransaction(String id, Map<String, dynamic> body) async {
    final r = await _dio.patch('/transactions/$id', data: body);
    return Transaction.fromJson(r.data as Map<String, dynamic>);
  }

  // ----- AI -----
  Future<AIExtractedReceipt> classifyText(String text, {String? model}) async {
    final r = await _dio.post('/ai/classify-text', data: {
      'text': text,
      if (model != null) 'model': model,
    });
    return AIExtractedReceipt.fromJson(r.data as Map<String, dynamic>);
  }

  Future<AIExtractedReceipt> transcribeVoice(String text, {String? model}) async {
    final r = await _dio.post('/ai/transcribe-voice', data: {
      'text': text,
      if (model != null) 'model': model,
    });
    return AIExtractedReceipt.fromJson(r.data as Map<String, dynamic>);
  }

  Future<AIExtractedReceipt> extractReceipt(String ocrText, {String? model, String hint = 'fiş'}) async {
    final r = await _dio.post('/ai/extract-receipt', data: {
      'text': ocrText,
      'hint': hint,
      if (model != null) 'model': model,
    });
    return AIExtractedReceipt.fromJson(r.data as Map<String, dynamic>);
  }

  // ----- Reports -----
  Future<Report> report({String scope = 'monthly', DateTime? anchor}) async {
    final r = await _dio.get('/reports', queryParameters: {
      'scope': scope,
      if (anchor != null) 'anchor': anchor.toUtc().toIso8601String(),
    });
    return Report.fromJson(r.data as Map<String, dynamic>);
  }
}
