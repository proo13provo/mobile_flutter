import 'package:flutter/material.dart';
import 'package:spotife/models/artist_response.dart';
import 'package:spotife/service/api/api_client.dart';

class ArtistService {
  final ApiClient _apiClient;
  ArtistService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<ArtistResponse>> fetchArtistSongs(int artistId) async {
    try {
      final response = await _apiClient.get('/api/open/artist/trending');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['content'] is List) {
          return (data['content'] as List)
              .map((e) => ArtistResponse.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching artist songs: $e');
    }
    return [];
  }
}
