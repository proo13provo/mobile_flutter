import 'package:dio/dio.dart';
import 'package:spotife/core/constants/api_constants.dart';
import 'package:spotife/models/song_response.dart';
import 'package:spotife/models/song_detail_response.dart';

class SongService {
  final Dio _dio = Dio();

  Future<SongDetailResponse?> fetchSongDetail(String songId) async {
    try {
      final url = '${ApiConstants.baseUrl}/api/open/songs/$songId';
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        return SongDetailResponse.fromJson(response.data);
      }
    } catch (e) {
      // Handle error (log it or rethrow)
      print('Error fetching song detail: $e');
    }
    return null;
  }

  Future<List<SongResponse>> fetchTrendingSongs() async {
    try {
      final url = '${ApiConstants.baseUrl}/api/open/songs/trending';
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['content'] is List) {
          return (data['content'] as List)
              .map((e) => SongResponse.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      print('Error fetching trending songs: $e');
    }
    return [];
  }
}
