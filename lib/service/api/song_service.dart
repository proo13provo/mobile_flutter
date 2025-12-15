import 'package:dio/dio.dart';
import 'package:spotife/core/constants/api_constants.dart';
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
}
