import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import '../../core/constants/api_constants.dart';

/// Centralised HTTP client based on Dio.
///
/// Provides a single place to configure timeouts, headers,
/// and shared interceptors (like cookie handling) so that
/// higher level services can focus on business logic.
class ApiClient {
  ApiClient({
    Dio? dio,
    CookieJar? cookieJar,
    BaseOptions? baseOptions,
    List<Interceptor>? interceptors,
  }) : _cookieJar = cookieJar ?? _createDefaultCookieJar(),
       _dio = dio ?? Dio(baseOptions ?? _defaultBaseOptions()) {
    // Ensure cookies are persisted between requests.
    _dio.interceptors.removeWhere((i) => i is CookieManager);
    _dio.interceptors.add(CookieManager(_cookieJar));

    if (interceptors != null && interceptors.isNotEmpty) {
      _dio.interceptors.addAll(interceptors);
    }
  }

  final Dio _dio;
  final CookieJar _cookieJar;

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  void setDefaultHeader(String key, Object value) {
    _dio.options.headers[key] = value;
  }

  void removeDefaultHeader(String key) {
    _dio.options.headers.remove(key);
  }

  void clearCookies([Uri? uri]) {
    if (uri != null) {
      _cookieJar.delete(uri);
    } else {
      _cookieJar.deleteAll();
    }
  }

  static BaseOptions _defaultBaseOptions() {
    return BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {'Content-Type': 'application/json'},
    );
  }

  static CookieJar _createDefaultCookieJar() {
    final directory = Directory('${Directory.systemTemp.path}/spotife_cookies');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    return PersistCookieJar(storage: FileStorage(directory.path));
  }
}
