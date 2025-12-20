import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:spotife/models/song_detail_response.dart';
import 'package:spotife/models/song_response.dart';
import 'package:spotife/service/api/api_client.dart';
import 'package:spotife/service/api/auth_service.dart';

class SongService {
  final ApiClient _apiClient;

  // Sử dụng AuthService().apiClient để tận dụng Interceptor đã cấu hình (tự động gắn Token)
  SongService({ApiClient? apiClient})
    : _apiClient = apiClient ?? AuthService().apiClient;

  Future<SongDetailResponse?> fetchSongDetail(String songId) async {
    try {
      final response = await _apiClient.get('/api/open/songs/$songId');

      if (response.statusCode == 200 && response.data != null) {
        return SongDetailResponse.fromJson(response.data);
      }
    } catch (e) {
      // Handle error (log it or rethrow)
      debugPrint('Error fetching song detail: $e');
    }
    return null;
  }

  Future<List<SongResponse>> fetchTrendingSongs() async {
    try {
      final response = await _apiClient.get('/api/open/songs/trending');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['content'] is List) {
          return (data['content'] as List)
              .map((e) => SongResponse.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching trending songs: $e');
    }
    return [];
  }

  // Lấy danh sách bài hát được đề xuất cho người dùng
  Future<List<SongResponse>> fetchRecommendedSongs() async {
    try {
      final response = await _apiClient.get('/api/user/songs/recommended');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['content'] is List) {
          return (data['content'] as List)
              .map((e) => SongResponse.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching recommended songs: $e');
    }
    return [];
  }

  Future<void> listenSong(String songId) async {
    try {
      // Gọi API ghi nhận lượt nghe. Prefix /api được thêm vào để đồng bộ với cấu trúc dự án.
      await _apiClient.get('/api/user/songs/$songId/listen');
    } catch (e) {
      // Log lỗi nhưng không chặn luồng ứng dụng vì đây là tác vụ ngầm
      debugPrint('Lỗi khi ghi nhận lượt nghe: $e');
    }
  }

  Future<List<SongResponse>> fetchListeningHistory() async {
    try {
      // Cập nhật endpoint đúng với BE: /user/listening-history
      final response = await _apiClient.get('/api/user/listening-history');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        if (data is Map && data['content'] is List) {
          return (data['content'] as List)
              .map((e) => SongResponse.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching listening history: $e');
    }
    return [];
  }

  Future<List<SongResponse>> fetchArtistSongs(int artistId) async {
    try {
      final response = await _apiClient.get('/api/open/$artistId/full');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['songs'] is List) {
          return (data['songs'] as List).map((e) {
            final map = Map<String, dynamic>.from(e);
            if (map['id'] is String) {
              map['id'] = int.tryParse(map['id']) ?? 0;
            }
            return SongResponse.fromJson(map);
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching artist songs: $e');
    }
    return [];
  }
}
