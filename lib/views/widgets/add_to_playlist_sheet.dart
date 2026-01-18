import 'package:flutter/material.dart';
import 'package:spotife/models/playlist_response.dart';
import 'package:spotife/service/api/playlist_service.dart';
import 'package:spotife/views/screens/create_playlist_screen.dart';

class AddToPlaylistSheet extends StatefulWidget {
  final String songId;

  const AddToPlaylistSheet({super.key, required this.songId});

  @override
  State<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<AddToPlaylistSheet> {
  final PlaylistService _playlistService = PlaylistService();
  List<PlaylistResponse> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlaylists();
  }

  Future<void> _fetchPlaylists() async {
    setState(() => _isLoading = true);
    try {
      final playlists = await _playlistService.fetchMyPlaylists();
      if (mounted) {
        setState(() {
          _playlists = playlists;
        });
      }
    } catch (e) {
      debugPrint('Error fetching playlists: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addSongToPlaylist(PlaylistResponse playlist) async {
    try {
      final sId = int.tryParse(widget.songId);
      if (sId == null) return;

      final success = await _playlistService.addSongToPlaylist(
        playlist.id,
        sId,
      );
      if (!mounted) return;

      Navigator.pop(context); // Đóng sheet

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã thêm vào ${playlist.name}')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Thêm thất bại')));
      }
    } catch (e) {
      debugPrint('Error adding song: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF282828),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Thêm vào danh sách phát',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Flexible(
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1DB954),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _playlists.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1DB954),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.add, color: Colors.black),
                            ),
                            title: const Text(
                              'Danh sách phát mới',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () async {
                              final sId = int.tryParse(widget.songId);
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CreatePlaylistScreen(songId: sId),
                                ),
                              );
                              if (result != null && mounted) {
                                Navigator.pop(
                                  context,
                                ); // Đóng sheet sau khi tạo thành công
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Đã tạo và thêm vào ${result.name}',
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        }
                        final playlist = _playlists[index - 1];
                        return ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white54,
                            ),
                          ),
                          title: Text(
                            playlist.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          onTap: () => _addSongToPlaylist(playlist),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
