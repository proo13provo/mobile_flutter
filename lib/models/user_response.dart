class UserResponse {
  final String username;
  final String email;
  final String urlAvatar;

  const UserResponse({
    required this.username,
    required this.email,
    required this.urlAvatar,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      urlAvatar: json['urlAvatar'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'username': username, 'email': email, 'urlAvatar': urlAvatar};
  }
}
