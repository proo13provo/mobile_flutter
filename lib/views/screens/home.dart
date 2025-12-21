import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:spotife/models/user_response.dart';
import 'package:spotife/routes/app_routes.dart';
import 'package:spotife/service/api/auth_service.dart';
import 'package:spotife/service/api/api_user.dart';
import 'package:spotife/service/player_service.dart';
import 'package:spotife/service/secure_storage_service.dart';
import 'package:spotife/views/screens/songdetail_screen.dart';
import 'package:spotife/views/tabs/home_tab.dart';
import 'package:spotife/views/tabs/library_tab.dart';
import 'package:spotife/views/screens/create_playlist_screen.dart';
import 'package:spotife/views/tabs/premium_tab.dart';
import 'package:spotife/views/tabs/search_tab.dart';
import 'package:spotife/views/widgets/user_avatar.dart';

final PlayerRouteObserver _playerRouteObserver = PlayerRouteObserver();

class SpotifyScreen extends StatelessWidget {
  const SpotifyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorObservers: [_playerRouteObserver],
      home: const SpotifyShell(),
      // Builder này giúp Player nằm đè lên TẤT CẢ các màn hình (kể cả SearchScreen được push)
      builder: (context, child) {
        return Stack(
          children: [if (child != null) child, const _GlobalPlayerOverlay()],
        );
      },
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
  bool _homeFullScreen = false;

