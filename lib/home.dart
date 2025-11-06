import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SpotifyApp extends StatelessWidget {
  const SpotifyApp({super.key});
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
          offset: const Offset(0, -35),
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                    horizontal: 20, vertical: 8),
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
              child: IndexedStack(
                index: tab,
                children: pages,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        currentIndex: tab,
        onTap: (i) {
          if (i == 4) {
            _openCreateSheet(context);
          } else {
            setState(() => tab = i);
          }

        },
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
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Tìm kiếm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music_outlined),
            activeIcon: Icon(Icons.library_music),
            label: 'Thư viện',
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
      ),
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
    super.key,
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
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
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
      child: Text('Trang chủ',
          style: TextStyle(color: Colors.white, fontSize: 22)),
    );
  }
}

class _SearchPage extends StatelessWidget {
  const _SearchPage();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child:
      Text('Tìm kiếm', style: TextStyle(color: Colors.white, fontSize: 22)),
    );
  }
}

class _LibraryPage extends StatelessWidget {
  const _LibraryPage();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child:
      Text('Thư viện', style: TextStyle(color: Colors.white, fontSize: 22)),
    );
  }
}

class _PremiumPage extends StatelessWidget {
  const _PremiumPage();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child:
      Text('Premium', style: TextStyle(color: Colors.white, fontSize: 22)),
    );
  }
}
