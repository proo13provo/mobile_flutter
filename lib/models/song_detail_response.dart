class SongDetailResponse {
  final SongInfo song;
  final ArtistInfo artist;

  SongDetailResponse({required this.song, required this.artist});

  factory SongDetailResponse.fromJson(Map<String, dynamic> json) {
    return SongDetailResponse(
      song: SongInfo.fromJson(json['song'] ?? {}),
      artist: ArtistInfo.fromJson(json['artist'] ?? {}),
    );
  }
}

class SongInfo {
  final String id;
  final String title;
  final String mediaUrl;
  final String imageUrl;
  final String author;
  final List<String> genres;
  final int duration;
  final String? description;

  SongInfo({
    required this.id,
    required this.title,
    required this.mediaUrl,
    required this.imageUrl,
    required this.author,
    required this.genres,
    required this.duration,
    this.description,
  });

  factory SongInfo.fromJson(Map<String, dynamic> json) {
    return SongInfo(
      // JSON returns id as "12" (String)
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      mediaUrl: json['mediaUrl'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      author: json['author'] ?? '',
      genres: json['genres'] != null ? List<String>.from(json['genres']) : [],
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      description: json['description'],
    );
  }
}

class ArtistInfo {
  final int id;
  final String username;
  final String? urlAvatar;
  final int monthlyListeners;

  ArtistInfo({
    required this.id,
    required this.username,
    this.urlAvatar,
    required this.monthlyListeners,
  });

  factory ArtistInfo.fromJson(Map<String, dynamic> json) {
    return ArtistInfo(
      // JSON returns id as 3 (int)
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username'] ?? '',
      urlAvatar: json['urlAvatar'],
      monthlyListeners: (json['monthlyListeners'] as num?)?.toInt() ?? 0,
    );
  }
}
