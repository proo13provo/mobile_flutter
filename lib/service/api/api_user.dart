import 'package:dio/dio.dart';
import 'package:spotife/service/api/auth_service.dart';

import '../../models/search_response.dart';
import '../../models/user_response.dart';
import 'api_client.dart';

/// Provides typed calls for user profile and search endpoints.
class ApiUserService {
  ApiUserService({ApiClient? apiClient})
    : _apiClient = apiClient ?? AuthService().apiClient;

  final ApiClient _apiClient;

  Future<({bool ok, UserResponse? user})> fetchProfile({
    String? authorization,
  }) async {
    try {
      final options = authorization == null || authorization.isEmpty
          ? null
          : Options(headers: {'Authorization': authorization});

      final resp = await _apiClient.get('/api/user/profile', options: options);
      final body = _asMap(resp.data);
      final user = _buildUser(body);
      final ok = resp.statusCode == 200 && user != null;
      return (ok: ok, user: user);
    } on DioException {
      return (ok: false, user: null);
    } catch (_) {
      return (ok: false, user: null);
    }
  }

  Future<({bool ok, SearchResponse results})> searchAll(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      return (ok: true, results: const SearchResponse());
    }

    try {
      // Lấy token hợp lệ (đã refresh nếu cần) từ AuthService
      final token = await AuthService().getAccessToken();
      final options = token != null && token.isNotEmpty
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null;

      final resp = await _apiClient.get(
        '/api/search',
        queryParameters: {'keyword': trimmed},
        options: options,
      );
      final results = SearchResponse.fromJson(_asMap(resp.data));
      return (ok: resp.statusCode == 200, results: results);
    } on DioException {
      return (ok: false, results: const SearchResponse());
    } catch (_) {
      return (ok: false, results: const SearchResponse());
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  UserResponse? _buildUser(Map<String, dynamic> json) {
    try {
      return UserResponse.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
