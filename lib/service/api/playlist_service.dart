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

  Future<List<PlaylistResponse>> fetchMyPlaylists() async {
    try {
      final response = await _apiClient.get('/api/user/my-playlists');

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          return (response.data as List)
              .map((e) => PlaylistResponse.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("Error fetching my playlists: $e");
    }
    return [];
  }

  Future<PlaylistResponse?> createPlaylist(String name, {int? songId}) async {
    try {
      final body = <String, dynamic>{'name': name};
      if (songId != null) {
        body['songId'] = songId;
      }
      final response = await _apiClient.post(
        '/api/user/create-playlist',
        data: body,
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        return PlaylistResponse.fromJson(response.data);
      }
    } catch (e) {
      debugPrint("Error creating playlist: $e");
    }
    return null;
  }

  Future<PlaylistResponse?> createPlaylistWithFirstSong(int songId) async {
    try {
      final response = await _apiClient.post(
        '/api/user/create-playlist-with-song',
        data: {'songId': songId},
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        return PlaylistResponse.fromJson(response.data);
      }
    } catch (e) {
      debugPrint("Error creating playlist with song: $e");
    }
    return null;
  }

  Future<bool> addSongToPlaylist(int playlistId, int songId) async {
    try {
      final response = await _apiClient.post(
        '/api/user/$playlistId/songs/$songId',
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error adding song to playlist: $e");
      return false;
    }
  }

  Future<bool> removeSongFromPlaylist(int playlistId, int songId) async {
    try {
      final response = await _apiClient.delete(
        '/api/user/$playlistId/songs/$songId',
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error removing song from playlist: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchPlaylistDetail(int playlistId) async {
    try {
      final response = await _apiClient.get('/api/user/playlist/$playlistId');

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("Error fetching playlist detail: $e");
    }
    return null;
  }

  Future<bool> deletePlaylist(int playlistId) async {
    try {
      final response = await _apiClient.delete('/api/user/$playlistId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error deleting playlist: $e");
      return false;
    }
  }
}
