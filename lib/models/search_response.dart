import 'album_response.dart';
import 'artist_response.dart';
import 'song_response.dart';

class SearchResponse {
  final List<ArtistResponse> artists;
  final List<AlbumResponse> albums;
  final List<SongResponse> songs;

  const SearchResponse({
    this.artists = const [],
    this.albums = const [],
    this.songs = const [],
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      artists: _parseList(
        json['artists'],
        (item) => ArtistResponse.fromJson(_asMap(item)),
      ),
      albums: _parseList(
        json['albums'],
        (item) => AlbumResponse.fromJson(_asMap(item)),
      ),
      songs: _parseList(
        json['songs'],
        (item) => SongResponse.fromJson(_asMap(item)),
      ),
    );
  }

  static List<T> _parseList<T>(dynamic value, T Function(dynamic item) mapper) {
    if (value is Iterable) {
      return value.map(mapper).toList(growable: false);
    }
    return const [];
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }
}
