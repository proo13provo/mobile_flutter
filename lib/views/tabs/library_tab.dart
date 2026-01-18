import 'package:flutter/material.dart';
import 'package:spotife/models/album_response.dart';
import 'package:spotife/models/artist_response.dart';
import 'package:spotife/models/playlist_response.dart';
import 'package:spotife/models/song_response.dart';
import 'package:spotife/service/api/albums_service.dart';
import 'package:spotife/service/api/api_user.dart';
import 'package:spotife/service/api/playlist_service.dart';
import 'package:spotife/service/api/song_service.dart';
import 'package:spotife/views/screens/create_playlist_screen.dart';
import 'package:spotife/views/screens/playlist_screen.dart';
import 'package:spotife/views/widgets/user_avatar.dart';

class LibraryTab extends StatefulWidget {
  const LibraryTab({
    super.key,
    this.avatarUrl,
    this.avatarLetter,
    this.onAvatarTap,
  });

  final String? avatarUrl;
  final String? avatarLetter;
  final VoidCallback? onAvatarTap;

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  final PlaylistService _playlistService = PlaylistService();
  final ApiUserService _apiUserService = ApiUserService();
  final SongService _songService = SongService();
  final AlbumService _albumService = AlbumService();

  List<dynamic> _libraryItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLibrary();
  }

  Future<void> _fetchLibrary() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _playlistService.fetchMyPlaylists(),
        _apiUserService.fetchFollowedArtists(),
        _apiUserService.fetchFollowedAlbums(),
      ]);

      if (mounted) {
        setState(() {
          _libraryItems = [
            ...results[0] as List<PlaylistResponse>,
            ...results[1] as List<ArtistResponse>,
            ...results[2] as List<AlbumResponse>,
          ];
        });
      }
    } catch (e) {
      debugPrint('Error fetching library: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deletePlaylist(int playlistId) async {
    final success = await _playlistService.deletePlaylist(playlistId);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa playlist')));
        _fetchLibrary();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lỗi khi xóa playlist')));
      }
    }
  }

  void _confirmDelete(BuildContext context, PlaylistResponse playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text(
          'Xóa Playlist',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa playlist "${playlist.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePlaylist(playlist.id);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _unfollowItem(int id, String type) async {
    final success = await _apiUserService.unfollow(id, type);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã bỏ theo dõi')));
        _fetchLibrary();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lỗi khi bỏ theo dõi')));
      }
    }
  }

  void _confirmUnfollow(
    BuildContext context,
    int id,
    String type,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF282828),
        title: const Text('Bỏ theo dõi', style: TextStyle(color: Colors.white)),
        content: Text(
          'Bạn có chắc chắn muốn bỏ theo dõi "$name"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _unfollowItem(id, type);
            },
            child: const Text(
              'Bỏ theo dõi',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8, bottom: 8),
          child: GestureDetector(
            onTap: widget.onAvatarTap,
            child: UserAvatar(
              imageUrl: widget.avatarUrl,
              fallbackLetter: widget.avatarLetter ?? 'S',
            ),
          ),
        ),
        title: const Text(
          'Thư viện',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 28),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePlaylistScreen(),
                ),
              );
              if (result != null) {
                _fetchLibrary();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1DB954)),
            )
          : RefreshIndicator(
              onRefresh: _fetchLibrary,
              color: const Color(0xFF1DB954),
              backgroundColor: Colors.grey[900],
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                itemCount:
                    _libraryItems.length + 1, // +1 cho mục "Bài hát đã thích"
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF450AF5), Color(0xFFC4EFD9)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      title: const Text(
                        'Bài hát đã thích',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Danh sách phát • Đã ghim',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      onTap: () {},
                    );
                  }

                  final item = _libraryItems[index - 1];

                  if (item is ArtistResponse) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        radius: 32,
                        backgroundImage: NetworkImage(item.imageUrl),
                        backgroundColor: Colors.grey[800],
                      ),
                      title: Text(
                        item.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Nghệ sĩ',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        color: const Color(0xFF282828),
                        onSelected: (value) {
                          if (value == 'unfollow') {
                            _confirmUnfollow(
                              context,
                              item.id,
                              'ARTIST',
                              item.username,
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'unfollow',
                            child: Text(
                              'Bỏ theo dõi',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      onTap: () async {
                        final songs = await _songService.fetchArtistSongs(
                          item.id,
                        );
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlaylistTab(
                              id: item.id,
                              title: item.username,
                              imageUrl: item.imageUrl,
                              type: 'Artist',
                              songs: songs,
                            ),
                          ),
                        );
                      },
                    );
                  } else if (item is AlbumResponse) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          image: DecorationImage(
                            image: NetworkImage(item.imageUrl),
                            fit: BoxFit.cover,
                          ),
                          color: Colors.grey[800],
                        ),
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Album',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        color: const Color(0xFF282828),
                        onSelected: (value) {
                          if (value == 'unfollow') {
                            _confirmUnfollow(
                              context,
                              item.id,
                              'ALBUM',
                              item.title,
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'unfollow',
                            child: Text(
                              'Bỏ theo dõi',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      onTap: () async {
                        final songs = await _albumService.fetchAlbumSongs(
                          item.id,
                        );
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlaylistTab(
                              id: item.id,
                              title: item.title,
                              imageUrl: item.imageUrl,
                              type: 'Album',
                              songs: songs,
                            ),
                          ),
                        );
                      },
                    );
                  }

                  // Default: PlaylistResponse
                  final playlist = item as PlaylistResponse;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white54,
                        size: 32,
                      ),
                    ),
                    title: Text(
                      playlist.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Danh sách phát',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      color: const Color(0xFF282828),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _confirmDelete(context, playlist);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Xóa playlist',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    onLongPress: () => _confirmDelete(context, playlist),
                    onTap: () async {
                      final detail = await _playlistService.fetchPlaylistDetail(
                        playlist.id,
                      );
                      if (!context.mounted) return;

                      if (detail != null) {
                        final playlistInfo = detail['playlist'];
                        final songList =
                            detail['songAndArtistResponses'] as List?;

                        final songs =
                            songList?.map((e) {
                              final songData = Map<String, dynamic>.from(
                                e['song'],
                              );
                              if (songData['id'] is String) {
                                songData['id'] =
                                    int.tryParse(songData['id']) ?? 0;
                              }
                              return SongResponse.fromJson(songData);
                            }).toList() ??
                            [];

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlaylistTab(
                              id: playlist.id,
                              title: playlistInfo != null
                                  ? playlistInfo['name']
                                  : playlist.name,
                              imageUrl: playlistInfo != null
                                  ? playlistInfo['imageUrl']
                                  : '',
                              type: 'Playlist',
                              songs: songs,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
    );
  }
}
