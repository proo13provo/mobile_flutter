import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import '../config/api_constants.dart';
import '../models/auth_response.dart';
import '../models/user_response.dart';

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

  Future<({bool ok, AuthResponse auth, UserResponse? user})> login({
    required String email,
    required String password,
  }) async {
    try {
      final resp = await _dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );

      final body = _asMap(resp.data);
      final auth = _buildAuthResponse(body, fallbackMessage: 'Login OK');
      final user = _buildUserResponse(body['user']);
      final ok = resp.statusCode == 200;

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
      final resp = await _dio.post(
        '/api/auth/register-initiate',
        data: {'email': email, 'password': password},
      );

      final auth = _buildAuthResponse(
        resp.data,
        fallbackMessage: 'Sign up OK',
      );
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
      final resp = await _dio.post(
        '/api/auth/register-verify',
        data: {'email': email, 'verificationCode': verificationCode},
      );

      final auth = _buildAuthResponse(
        resp.data,
        fallbackMessage: 'verify OK',
      );
      final ok = resp.statusCode == 200;

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

      final resp = await _dio.post(
        '/api/auth/logout',
        options: Options(headers: headers.isEmpty ? null : headers),
      );

      final auth = _buildAuthResponse(
        resp.data,
        fallbackMessage: 'Logout OK',
      );
      final ok = resp.statusCode == 200;

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

  Future<({bool ok, AuthResponse auth})> refreshAccessToken() async {
    try {
      // Backend reads refresh token from cookie "refreshToken".
      final resp = await _dio.get('/api/auth/access-token');

      final auth = _buildAuthResponse(
        resp.data,
        fallbackMessage: 'Refreshed',
      );
      final ok = resp.statusCode == 200;

      return (ok: ok, auth: auth);
    } on DioException catch (e) {
      final auth = _buildAuthResponse(
        e.response?.data,
        fallbackMessage: 'Refresh failed',
      );
      return (ok: false, auth: auth);
    } catch (_) {
      return (
        ok: false,
        auth: const AuthResponse(accessToken: '', message: 'Refresh failed'),
      );
    }
  }

  Future<({bool ok, AuthResponse auth})> loginWithGoogle({
    required String code,
  }) async {
    try {
      final resp = await _dio.post(
        '/api/auth/google-callback',
        data: code,
        options: Options(contentType: 'text/plain'),
      );

      final auth = _buildAuthResponse(
        resp.data,
        fallbackMessage: 'Login OK',
      );
      final ok = resp.statusCode == 200;

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
    return AuthResponse(accessToken: auth.accessToken, message: fallbackMessage);
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
