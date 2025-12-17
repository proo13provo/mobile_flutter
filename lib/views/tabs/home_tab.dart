import 'package:flutter/material.dart';
import 'package:spotife/models/song_response.dart';
import 'package:spotife/service/api/song_service.dart';
import 'package:spotife/service/player_service.dart';
import 'package:spotife/views/widgets/song_card.dart';
import 'package:spotife/views/widgets/song_card_search.dart';

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
  List<SongResponse> _recentSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        _songService.fetchTrendingSongs(),
        _songService.fetchListeningHistory(),
      ]);
      if (mounted) {
        setState(() {
          _trendingSongs = results[0];
          _recentSongs = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching home data: $e');
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
            onRefresh: _fetchData,
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

                // Section: Nghe gần đây (Mới)
                if (!_isLoading && _recentSongs.isNotEmpty) ...[
                  _buildSectionHeader('Nghe gần đây'),
                  const SizedBox(height: 16),
                  _buildRecentlyPlayedList(),
                  const SizedBox(height: 24),
                ],

                // Section: Thịnh hành
                _buildSectionHeader('Thịnh hành'),
                const SizedBox(height: 16),
                _buildHorizontalList(_trendingSongs),

                const SizedBox(height: 24),

                // Section: Gợi ý (Dùng lại data demo)
                _buildSectionHeader('Gợi ý cho bạn'),
                const SizedBox(height: 16),
                _buildHorizontalList(
                  _trendingSongs,
                ), // Tạm thời dùng trending làm gợi ý
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
      onTap: () => _playSong(song, _trendingSongs),
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

  Widget _buildHorizontalList(List<SongResponse> songs) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF1DB954)),
        ),
      );
    }
    if (songs.isEmpty) {
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
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return SongCard(song: song, onTap: () => _playSong(song, songs));
        },
      ),
    );
  }

  Widget _buildRecentlyPlayedList() {
    // Lấy 4 bài gần nhất
    final songs = _recentSongs.take(4).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: songs
            .map(
              (song) => SongCardSearch(
                songId: song.id.toString(),
                title: song.title,
                imageUrl: song.imageUrl,
                onCardTap: () => _playSong(song, _recentSongs),
              ),
            )
            .toList(),
      ),
    );
  }

  void _playSong(SongResponse song, List<SongResponse> contextList) {
    final player = PlayerService();
    // Sử dụng danh sách ngữ cảnh (contextList) để tạo hàng đợi phát nhạc
    // Điều này giúp khi bấm vào bài ở mục "Gần đây" thì next bài sẽ là bài tiếp theo trong "Gần đây"
    final songIds = contextList.map((s) => s.id.toString()).toList();
    final index = contextList.indexOf(song);
    if (index != -1) {
      player.setQueue(songIds, index);
    }
  }
}
