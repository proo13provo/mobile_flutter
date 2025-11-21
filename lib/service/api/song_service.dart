// import 'dart:convert';

// import '../secure_storage_service.dart';
// import 'api_client.dart';

// class SongService {
//   final ApiClient _apiClient;
//   final SecureStorageService _secureStorageService;

//   SongService(this._apiClient, this._secureStorageService);

//   Future<List<dynamic>> fetchSongs() async {
//     final token = await _secureStorageService.readToken();
//     final response = await _apiClient.get(
//       '/songs',
//       headers: {'Authorization': 'Bearer $token'},
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body) as List<dynamic>;
//     } else {
//       throw Exception('Failed to load songs');
//     }
//   }
// }
