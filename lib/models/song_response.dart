class SongResponse {
  final int id;
  final String title;
  final String imageUrl;
  final String? author;
  final int? artistId;
  final String? username;

  const SongResponse({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.author,
    this.artistId,
    this.username,
  });

  factory SongResponse.fromJson(Map<String, dynamic> json) {
    return SongResponse(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      author: json['author'] as String?,
      artistId: (json['artistId'] as num?)?.toInt(),
      username: json['username'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'imageUrl': imageUrl,
    'author': author,
    'artistId': artistId,
    'username': username,
  };
}
