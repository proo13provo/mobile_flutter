import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:spotife/models/user_response.dart';
import 'package:spotife/routes/app_routes.dart';
import 'package:spotife/service/api/auth_service.dart';
import 'package:spotife/service/api/api_user.dart';
import 'package:spotife/service/secure_storage_service.dart';
import 'package:spotife/views/screens/search_screen.dart';

class SpotifyScreen extends StatelessWidget {
  const SpotifyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SpotifyShell(),
    );
  }
}

class SpotifyShell extends StatefulWidget {
  const SpotifyShell({super.key});
  @override
  State<SpotifyShell> createState() => _SpotifyShellState();
}

class _SpotifyShellState extends State<SpotifyShell> {
  final _apiUserService = ApiUserService();
  final _storage = SecureStorageService();

  int tab = 0;
  int filterIndex = 0;
  final filters = const ['Tất cả', 'Nhạc', 'Podcast'];
  bool showCreatePopup = false;
  double _horizontalDrag = 0;

  UserResponse? _user;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) {
        return Transform.translate(
          offset: const Offset(0, -50),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 25),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B2B2B),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            _OptionTile(
                              icon: Icons.music_note,
                              title: 'Danh sách phát',
                              subtitle:
                                  'Tạo danh sách phát gồm các bài hát hoặc tập podcast',
                            ),
                            SizedBox(height: 8),
                            _OptionTile(
                              icon: Icons.group,
                              title: 'Danh sách phát cộng tác',
                              subtitle: 'Cùng bạn bè tạo danh sách phát',
                            ),
                            SizedBox(height: 8),
                            _OptionTile(
                              icon: Icons.all_inclusive,
                              title: 'Giai điệu chung',
                              subtitle:
                                  'Tạo danh sách phát tổng hợp gu nhạc của bạn bè',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Positioned(
              //   right: 16,
              //   bottom: 0,
              //   child: FloatingActionButton.small(
              //     backgroundColor: const Color(0xFF2B2B2B),
              //     onPressed: () => Navigator.of(context).pop(),
              //    child: const Icon(Icons.close),
              //   ),
              // ),
            ],
          ),
        );
      },
    );
  }

  void _openQuickMenuPanel(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierLabel: 'menu',
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) {
        return _QuickMenuPanel(
          hostContext: context,
          displayName: _displayName,
          email: _user?.email ?? '',
          avatarUrl: _user?.urlAvatar ?? '',
          fallbackLetter: _avatarLetter,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      },
    );
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _horizontalDrag = 0;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (details.delta.dx > 0) {
      _horizontalDrag += details.delta.dx;
    } else {
      _horizontalDrag = 0;
    }
  }

  void _handleHorizontalDragEnd(DragEndDetails details, BuildContext context) {
    final velocity = details.primaryVelocity ?? 0;
    if (_horizontalDrag >= 80 || velocity > 600) {
      _openQuickMenuPanel(context);
    }
    _horizontalDrag = 0;
  }

  List<Widget> _buildPages() {
    final avatarUrl = _user?.urlAvatar;
    final letter = _avatarLetter;
    return [
      _HomePage(
        displayName: _displayName,
        avatarUrl: avatarUrl,
        avatarLetter: letter,
      ),
      _SearchPage(
        avatarUrl: avatarUrl,
        avatarLetter: letter,
      ),
      const _LibraryPage(),
      const _PremiumPage(),
    ];
  }

  String get _displayName {
    final name = (_user?.username ?? '').trim();
    if (name.isNotEmpty) return name;
    final email = (_user?.email ?? '').trim();
    if (email.isNotEmpty) return email;
    return '';
  }

  String get _avatarLetter {
    final basis = _displayName.isNotEmpty ? _displayName : (_user?.email ?? '');
    final trimmed = basis.trim();
    if (trimmed.isNotEmpty) {
      return trimmed.substring(0, 1).toUpperCase();
    }
    return 'S';
  }

  Future<void> _loadUserProfile() async {
    try {
      final token = await _storage.getAccessToken();
      final authorization =
          token != null && token.isNotEmpty ? 'Bearer $token' : null;

      final resp = await _apiUserService.fetchProfile(
        authorization: authorization,
      );
      if (!mounted) return;
      if (resp.ok && resp.user != null) {
        setState(() => _user = resp.user);
      }
    } catch (_) {
      if (!mounted) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _handleHorizontalDragStart,
      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
      onHorizontalDragEnd: (details) =>
          _handleHorizontalDragEnd(details, context),
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBody: true,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 4),
              Expanded(
                child: IndexedStack(index: tab, children: pages),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _SpotifyBottomNavigationBar(
          currentIndex: tab,
          onTap: (i) {
            if (i == 4) {
              _openCreateSheet(context);
            } else {
              setState(() => tab = i);
            }
          },
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    if (tab == 1) {
      return const SizedBox(height: 8);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (tab != 3)
            _UserAvatar(
              imageUrl: _user?.urlAvatar,
              fallbackLetter: _avatarLetter,
            ),
          const SizedBox(width: 12),
          if (tab == 0)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(filters.length, (i) {
                    final selected = filterIndex == i;
                    return GestureDetector(
                      onTap: () => setState(() => filterIndex = i),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.greenAccent
                              : const Color(0xFF2C2C2C),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(
                          filters[i],
                          style: TextStyle(
                            color: selected ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickMenuPanel extends StatelessWidget {
  final BuildContext hostContext;
  final String displayName;
  final String email;
  final String avatarUrl;
  final String fallbackLetter;
  const _QuickMenuPanel({
    required this.hostContext,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.fallbackLetter,
  });

  @override
  Widget build(BuildContext context) {
    final timeLabel = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.now(), alwaysUse24HourFormat: true);
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.8,
        heightFactor: 1,
        child: Material(
          color: const Color(0xFF121212),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: _QuickMenuContent(
                timeLabel: timeLabel,
                hostContext: hostContext,
                displayName: displayName,
                email: email,
                avatarUrl: avatarUrl,
                fallbackLetter: fallbackLetter,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickMenuContent extends StatelessWidget {
  final String timeLabel;
  final BuildContext hostContext;
  final String displayName;
  final String email;
  final String avatarUrl;
  final String fallbackLetter;
  const _QuickMenuContent({
    required this.timeLabel,
    required this.hostContext,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.fallbackLetter,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_QuickMenuItemData>[
      const _QuickMenuItemData(Icons.add_circle_outline, 'Thêm tài khoản'),
      const _QuickMenuItemData(Icons.bolt, 'Nội dung mới'),
      const _QuickMenuItemData(Icons.show_chart, 'Số liệu hoạt động nghe'),
      const _QuickMenuItemData(Icons.access_time, 'Gần đây'),
      const _QuickMenuItemData(Icons.campaign, 'Tin cập nhật'),
      const _QuickMenuItemData(Icons.settings, 'Cài đặt và quyền riêng tư'),
      _QuickMenuItemData(Icons.logout, 'Đăng xuất', onTap: _performLogout),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          timeLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _UserAvatar(
              imageUrl: avatarUrl,
              fallbackLetter: fallbackLetter,
              size: 52,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName.isNotEmpty ? displayName : 'Người dùng',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email.isNotEmpty ? email : 'Xem hồ sơ',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 16),
        ...items.map((item) => _QuickMenuTile(data: item)),
        const Spacer(),
      ],
    );
  }

  Future<void> _performLogout() async {
    final messenger = ScaffoldMessenger.of(hostContext);
    final navigator = Navigator.of(hostContext, rootNavigator: true);
    try {
      final result = await AuthService().logout();
      final message = result.auth.message.isNotEmpty
          ? result.auth.message
          : (result.ok ? 'Đăng xuất thành công' : 'Đăng xuất thất bại');
      messenger.showSnackBar(SnackBar(content: Text(message)));
      if (result.ok) {
        navigator.pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Đăng xuất thất bại')),
      );
    }
  }
}

typedef _QuickMenuAction = Future<void> Function();

class _QuickMenuItemData {
  final IconData icon;
  final String title;
  final _QuickMenuAction? onTap;
  const _QuickMenuItemData(this.icon, this.title, {this.onTap});
}

class _QuickMenuTile extends StatelessWidget {
  final _QuickMenuItemData data;
  const _QuickMenuTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: data.onTap == null
          ? null
          : () async {
              Navigator.of(context).pop();
              await data.onTap!.call();
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(data.icon, color: Colors.white, size: 26),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                data.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotifyBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _SpotifyBottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.transparent,
      elevation: 0,
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: Colors.white,
      unselectedItemColor: const Color(0xFF8E8E93),
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_filled),
          label: 'Trang chủ',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Tiềm kiếm'),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_music_outlined),
          activeIcon: Icon(Icons.library_music),
          label: 'Thu viện',
        ),
        BottomNavigationBarItem(
          icon: Icon(FontAwesomeIcons.spotify),
          activeIcon: Icon(FontAwesomeIcons.spotify),
          label: 'Premium',
        ),
        BottomNavigationBarItem(
          icon: Icon(FontAwesomeIcons.plus),
          label: 'Tạo',
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF3A3A3A),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallbackLetter;
  final double size;
  const _UserAvatar({
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
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              )
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

class _HomePage extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;
  final String avatarLetter;
  const _HomePage({
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
          _UserAvatar(
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

class _SearchPage extends StatelessWidget {
  final String? avatarUrl;
  final String avatarLetter;
  const _SearchPage({required this.avatarUrl, required this.avatarLetter});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
      children: [
        Row(
          children: [
            _UserAvatar(
              imageUrl: avatarUrl,
              fallbackLetter: avatarLetter,
            ),
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

class _LibraryPage extends StatelessWidget {
  const _LibraryPage();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Thư viện',
        style: TextStyle(color: Colors.white, fontSize: 22),
      ),
    );
  }
}

class _PremiumPage extends StatelessWidget {
  const _PremiumPage();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Premium',
        style: TextStyle(color: Colors.white, fontSize: 22),
      ),
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
