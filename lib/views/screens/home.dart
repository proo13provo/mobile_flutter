import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:spotife/routes/app_routes.dart';
import 'package:spotife/service/api/auth_service.dart';

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
  int tab = 0;
  int filterIndex = 0;
  final filters = const ['Tất cả', 'Nhạc', 'Podcast'];
  bool showCreatePopup = false;
  double _horizontalDrag = 0;

  final pages = const [
    _HomePage(),
    _SearchPage(),
    _LibraryPage(),
    _PremiumPage(),
  ];

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
        return _QuickMenuPanel(hostContext: context);
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

  @override
  Widget build(BuildContext context) {
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    if (tab != 3)
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF8DBB),
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          'S',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
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
                                      color: selected
                                          ? Colors.black
                                          : Colors.white,
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
              ),
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
}

class _QuickMenuPanel extends StatelessWidget {
  final BuildContext hostContext;
  const _QuickMenuPanel({required this.hostContext});

  @override
  Widget build(BuildContext context) {
    final timeLabel = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.now(),
      alwaysUse24HourFormat: true,
    );
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
  const _QuickMenuContent({
    required this.timeLabel,
    required this.hostContext,
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
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFFF8DBB),
                shape: BoxShape.circle,
              ),
              child: const Text(
                'T',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Truong Ha',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Xem hồ sơ',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
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
        navigator.pushNamedAndRemoveUntil(
          AppRoutes.main,
          (route) => false,
        );
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

class _HomePage extends StatelessWidget {
  const _HomePage();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Trang chủ',
        style: TextStyle(color: Colors.white, fontSize: 22),
      ),
    );
  }
}

class _SearchPage extends StatelessWidget {
  const _SearchPage();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Tìm kiếm',
        style: TextStyle(color: Colors.white, fontSize: 22),
      ),
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
