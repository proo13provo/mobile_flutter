import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackLetter;
  final double size;
  const UserAvatar({
    super.key,
    this.imageUrl,
    this.fallbackLetter = 'S',
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final displayLetter = fallbackLetter.trim().isNotEmpty
        ? fallbackLetter.trim()[0].toUpperCase()
        : 'S';
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFF8DBB),
        shape: BoxShape.circle,
        image: hasImage
            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: hasImage
          ? null
          : Text(
              displayLetter,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: size * 0.45,
                color: Colors.black,
              ),
            ),
    );
  }
}
