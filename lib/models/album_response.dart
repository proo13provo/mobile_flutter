class AlbumResponse {
  final int id;
  final String title;
  final String imageUrl;

  const AlbumResponse({
    required this.id,
    required this.title,
    required this.imageUrl,
  });

  factory AlbumResponse.fromJson(Map<String, dynamic> json) {
    return AlbumResponse(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'imageUrl': imageUrl,
  };
}
