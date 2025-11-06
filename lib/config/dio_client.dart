import 'dart:async';
import 'package:dio/dio.dart';
import '../config/api_constants.dart';
import '../service/secure_storage_service.dart';

class AppDio {
  AppDio._();
  static final instance = AppDio._();

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  final _storage = SecureStorageService();
  final _refreshEndpoint = '/api/auth/refresh';
  Future<String?>? _refreshing;

  void init() {
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final t = await _storage.getAccessToken();
          if (t != null && t.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $t';
          }
          handler.next(options);
        },
        onError: (err, handler) async {
          final req = err.requestOptions;
          final isUnauthorized = err.response?.statusCode == 401;
          final isRefreshCall = req.path == _refreshEndpoint;

          if (!isUnauthorized || isRefreshCall) {
            handler.next(err);
            return;
          }

          try {
            final newAccess = await _refreshAccessToken();
            if (newAccess == null || newAccess.isEmpty) {
              handler.next(err);
              return;
            }

            final newRequest = req.copyWith(
              method: req.method,
              path: req.path,
              data: req.data,
              queryParameters: req.queryParameters,
              headers: Map<String, dynamic>.from(req.headers)
                ..['Authorization'] = 'Bearer $newAccess',
              responseType: req.responseType,
              contentType: req.contentType,
              followRedirects: req.followRedirects,
              receiveDataWhenStatusError: req.receiveDataWhenStatusError,
              validateStatus: req.validateStatus,
            );

            final newResponse = await dio.fetch(newRequest);
            handler.resolve(newResponse);
          } catch (_) {
            handler.next(err);
          }
        },
      ),
    );
  }

  Future<String?> _refreshAccessToken() async {
    if (_refreshing != null) return _refreshing!;

    final c = Completer<String?>();
    _refreshing = c.future;

    try {
      final refresh = await _storage.getRefreshToken();
      if (refresh == null || refresh.isEmpty) {
        c.complete(null);
      } else {
        final resp = await dio.post(_refreshEndpoint, data: {'refreshToken': refresh});
        final data = _asMap(resp.data);
        final newAccess = data['accessToken']?.toString();
        final newRefresh = data['refreshToken']?.toString() ?? refresh;
        if (newAccess != null && newAccess.isNotEmpty) {
          await _storage.saveTokens(access: newAccess, refresh: newRefresh);
          c.complete(newAccess);
        } else {
          c.complete(null);
        }
      }
    } catch (_) {
      c.complete(null);
    } finally {
      _refreshing = null;
    }
    return c.future;
  }

  Map<String, dynamic> _asMap(dynamic d) {
    if (d is Map<String, dynamic>) return d;
    if (d is Map) return Map<String, dynamic>.from(d);
    return <String, dynamic>{};
  }
}
