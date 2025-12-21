class PlaylistResponse {
  final int id;
  final String name;
  final String imageUrl;

  const PlaylistResponse({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory PlaylistResponse.fromJson(Map<String, dynamic> json) {
    return PlaylistResponse(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? json['name'] as String? ?? '',
      imageUrl:
          json['coverUrl'] as String? ?? json['coverUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': name,
    'imageUrl': imageUrl,
  };
}
