import 'package:flutter/material.dart';
import 'package:spotife/models/song_response.dart';
import 'package:spotife/service/api/api_user.dart';
import 'package:spotife/service/player_service.dart';
import 'package:spotife/views/widgets/song_card_search.dart';

class PlaylistTab extends StatefulWidget {
  final int id;
  final String title;
  final String imageUrl;
  final String? description;
  final String type; // 'Album', 'Playlist', 'Artist'
  final List<SongResponse> songs;
  final List<dynamic> albums;
  final VoidCallback? onBack;

  const PlaylistTab({
    super.key,
    required this.id,
    required this.title,
    required this.imageUrl,
    this.description,
    this.type = 'Playlist',
    required this.songs,
    this.albums = const [],
    this.onBack,
  });

  @override
  State<PlaylistTab> createState() => _PlaylistTabState();
}

class _PlaylistTabState extends State<PlaylistTab> {
  late ScrollController _scrollController;
  // Giả lập màu chủ đạo (thực tế có thể dùng thư viện palette_generator để lấy từ ảnh)
  final Color _dominantColor = const Color(0xFF483830);
  bool _showAllSongs = false;
  bool _isFollowed = false;
  final ApiUserService _apiUserService = ApiUserService();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    if (widget.type == 'Artist') {
      final artists = await _apiUserService.fetchFollowedArtists();
      if (mounted) {
        setState(() {
          _isFollowed = artists.any((a) => a.id == widget.id);
        });
      }
    } else if (widget.type == 'Album') {
      final albums = await _apiUserService.fetchFollowedAlbums();
      if (mounted) {
        setState(() {
          _isFollowed = albums.any((a) => a.id == widget.id);
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    setState(() => _isFollowed = !_isFollowed);
    bool success;
    if (_isFollowed) {
      success = await _apiUserService.follow(widget.id, widget.type);
    } else {
      success = await _apiUserService.unfollow(widget.id, widget.type);
    }

    if (!success && mounted) {
      setState(() => _isFollowed = !_isFollowed);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Thao tác thất bại')));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(),
              _buildHeaderInfo(),
              if (widget.type == 'Artist')
                ..._buildArtistContent()
              else
                _buildSongList(),
              // Khoảng trống dưới cùng để không bị che bởi MiniPlayer
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: widget.onBack ?? () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: false,
      expandedHeight: 340,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_dominantColor, Colors.black],
              stops: const [0.0, 1.0],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60), // Bù cho StatusBar
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[850],
                      child: const Icon(
                        Icons.music_note,
                        size: 80,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.description != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.description!,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.music_note,
                  color: Color(0xFF1DB954),
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.type,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  onPressed: _toggleFollow,
                  icon: Icon(
                    _isFollowed ? Icons.favorite : Icons.favorite_border,
                    color: _isFollowed ? const Color(0xFF1DB954) : Colors.white,
                    size: 28,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.download_for_offline_outlined,
                    color: Colors.grey,
                    size: 28,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.grey,
                    size: 28,
                  ),
                ),
                const Spacer(),
                // Nút Play lớn
                GestureDetector(
                  onTap: () {
                    if (widget.songs.isNotEmpty) {
                      final player = PlayerService();
                      final songIds = widget.songs
                          .map((s) => s.id.toString())
                          .toList();
                      player.setQueue(songIds, 0);
                    }
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1DB954),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.black,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildArtistContent() {
    final totalSongs = widget.songs.length;
    final displaySongs = _showAllSongs
        ? widget.songs
        : widget.songs.take(4).toList();

    return [
      if (widget.songs.isNotEmpty) ...[
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              "Popular Songs",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        _buildSongList(songs: displaySongs),
        if (totalSongs > 4)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _showAllSongs = !_showAllSongs;
                    });
                  },
                  child: Text(
                    _showAllSongs ? 'Show less' : 'See more',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
      if (widget.albums.isNotEmpty) ...[
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              "Albums",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.albums.length,
              itemBuilder: (context, index) {
                final album = widget.albums[index];
                // Xử lý hiển thị album item (giả sử album là Map có title, imageUrl)
                final title = (album is Map ? album['title'] : null) ?? 'Album';
                final imageUrl =
                    (album is Map ? album['imageUrl'] : null) ?? '';

                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: imageUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: Colors.grey[850],
                        ),
                        child: imageUrl.isEmpty
                            ? const Icon(
                                Icons.album,
                                color: Colors.white54,
                                size: 40,
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 120,
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ];
  }

  Widget _buildSongList({List<SongResponse>? songs}) {
    final currentSongs = songs ?? widget.songs;
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final song = currentSongs[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SongCardSearch(
            songId: song.id.toString(),
            title: song.title,
            subtitle: song.author ?? song.username ?? 'Unknown Artist',
            imageUrl: song.imageUrl,
            onCardTap: () {
              final player = PlayerService();
              final songIds = widget.songs.map((s) => s.id.toString()).toList();
              final realIndex = widget.songs.indexOf(song);
              if (realIndex != -1) {
                player.setQueue(songIds, realIndex);
              }
            },
          ),
        );
      }, childCount: currentSongs.length),
    );
  }
}
