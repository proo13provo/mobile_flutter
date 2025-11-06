import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import '../config/api_constants.dart';

class AuthService {
  final Dio _dio;

  AuthService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: {'Content-Type': 'application/json'},
            ),
          ) {
    // Enable cookie handling so backend refreshToken cookie is stored/sent.
    _dio.interceptors.add(CookieManager(CookieJar()));
  }

  Future<({bool ok, String message, String? token})> login({
    required String email,
    required String password,
  }) async {
    try {
      final resp = await _dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );

      if (resp.statusCode == 200) {
        final data = _asMap(resp.data);
        return (
          ok: true,
          message: data['message']?.toString() ?? 'Login OK',
          token: data['accessToken'] as String?,
        );
      } else {
        final data = _asMap(resp.data);
        return (
          ok: false,
          message: data['message']?.toString() ?? 'Login failed',
          token: null,
        );
      }
    } on DioException catch (e) {
      final data = _asMap(e.response?.data);
      return (
        ok: false,
        message: data['message']?.toString() ?? 'Login failed',
        token: null,
      );
    } catch (_) {
      return (ok: false, message: 'Login failed', token: null);
    }
  }

  Future<({bool ok, String message})> register({
    required String email,
    required String password,
  }) async {
    try {
      final resp = await _dio.post(
        '/api/auth/register-initiate',
        data: {'email': email, 'password': password},
      );

      if (resp.statusCode == 200) {
        final data = _asMap(resp.data);
        return (ok: true, message: data['message']?.toString() ?? 'Sign up OK');
      } else {
        final data = _asMap(resp.data);
        return (
          ok: false,
          message: data['message']?.toString() ?? 'Sign up failed',
        );
      }
    } on DioException catch (e) {
      final data = _asMap(e.response?.data);
      return (
        ok: false,
        message: data['message']?.toString() ?? 'Sign up failed',
      );
    } catch (_) {
      return (ok: false, message: 'Sign up failed');
    }
  }

  Future<({bool ok, String message, String? accessToken})> verify({
    required String email,
    required String verificationCode,
  }) async {
    try {
      final resp = await _dio.post(
        '/api/auth/register-verify',
        data: {'email': email, 'verificationCode': verificationCode},
      );

      if (resp.statusCode == 200) {
        final data = _asMap(resp.data);
        return (
          ok: true,
          message: data['message']?.toString() ?? 'verify OK',
          accessToken: data['accessToken']?.toString(),
        );
      } else {
        final data = _asMap(resp.data);
        return (
          ok: false,
          message: data['message']?.toString() ?? 'verify failed',
          accessToken: null,
        );
      }
    } on DioException catch (e) {
      final data = _asMap(e.response?.data);
      return (
        ok: false,
        message: data['message']?.toString() ?? 'verify failed',
        accessToken: null,
      );
    } catch (_) {
      return (ok: false, message: 'verify failed', accessToken: null);
    }
  }

  Future<({bool ok, String message})> logout({String? authorization}) async {
    try {
      final headers = <String, dynamic>{};
      if (authorization != null && authorization.isNotEmpty) {
        headers['Authorization'] = authorization;
      }

      final resp = await _dio.post(
        '/api/auth/logout',
        options: Options(headers: headers.isEmpty ? null : headers),
      );

      final data = _asMap(resp.data);
      if (resp.statusCode == 200) {
        return (ok: true, message: data['message']?.toString() ?? 'Logout OK');
      } else {
        return (
          ok: false,
          message: data['message']?.toString() ?? 'Logout failed',
        );
      }
    } on DioException catch (e) {
      final data = _asMap(e.response?.data);
      return (
        ok: false,
        message: data['message']?.toString() ?? 'Logout failed',
      );
    } catch (_) {
      return (ok: false, message: 'Logout failed');
    }
  }

  Future<({bool ok, String message, String? accessToken})>
  refreshAccessToken() async {
    try {
      // Backend reads refresh token from cookie "refreshToken".
      final resp = await _dio.get('/api/auth/access-token');
      final data = _asMap(resp.data);

      if (resp.statusCode == 200) {
        return (
          ok: true,
          message: data['message']?.toString() ?? 'Refreshed',
          accessToken: data['accessToken']?.toString(),
        );
      } else {
        return (
          ok: false,
          message: data['message']?.toString() ?? 'Refresh failed',
          accessToken: null,
        );
      }
    } on DioException catch (e) {
      final data = _asMap(e.response?.data);
      return (
        ok: false,
        message: data['message']?.toString() ?? 'Refresh failed',
        accessToken: null,
      );
    } catch (_) {
      return (ok: false, message: 'Refresh failed', accessToken: null);
    }
  }

  Future<({bool ok, String message, String? accessToken})> loginWithGoogle({
    required String code,
  }) async {
    try {
      final resp = await _dio.post(
        '/api/auth/google-callback',
        data: code,
        options: Options(contentType: 'text/plain'),
      );

      final data = _asMap(resp.data);
      if (resp.statusCode == 200) {
        return (
          ok: true,
          message: data['message']?.toString() ?? 'Login OK',
          accessToken: data['accessToken']?.toString(),
        );
      } else {
        return (
          ok: false,
          message: data['message']?.toString() ?? 'Login failed',
          accessToken: null,
        );
      }
    } on DioException catch (e) {
      final data = _asMap(e.response?.data);
      return (
        ok: false,
        message: data['message']?.toString() ?? 'Login failed',
        accessToken: null,
      );
    } catch (_) {
      return (ok: false, message: 'Login failed', accessToken: null);
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }
}
