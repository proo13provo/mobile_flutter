class ArtistResponse {
  final int id;
  final String username;
  final String imageUrl;
  final String urlAvatar;

  const ArtistResponse({
    required this.id,
    required this.username,
    required this.imageUrl,
    required this.urlAvatar,
  });

  factory ArtistResponse.fromJson(Map<String, dynamic> json) {
    return ArtistResponse(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['name'] as String? ?? json['username'] as String? ?? '',
      imageUrl:
          json['imageUrl'] as String? ?? json['urlAvatar'] as String? ?? '',
      urlAvatar: json['urlAvatar'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'imageUrl': imageUrl,
    'urlAvatar': urlAvatar,
  };
}
