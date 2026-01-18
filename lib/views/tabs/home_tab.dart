import 'package:flutter/material.dart';
import 'package:spotife/models/album_response.dart';
import 'package:spotife/models/artist_response.dart';
import 'package:spotife/models/song_response.dart';
import 'package:spotife/service/api/albums_service.dart';
import 'package:spotife/service/api/song_service.dart';
import 'package:spotife/service/player_service.dart';
import 'package:spotife/views/widgets/song_card.dart';
import 'package:spotife/views/widgets/song_card_search.dart';
import '../../service/api/artist_service.dart';
import 'package:spotife/views/screens/playlist_screen.dart';

class HomeTab extends StatefulWidget {
  final String displayName;
  final String? avatarUrl;
  final String avatarLetter;
  final ValueChanged<bool>? onFullScreenToggle;

  const HomeTab({
    super.key,
    required this.displayName,
    this.avatarUrl,
    required this.avatarLetter,
    this.onFullScreenToggle,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _songService = SongService();
  final _artistService = ArtistService();
  final _albumsService = AlbumService();
  List<SongResponse> _trendingSongs = [];
  List<SongResponse> _recentSongs = [];
  List<ArtistResponse> _recommendedArtists = [];
  List<SongResponse> _recommendedSongs = [];
  List<AlbumResponse> _recommendedAlbums = [];
  bool _isLoading = true;
  Map<String, dynamic>? _selectedPlaylist;

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
        _artistService.fetchArtistSongs(), // Giả sử 0 là ID người dùng hiện tại
        _songService.fetchRecommendedSongs(),
        _albumsService.fetchAlbums(),

        // Giả sử 0 là ID người dùng hiện tại
      ]);
      if (mounted) {
        setState(() {
          _trendingSongs = results[0] as List<SongResponse>;
          _recentSongs = results[1] as List<SongResponse>;
          _recommendedArtists = results[2] as List<ArtistResponse>;
          _recommendedSongs = results[3] as List<SongResponse>;
          _recommendedAlbums = results[4] as List<AlbumResponse>;
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
    if (_selectedPlaylist != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          setState(() => _selectedPlaylist = null);
          widget.onFullScreenToggle?.call(false);
        },
        child: PlaylistTab(
          id: _selectedPlaylist!['id'] as int? ?? 0,
          title: _selectedPlaylist!['title'],
          imageUrl: _selectedPlaylist!['imageUrl'],
          type: _selectedPlaylist!['type'],
          songs: _selectedPlaylist!['songs'] as List<SongResponse>,
          onBack: () {
            setState(() => _selectedPlaylist = null);
            widget.onFullScreenToggle?.call(false);
          },
        ),
      );
    }
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

                // Section: Gợi ý cho bạn
                if (!_isLoading && _recommendedSongs.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSectionHeader('Gợi ý cho bạn'),
                  const SizedBox(height: 16),
                  _buildHorizontalList(_recommendedSongs),
                ],
                const SizedBox(height: 24),
                _buildSectionHeader('Nghệ sĩ được đề xuất'),
                const SizedBox(height: 16),
                _buildArtistList(_recommendedArtists),

                const SizedBox(height: 24),
                _buildSectionHeader('Album được đề xuất'),
                const SizedBox(height: 16),
                _buildAlbumList(_recommendedAlbums),
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
                subtitle: song.author ?? song.username ?? '',
                imageUrl: song.imageUrl,
                onCardTap: () => _playSong(song, _recentSongs),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildArtistList(List<ArtistResponse> artists) {
    if (_isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF1DB954)),
        ),
      );
    }
    if (artists.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Không có nghệ sĩ nào.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return SizedBox(
      height: 200, // Tăng chiều cao để chứa subtitle
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16),
        scrollDirection: Axis.horizontal,
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return InkWell(
            onTap: () async {
              try {
                final songs = await _songService.fetchArtistSongs(artist.id);
                if (!mounted) return;

                if (songs.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Không tìm thấy bài hát nào của nghệ sĩ này',
                      ),
                    ),
                  );
                }

                setState(() {
                  _selectedPlaylist = {
                    'id': artist.id,
                    'title': artist.username,
                    'imageUrl': artist.imageUrl,
                    'type': 'Artist',
                    'songs': songs,
                  };
                });
                widget.onFullScreenToggle?.call(true);
              } catch (e) {
                debugPrint('Lỗi khi tải bài hát nghệ sĩ: $e');
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 140, // Tăng chiều rộng thẻ
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      70,
                    ), // Bán kính = width / 2
                    child: Image.network(
                      artist.imageUrl,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 140,
                        height: 140,
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.person,
                          color: Colors.white54,
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    artist.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold, // In đậm hơn
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Nghệ sĩ',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlbumList(List<AlbumResponse> albums) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF1DB954)),
        ),
      );
    }
    if (albums.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Không có album nào.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return SizedBox(
      height: 240,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16),
        scrollDirection: Axis.horizontal,
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];
          return GestureDetector(
            onTap: () async {
              try {
                final songs = await _albumsService.fetchAlbumSongs(album.id);
                if (!mounted) return;

                if (songs.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Album này chưa có bài hát nào'),
                    ),
                  );
                }

                setState(() {
                  _selectedPlaylist = {
                    'id': album.id,
                    'title': album.title,
                    'imageUrl': album.imageUrl,
                    'type': 'Album',
                    'songs': songs,
                  };
                });
                widget.onFullScreenToggle?.call(true);
              } catch (e) {
                debugPrint('Lỗi khi tải bài hát album: $e');
              }
            },
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          album.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[850],
                            child: const Icon(
                              Icons.album,
                              color: Colors.white24,
                              size: 50,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    album.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Album',
                    style: TextStyle(
                      color: Color(0xFFB3B3B3),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
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
