import 'package:flutter/material.dart';
import 'package:spotife/models/playlist_response.dart';
import 'package:spotife/service/api/api_client.dart';
import 'package:spotife/service/api/auth_service.dart';

class PlaylistService {
  final ApiClient _apiClient;
  PlaylistService({ApiClient? apiClient})
    : _apiClient = apiClient ?? AuthService().apiClient;

  Future<List<PlaylistResponse>> fetchPlaylists() async {
    try {
      final response = await _apiClient.get('/api/open/playlists');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['content'] is List) {
          return (data['content'] as List)
              .map((e) => PlaylistResponse.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("Error fetching playlists: $e");
    }
    return [];
  }

  Future<bool> createPlaylist(String name) async {
    try {
      final response = await _apiClient.post(
        '/api/user/create-playlist',
        data: {'name': name},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Error creating playlist: $e");
      return false;
    }
  }
}
