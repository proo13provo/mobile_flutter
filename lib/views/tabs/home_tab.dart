import 'package:flutter/material.dart';
import 'package:spotife/views/widgets/user_avatar.dart';

class HomeTab extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;
  final String avatarLetter;
  const HomeTab({
    super.key,
    required this.displayName,
    required this.avatarUrl,
    required this.avatarLetter,
  });
  @override
  Widget build(BuildContext context) {
    final greetingName = displayName.isNotEmpty ? displayName : 'bạn';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          UserAvatar(
            imageUrl: avatarUrl,
            fallbackLetter: avatarLetter,
            size: 72,
          ),
          const SizedBox(height: 12),
          Text(
            'Xin chào, $greetingName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Chúc bạn nghe nhạc vui vẻ.',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
