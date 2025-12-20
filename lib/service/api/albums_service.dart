import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:spotife/models/album_response.dart';
import 'package:spotife/models/song_response.dart';
import 'package:spotife/service/api/api_client.dart';

class AlbumService {
  final ApiClient _apiClient;
  AlbumService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<AlbumResponse>> fetchAlbums() async {
    try {
      final response = await _apiClient.get('/api/open/albums/trending');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['content'] is List) {
          return (data['content'] as List)
              .map((e) => AlbumResponse.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching albums: $e');
    }
    return [];
  }

  Future<List<SongResponse>> fetchAlbumSongs(int albumId) async {
    try {
      final response = await _apiClient.get('/api/open/albums/$albumId/songs');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        // Kiểm tra cả 'songs' và 'content' để tương thích với các cấu trúc JSON khác nhau
        final list = data['songs'] ?? data['content'];
        if (list is List) {
          return list.map((e) {
            final map = Map<String, dynamic>.from(e);
            if (map['id'] is String) map['id'] = int.tryParse(map['id']) ?? 0;
            if (map['artistId'] is String) {
              map['artistId'] = int.tryParse(map['artistId']);
            }
            return SongResponse.fromJson(map);
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching album songs: $e');
    }
    return [];
  }
}