  UserResponse? _user;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _toggleCreateSheet() {
    final service = PlayerService();
    service.setModalOpen(!service.isModalOpen);
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

  List<Widget> _buildPages() {
    final avatarUrl = _user?.urlAvatar;
    final letter = _avatarLetter;
    return [
      HomeTab(
        displayName: _displayName,
        avatarUrl: avatarUrl,
        avatarLetter: letter,
        onFullScreenToggle: (isFullScreen) {
          if (_homeFullScreen != isFullScreen) {
            setState(() => _homeFullScreen = isFullScreen);
          }
        },
      ),
      SearchTab(avatarUrl: avatarUrl, avatarLetter: letter),
      const LibraryTab(),
      const PremiumTab(),
    ];
  }

  String get _displayName {
    final name = (_user?.username ?? '').trim();
    if (name.isNotEmpty) return name;
    // final email = (_user?.email ?? '').trim();
    // if (email.isNotEmpty) return email;
    return 'NoName';
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
      final authorization = token != null && token.isNotEmpty
          ? 'Bearer $token'
          : null;

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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navBarHeight = kBottomNavigationBarHeight + bottomPadding;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        children: [
          SafeArea(
            top: !(tab == 0 && _homeFullScreen),
            child: Column(
              children: [
                _buildTopBar(),
                if (!(tab == 0 && _homeFullScreen)) const SizedBox(height: 4),
                Expanded(
                  child: IndexedStack(index: tab, children: pages),
                ),
              ],
            ),
          ),
          ListenableBuilder(
            listenable: PlayerService(),
            builder: (context, _) {
              final isOpen = PlayerService().isModalOpen;
              return Stack(
                children: [
                  // Lớp phủ mờ (Barrier) - Bấm vào để đóng
                  IgnorePointer(
                    ignoring: !isOpen,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isOpen ? 1.0 : 0.0,
                      child: GestureDetector(
                        onTap: () => PlayerService().setModalOpen(false),
                        child: Container(color: Colors.black54),
                      ),
                    ),
                  ),
                  // Menu trượt lên từ dưới
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    left: 0,
                    right: 0,
                    bottom: isOpen ? 0 : -500, // Ẩn xuống dưới khi đóng
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        navBarHeight + 12,
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF282828),
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        child: SafeArea(
                          top: false,
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _OptionTile(
                                  icon: Icons.music_note_outlined,
                                  title: 'Danh sách phát',
                                  subtitle:
                                      'Tạo danh sách phát gồm các bài hát hoặc tập podcast',
                                  onTap: () {
                                    PlayerService().setModalOpen(false);
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                            ) => const CreatePlaylistScreen(),
                                        transitionsBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                              child,
                                            ) {
                                              const begin = Offset(0.0, 1.0);
                                              const end = Offset.zero;
                                              const curve = Curves.easeOutCubic;
                                              var tween = Tween(
                                                begin: begin,
                                                end: end,
                                              ).chain(CurveTween(curve: curve));
                                              return SlideTransition(
                                                position: animation.drive(
                                                  tween,
                                                ),
                                                child: child,
                                              );
                                            },
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                _OptionTile(
                                  icon: Icons.group_outlined,
                                  title: 'Danh sách phát cộng tác',
                                  subtitle: 'Cùng bạn bè tạo danh sách phát',
                                  onTap: () =>
                                      PlayerService().setModalOpen(false),
                                ),
                                const SizedBox(height: 16),
                                _OptionTile(
                                  icon: Icons.all_inclusive,
                                  title: 'Giai điệu chung',
                                  subtitle:
                                      'Tạo danh sách phát tổng hợp gu nhạc của bạn bè',
                                  onTap: () =>
                                      PlayerService().setModalOpen(false),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: _SpotifyBottomNavigationBar(
        currentIndex: tab,
        onTap: (i) {
          if (i == 4) {
            _toggleCreateSheet();
          } else {
            // Nếu đang mở menu mà bấm tab khác thì đóng menu
            if (PlayerService().isModalOpen) {
              PlayerService().setModalOpen(false);
            }
            setState(() => tab = i);
          }
        },
      ),
    );
  }

  Widget _buildTopBar() {
    if (tab == 0 && _homeFullScreen) {
      return const SizedBox.shrink();
    }
    if (tab == 1 || tab == 3) {
      return const SizedBox(height: 8);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (tab != 3)
            GestureDetector(
              onTap: () => _openQuickMenuPanel(context),
              child: UserAvatar(
                imageUrl: _user?.urlAvatar,
                fallbackLetter: _avatarLetter,
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

class _GlobalPlayerOverlay extends StatefulWidget {
  const _GlobalPlayerOverlay();

  @override
  State<_GlobalPlayerOverlay> createState() => _GlobalPlayerOverlayState();
}

class _GlobalPlayerOverlayState extends State<_GlobalPlayerOverlay> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // Chiều cao của BottomNavigationBar + Safe area
    // Để mini player nằm ngay trên bottom bar
    final double bottomNavHeight = kBottomNavigationBarHeight + bottomPadding;
    const double miniPlayerHeight = 60.0;

    return ListenableBuilder(
      listenable: Listenable.merge([
        PlayerService(),
        _playerRouteObserver.showBottomNav,
      ]),
      builder: (context, _) {
        final service = PlayerService();
        if (!service.showPlayer || service.currentSongId == null) {
          return const SizedBox.shrink();
        }

        // Tính toán vị trí
        // Nếu expanded: top = 0, height = screenHeight
        // Nếu mini: top = screenHeight - bottomNavHeight - miniPlayerHeight

        final bool showBottomNav = _playerRouteObserver.showBottomNav.value;
        final bool isModalOpen = service.isModalOpen;
        final bool isExpanded = service.isExpanded;

        double opacity = 1.0;
        if ((!isExpanded && !showBottomNav) || isModalOpen) {
          opacity = 0.0;
        }

        double top;
        if (isExpanded && !isModalOpen) {
          top = 0;
        } else {
          top = screenHeight - bottomNavHeight - miniPlayerHeight;
        }

        final double height = isExpanded ? screenHeight : miniPlayerHeight;

        return AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: top,
          left: 0,
          right: 0,
          height: height,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: opacity,
            child: IgnorePointer(
              ignoring: opacity == 0,
              child: Material(
                color: Colors.transparent,
                child: SongDetailScreen(
                  songId: service.currentSongId!,
                  isMini: !isExpanded,
                  onMiniTap: () => service.setExpanded(true),
                  onMinimize: () => service.setExpanded(false),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class PlayerRouteObserver extends NavigatorObserver {
  final ValueNotifier<bool> showBottomNav = ValueNotifier(true);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      showBottomNav.value = route.isFirst;
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute) {
      showBottomNav.value = previousRoute.isFirst;
    }
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
            UserAvatar(
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
    return ListenableBuilder(
      listenable: PlayerService(),
      builder: (context, _) {
        final isModalOpen = PlayerService().isModalOpen;
        return ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.black.withOpacity(0.6),
              elevation: 0,
              currentIndex: currentIndex,
              onTap: onTap,
              selectedItemColor: Colors.white,
              unselectedItemColor: const Color(0xFF8E8E93),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_filled),
                  label: 'Trang chủ',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Tiềm kiếm',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.library_music_outlined),
                  activeIcon: Icon(Icons.library_music),
                  label: 'Thu viện',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(FontAwesomeIcons.spotify),
                  activeIcon: Icon(FontAwesomeIcons.spotify),
                  label: 'Premium',
                ),
                BottomNavigationBarItem(
                  icon: isModalOpen
                      ? Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.close,
                            color: Colors.black,
                            size: 20,
                          ),
                        )
                      : const Icon(FontAwesomeIcons.plus),
                  label: 'Tạo',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFB3B3B3), size: 32),
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
