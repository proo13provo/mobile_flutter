import 'package:flutter/material.dart';
import 'package:spotife/models/song_response.dart';
import 'package:spotife/service/api/song_service.dart';
import 'package:spotife/service/player_service.dart';
import 'package:spotife/views/widgets/song_card.dart';

class HomeTab extends StatefulWidget {
  final String displayName;
  final String? avatarUrl;
  final String avatarLetter;

  const HomeTab({
    super.key,
    required this.displayName,
    this.avatarUrl,
    required this.avatarLetter,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _songService = SongService();
  List<SongResponse> _trendingSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTrending();
  }

  Future<void> _fetchTrending() async {
    try {
      final songs = await _songService.fetchTrendingSongs();
      if (mounted) {
        setState(() {
          _trendingSongs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching trending: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 2. Nội dung chính
          RefreshIndicator(
            onRefresh: _fetchTrending,
            color: const Color(0xFF1DB954),
            backgroundColor: const Color(0xFF282828),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                const SizedBox(height: 16),
                // Lời chào
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _greeting,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Grid truy cập nhanh (6 items)
                if (!_isLoading && _trendingSongs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildQuickAccessGrid(),
                  ),

                const SizedBox(height: 24),

                // Section: Thịnh hành
                _buildSectionHeader('Thịnh hành'),
                const SizedBox(height: 16),
                _buildHorizontalList(),

                const SizedBox(height: 24),

                // Section: Gợi ý (Dùng lại data demo)
                _buildSectionHeader('Gợi ý cho bạn'),
                const SizedBox(height: 16),
                _buildHorizontalList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid() {
    // Lấy tối đa 6 bài đầu tiên
    final items = _trendingSongs.take(6).toList();
    return Column(
      children: [
        for (int i = 0; i < items.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: _buildQuickAccessTile(items[i])),
                const SizedBox(width: 8),
                if (i + 1 < items.length)
                  Expanded(child: _buildQuickAccessTile(items[i + 1]))
                else
                  const Spacer(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQuickAccessTile(SongResponse song) {
    return GestureDetector(
      onTap: () => _playSong(song),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
              child: Image.network(
                song.imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(width: 56, height: 56, color: Colors.grey[800]),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHorizontalList() {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF1DB954)),
        ),
      );
    }
    if (_trendingSongs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Không có bài hát nào.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return SizedBox(
      height: 230,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _trendingSongs.length,
        itemBuilder: (context, index) {
          final song = _trendingSongs[index];
          return SongCard(song: song, onTap: () => _playSong(song));
        },
      ),
    );
  }

  void _playSong(SongResponse song) {
    final player = PlayerService();
    final songIds = _trendingSongs.map((s) => s.id.toString()).toList();
    final index = _trendingSongs.indexOf(song);
    if (index != -1) {
      player.setQueue(songIds, index);
    }
  }
}
