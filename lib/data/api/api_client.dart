import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

/// Holds the signed-in session's tokens. The default keeps them in memory only.
///
/// TODO: API — persist with Keychain/Keystore (e.g. `flutter_secure_storage`) so sessions survive restarts.
abstract interface class TokenStore {
  String? get accessToken;
  String? get refreshToken;
  Future<void> save({required String accessToken, String? refreshToken});
  Future<void> clear();
}

class MemoryTokenStore implements TokenStore {
  @override
  String? accessToken;
  @override
  String? refreshToken;

  @override
  Future<void> save({required String accessToken, String? refreshToken}) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken ?? this.refreshToken;
  }

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }
}

/// A non-2xx response or a transport failure. [status] is null when the request never got a response.
class ApiException implements Exception {
  const ApiException(this.message, {this.status, this.body});

  final String message;
  final int? status;
  final Object? body;

  bool get unauthorized => status == 401;

  @override
  String toString() => 'ApiException(${status ?? 'network'}): $message';
}

/// Thin JSON-over-HTTP client: base URL, bearer token, timeouts, error mapping, and one automatic retry after a
/// token refresh on 401.
class ApiClient {
  ApiClient(this.config, {TokenStore? tokens, http.Client? http, this.onRefresh})
    : tokens = tokens ?? MemoryTokenStore(),
      _http = http ?? _defaultClient();

  final ApiConfig config;
  final TokenStore tokens;
  final http.Client _http;

  /// Exchanges the refresh token for a new session; returns false when the user must sign in again.
  /// Wired by the auth repository.
  Future<bool> Function()? onRefresh;

  static http.Client _defaultClient() => http.Client();

  Future<Object?> get(String path, {Map<String, String>? query}) => _send('GET', path, query: query);

  Future<Object?> post(String path, {Object? body}) => _send('POST', path, body: body);

  Future<Object?> put(String path, {Object? body}) => _send('PUT', path, body: body);

  Future<Object?> patch(String path, {Object? body}) => _send('PATCH', path, body: body);

  Future<Object?> delete(String path) => _send('DELETE', path);

  /// `multipart/form-data` upload of a single file field.
  Future<Object?> upload(
    String path, {
    required String field,
    required List<int> bytes,
    required String filename,
    Map<String, String> fields = const {},
  }) async {
    Future<http.StreamedResponse> once() {
      final req = http.MultipartRequest('POST', config.uri(path))
        ..headers.addAll(_headers(json: false))
        ..fields.addAll(fields)
        ..files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename));
      return _http.send(req).timeout(config.timeout);
    }

    var res = await _guard(once);
    if (res.statusCode == 401 && await _refresh()) res = await _guard(once);
    return _decode(await http.Response.fromStream(res));
  }

  Future<Object?> _send(String method, String path, {Map<String, String>? query, Object? body}) async {
    Future<http.StreamedResponse> once() {
      final req = http.Request(method, config.uri(path, query))..headers.addAll(_headers());
      if (body != null) req.body = jsonEncode(body);
      return _http.send(req).timeout(config.timeout);
    }

    var res = await _guard(once);
    if (res.statusCode == 401 && await _refresh()) res = await _guard(once);
    return _decode(await http.Response.fromStream(res));
  }

  Map<String, String> _headers({bool json = true}) => {
    'Accept': 'application/json',
    if (json) 'Content-Type': 'application/json',
    if (tokens.accessToken != null) 'Authorization': 'Bearer ${tokens.accessToken}',
  };

  Future<http.StreamedResponse> _guard(Future<http.StreamedResponse> Function() send) async {
    try {
      return await send();
    } on TimeoutException {
      throw const ApiException('The request timed out.');
    } on Exception catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<bool> _refresh() async {
    if (tokens.refreshToken == null || onRefresh == null) return false;
    try {
      return await onRefresh!();
    } on ApiException {
      return false;
    }
  }

  Object? _decode(http.Response res) {
    final text = utf8.decode(res.bodyBytes);
    Object? body;
    if (text.isNotEmpty) {
      try {
        body = jsonDecode(text);
      } on FormatException {
        body = text;
      }
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      // Accept both a bare payload and the `{ "data": … }` envelope.
      if (body is Map<String, Object?> && body.length <= 3 && body.containsKey('data')) return body['data'];
      return body;
    }
    final message = switch (body) {
      {'error': {'message': final String m}} => m,
      {'error': final String m} => m,
      {'message': final String m} => m,
      _ => 'Request failed (${res.statusCode}).',
    };
    throw ApiException(message, status: res.statusCode, body: body);
  }

  void close() => _http.close();
}
