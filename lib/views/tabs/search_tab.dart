import 'package:flutter/material.dart';
import 'package:spotife/views/screens/search_screen.dart';
import 'package:spotife/views/widgets/user_avatar.dart';

class SearchTab extends StatelessWidget {
  final String? avatarUrl;
  final String avatarLetter;
  const SearchTab({
    super.key,
    required this.avatarUrl,
    required this.avatarLetter,
  });
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
      children: [
        Row(
          children: [
            UserAvatar(imageUrl: avatarUrl, fallbackLetter: avatarLetter),
            const SizedBox(width: 12),
            const Text(
              'Tìm kiếm',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                ),
                padding: EdgeInsets.zero,
                onPressed: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.search, color: Colors.black87, size: 26),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bạn muốn nghe gì?',
                    style: TextStyle(
                      color: Color(0xFF6E6E6E),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Khám phá nội dung mới mẻ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _exploreItems.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = _exploreItems[index];
              return SizedBox(width: 140, child: _ExploreCard(item: item));
            },
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Duyệt tìm tất cả',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _browseItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.65,
          ),
          itemBuilder: (context, index) {
            final item = _browseItems[index];
            return _BrowseTile(item: item);
          },
        ),
      ],
    );
  }
}

class _ExploreItem {
  final String title;
  final String imageUrl;
  const _ExploreItem(this.title, this.imageUrl);
}

class _BrowseItem {
  final String title;
  final Color color;
  final String imageUrl;
  const _BrowseItem(this.title, this.color, this.imageUrl);
}

const _exploreItems = [
  _ExploreItem(
    '#hip hop\nviệt nam',
    'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?auto=format&fit=crop&w=900&q=80',
  ),
  _ExploreItem(
    '#rock việt',
    'https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=900&q=80',
  ),
  _ExploreItem(
    '#pop rap',
    'https://images.unsplash.com/photo-1501612780327-45045538702b?auto=format&fit=crop&w=900&q=80',
  ),
];

const _browseItems = [
  _BrowseItem(
    'Nhạc',
    Color(0xFFE00081),
    'https://images.unsplash.com/photo-1487180144351-b8472da7d491?auto=format&fit=crop&w=600&q=80',
  ),
  _BrowseItem(
    'Podcasts',
    Color(0xFF006C5B),
    'https://images.unsplash.com/photo-1582719478248-51f2e51b2cf5?auto=format&fit=crop&w=600&q=80',
  ),
  _BrowseItem(
    'Sự kiện trực tiếp',
    Color(0xFF6C21FF),
    'https://images.unsplash.com/photo-1470229538611-16ba8c7ffbd7?auto=format&fit=crop&w=600&q=80',
  ),
  _BrowseItem(
    'Dành Cho Bạn',
    Color(0xFF7E7A91),
    'https://images.unsplash.com/photo-1511379938547-c1f69419868d?auto=format&fit=crop&w=600&q=80',
  ),
];

class _ExploreCard extends StatelessWidget {
  final _ExploreItem item;
  const _ExploreCard({required this.item});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(item.imageUrl, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.75),
                    Colors.black.withOpacity(0.15),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowseTile extends StatelessWidget {
  final _BrowseItem item;
  const _BrowseTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -6,
            child: Transform.rotate(
              angle: -0.3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  item.imageUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
