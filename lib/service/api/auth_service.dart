import 'dart:convert';

import 'package:dio/dio.dart';

import '../../models/auth_response.dart';
import '../../models/user_response.dart';
import '../secure_storage_service.dart';
import 'api_client.dart';

class AuthService {
  factory AuthService({ApiClient? apiClient, SecureStorageService? storage}) {
    if (apiClient == null && storage == null) {
      return _instance;
    }
    return AuthService._(
      apiClient ?? ApiClient(),
      storage ?? SecureStorageService(),
    );
  }

  AuthService._(this._apiClient, SecureStorageService storage)
    : _storage = storage {
    _attachAuthInterceptor();
  }

  static final AuthService _instance = AuthService._(
    ApiClient(),
    SecureStorageService(),
  );

  static const Duration _expiryGracePeriod = Duration(seconds: 30);

  final ApiClient _apiClient;
  final SecureStorageService _storage;

  ApiClient get apiClient => _apiClient;

  String? _cachedAccessToken;
  DateTime? _cachedExpiry;
  bool _authInterceptorAttached = false;
  Future<({bool ok, AuthResponse auth})>? _refreshingFuture;

  Future<({bool ok, AuthResponse auth, UserResponse? user})> login({
    required String email,
    required String password,
  }) async {
    try {
      final resp = await _apiClient.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
        options: Options(extra: const {'skipAuth': true}),
      );

      final body = _asMap(resp.data);
      final auth = _buildAuthResponse(body, fallbackMessage: 'Login OK');
      final user = _buildUserResponse(body['user']);
      final ok = resp.statusCode == 200;

      if (ok && auth.accessToken.isNotEmpty) {
        await _persistAccessToken(auth.accessToken);
      }

      return (ok: ok, auth: auth, user: ok ? user : null);
    } on DioException catch (e) {
      final auth = _buildAuthResponse(
        e.response?.data,
        fallbackMessage: 'Login failed',
      );
      return (ok: false, auth: auth, user: null);
    } catch (_) {
      return (
        ok: false,
        auth: const AuthResponse(accessToken: '', message: 'Login failed'),
        user: null,
      );
    }
  }

  Future<({bool ok, AuthResponse auth})> register({
    required String email,
    required String password,
  }) async {
    try {
      final resp = await _apiClient.post(
        '/api/auth/register-initiate',
        data: {'email': email, 'password': password},
        options: Options(extra: const {'skipAuth': true}),
      );

      final auth = _buildAuthResponse(resp.data, fallbackMessage: 'Sign up OK');
      final ok = resp.statusCode == 200;

      return (ok: ok, auth: auth);
    } on DioException catch (e) {
      final auth = _buildAuthResponse(
        e.response?.data,
        fallbackMessage: 'Sign up failed',
      );
      return (ok: false, auth: auth);
    } catch (_) {
      return (
        ok: false,
        auth: const AuthResponse(accessToken: '', message: 'Sign up failed'),
      );
    }
  }

  Future<({bool ok, AuthResponse auth})> verify({
    required String email,
    required String verificationCode,
  }) async {
    try {
      final resp = await _apiClient.post(
        '/api/auth/register-verify',
        data: {'email': email, 'verificationCode': verificationCode},
        options: Options(extra: const {'skipAuth': true}),
      );

      final auth = _buildAuthResponse(resp.data, fallbackMessage: 'verify OK');
      final ok = resp.statusCode == 200;

      if (ok && auth.accessToken.isNotEmpty) {
        await _persistAccessToken(auth.accessToken);
      }

      return (ok: ok, auth: auth);
    } on DioException catch (e) {
      final auth = _buildAuthResponse(
        e.response?.data,
        fallbackMessage: 'verify failed',
      );
      return (ok: false, auth: auth);
    } catch (_) {
      return (
        ok: false,
        auth: const AuthResponse(accessToken: '', message: 'verify failed'),
      );
    }
  }

  Future<({bool ok, AuthResponse auth})> logout({String? authorization}) async {
    try {
      final headers = <String, dynamic>{};
      if (authorization != null && authorization.isNotEmpty) {
        headers['Authorization'] = authorization;
      }

      final resp = await _apiClient.post(
        '/api/auth/logout',
        options: Options(
          headers: headers.isEmpty ? null : headers,
          extra: const {'skipRetry': true},
        ),
      );

      final auth = _buildAuthResponse(resp.data, fallbackMessage: 'Logout OK');
      final ok = resp.statusCode == 200;

      if (ok) {
        await _invalidateSession(clearCookies: true);
      }

      return (ok: ok, auth: auth);
    } on DioException catch (e) {
      final auth = _buildAuthResponse(
        e.response?.data,
        fallbackMessage: 'Logout failed',
      );
      return (ok: false, auth: auth);
    } catch (_) {
      return (
        ok: false,
        auth: const AuthResponse(accessToken: '', message: 'Logout failed'),
      );
    }
  }

  Future<({bool ok, AuthResponse auth})> refreshAccessToken() {
    final ongoing = _refreshingFuture;
    if (ongoing != null) {
      return ongoing;
    }

    final future = _refreshAccessTokenInternal();
    _refreshingFuture = future;
    future.whenComplete(() {
      _refreshingFuture = null;
    });
    return future;
  }

  Future<({bool ok, AuthResponse auth})> loginWithGoogle({
    required String code,
  }) async {
    final encodedCode = Uri.encodeComponent(code);

    try {
      final resp = await _apiClient.post(
        '/api/auth/google-callback',
        data: encodedCode,
        options: Options(
          contentType: Headers.textPlainContentType,
          extra: const {'skipAuth': true},
        ),
      );

      final auth = _buildAuthResponse(resp.data, fallbackMessage: 'Login OK');
      final ok = resp.statusCode == 200;

      if (ok && auth.accessToken.isNotEmpty) {
        await _persistAccessToken(auth.accessToken);
      }

      return (ok: ok, auth: auth);
    } on DioException catch (e) {
      final auth = _buildAuthResponse(
        e.response?.data,
        fallbackMessage: 'Login failed',
      );
      return (ok: false, auth: auth);
    } catch (_) {
      return (
        ok: false,
        auth: const AuthResponse(accessToken: '', message: 'Login failed'),
      );
    }
  }

  Future<bool> restoreSessionOnAppLaunch() async {
    final storedToken = await _storage.getAccessToken();
    if (storedToken != null && storedToken.isNotEmpty) {
      await _persistAccessToken(storedToken, writeToStorage: false);
      if (!_isTokenExpired(_cachedExpiry)) {
        return true;
      }
    }

    final refreshed = await refreshAccessToken();
    if (refreshed.ok && refreshed.auth.accessToken.isNotEmpty) {
      return true;
    }

    await _invalidateSession(clearCookies: true);
    return false;
  }

  Future<({bool ok, AuthResponse auth})> _refreshAccessTokenInternal() async {
    try {
      final resp = await _apiClient.get(
        '/api/auth/access-token',
        options: Options(extra: const {'skipAuth': true, 'skipRetry': true}),
      );

      final auth = _buildAuthResponse(resp.data, fallbackMessage: 'Refreshed');
      final ok = resp.statusCode == 200 && auth.accessToken.isNotEmpty;

      if (ok) {
        await _persistAccessToken(auth.accessToken);
      }

      return (ok: ok, auth: auth);
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      final auth = _buildAuthResponse(
        e.response?.data,
        fallbackMessage: 'Refresh failed',
      );

      if (status == 401 || status == 403) {
        await _invalidateSession(clearCookies: true);
      } else {
        await _clearCachedAccessToken();
      }

      return (ok: false, auth: auth);
    } catch (_) {
      await _invalidateSession();
      return (
        ok: false,
        auth: const AuthResponse(accessToken: '', message: 'Refresh failed'),
      );
    }
  }

  Future<String?> _getValidAccessToken() async {
    if (_cachedAccessToken == null || _cachedAccessToken!.isEmpty) {
      final stored = await _storage.getAccessToken();
      if (stored == null || stored.isEmpty) {
        final refreshed = await refreshAccessToken();
        if (refreshed.ok && refreshed.auth.accessToken.isNotEmpty) {
          return refreshed.auth.accessToken;
        }
        return null;
      }

      await _persistAccessToken(stored, writeToStorage: false);
    }

    if (_isTokenExpired(_cachedExpiry)) {
      final refreshed = await refreshAccessToken();
      if (refreshed.ok && refreshed.auth.accessToken.isNotEmpty) {
        return refreshed.auth.accessToken;
      }
      return null;
    }

    return _cachedAccessToken;
  }

  bool _isTokenExpired(DateTime? expiry) {
    if (expiry == null) return true;
    final now = DateTime.now();
    return now.isAfter(expiry.subtract(_expiryGracePeriod));
  }

  Future<void> _persistAccessToken(
    String token, {
    bool writeToStorage = true,
  }) async {
    _cachedAccessToken = token;
    _cachedExpiry = _extractExpiry(token);

    _apiClient.setDefaultHeader('Authorization', 'Bearer $token');

    if (writeToStorage) {
      await _storage.saveAccessToken(token);
    }
  }

  Future<void> _invalidateSession({bool clearCookies = false}) async {
    await _clearCachedAccessToken();
    if (clearCookies) {
      _apiClient.clearCookies();
    }
  }

  Future<void> _clearCachedAccessToken() async {
    _cachedAccessToken = null;
    _cachedExpiry = null;
    _apiClient.removeDefaultHeader('Authorization');
    await _storage.deleteAccessToken();
  }

  DateTime? _extractExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final normalized = base64Url.normalize(parts[1]);
      final payloadJson = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(payloadJson);

      if (payload is Map<String, dynamic>) {
        final expValue = payload['exp'];
        if (expValue is int) {
          return DateTime.fromMillisecondsSinceEpoch(
            expValue * 1000,
            isUtc: true,
          ).toLocal();
        }
        if (expValue is num) {
          final millis = (expValue * 1000).toInt();
          return DateTime.fromMillisecondsSinceEpoch(
            millis,
            isUtc: true,
          ).toLocal();
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  void _attachAuthInterceptor() {
    if (_authInterceptorAttached) return;
    _authInterceptorAttached = true;

    _apiClient.dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['skipAuth'] == true) {
            return handler.next(options);
          }

          try {
            final token = await _getValidAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {
            await _invalidateSession(clearCookies: true);
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode ?? 0;
          final requestOptions = error.requestOptions;
          final shouldRetry =
              statusCode == 401 &&
              requestOptions.extra['skipAuth'] != true &&
              requestOptions.extra['skipRetry'] != true;

          if (!shouldRetry) {
            return handler.next(error);
          }

          try {
            final refreshed = await refreshAccessToken();
            if (refreshed.ok && refreshed.auth.accessToken.isNotEmpty) {
              final headers = Map<String, dynamic>.from(requestOptions.headers);
              headers['Authorization'] = 'Bearer ${refreshed.auth.accessToken}';

              final extra = Map<String, dynamic>.from(requestOptions.extra)
                ..['skipRetry'] = true;

              final response = await _apiClient.dio.request<dynamic>(
                requestOptions.path,
                data: requestOptions.data,
                queryParameters: requestOptions.queryParameters,
                options: Options(
                  method: requestOptions.method,
                  headers: headers,
                  contentType: requestOptions.contentType,
                  responseType: requestOptions.responseType,
                  followRedirects: requestOptions.followRedirects,
                  receiveTimeout: requestOptions.receiveTimeout,
                  sendTimeout: requestOptions.sendTimeout,
                  receiveDataWhenStatusError:
                      requestOptions.receiveDataWhenStatusError,
                  validateStatus: requestOptions.validateStatus,
                  extra: extra,
                ),
                cancelToken: requestOptions.cancelToken,
                onReceiveProgress: requestOptions.onReceiveProgress,
                onSendProgress: requestOptions.onSendProgress,
              );

              return handler.resolve(response);
            }
          } catch (_) {
            await _invalidateSession(clearCookies: true);
          }

          handler.next(error);
        },
      ),
    );
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  AuthResponse _buildAuthResponse(
    dynamic data, {
    required String fallbackMessage,
  }) {
    final map = _asMap(data);
    final auth = AuthResponse.fromJson(map);
    if (auth.message.isNotEmpty) {
      return auth;
    }
    return AuthResponse(
      accessToken: auth.accessToken,
      message: fallbackMessage,
    );
  }

  UserResponse? _buildUserResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      return UserResponse.fromJson(data);
    }
    if (data is Map) {
      return UserResponse.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }
}
