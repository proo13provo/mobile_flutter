import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:spotife/models/song_detail_response.dart';
import 'package:spotife/service/api/api_user.dart';
import 'package:spotife/service/api/song_service.dart';
import 'package:spotife/service/player_service.dart';
import 'package:video_player/video_player.dart';
import 'package:spotife/views/widgets/add_to_playlist_sheet.dart';

class SongDetailScreen extends StatefulWidget {
  final String songId;
  final bool isMini;
  final VoidCallback? onMiniTap;
  final VoidCallback? onMinimize;

  const SongDetailScreen({
    super.key,
    required this.songId,
    this.isMini = false,
    this.onMiniTap,
    this.onMinimize,
  });

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  final SongService _songService = SongService();
  final ApiUserService _apiUserService = ApiUserService();
  VideoPlayerController? _videoController;

  bool _isLoading = true;
  SongDetailResponse? _songDetail;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    PlayerService().addListener(_onPlayerStateChange);
    _initSong();
  }

  @override
  void didUpdateWidget(covariant SongDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songId != widget.songId) {
      _videoController?.dispose();
      _videoController = null;
      _initSong();
    }
  }

  void _onPlayerStateChange() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      final isServicePlaying = PlayerService().isPlaying;
      final isVideoPlaying = _videoController!.value.isPlaying;
      if (isServicePlaying && !isVideoPlaying) {
        _videoController!.play();
      } else if (!isServicePlaying && isVideoPlaying) {
        _videoController!.pause();
      }
    }
  }

  Future<void> _initSong() async {
    try {
      setState(() => _isLoading = true);
      final data = await _songService.fetchSongDetail(widget.songId);
      if (mounted) {
        setState(() {
          _songDetail = data;
          _isLoading = false;
        });

        if (data != null && data.song.mediaUrl.isNotEmpty) {
          _videoController = VideoPlayerController.networkUrl(
            Uri.parse(data.song.mediaUrl),
          );
          await _videoController!.initialize();
          if (PlayerService().isPlaying) {
            _videoController!.play();
          } else {
            _videoController!.pause();
          }
          _videoController!.addListener(_onSongFinished);
          _songService.listenSong(widget.songId); // Ghi nhận lượt nghe
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading song: $e')));
      }
    }
  }

  void _onSongFinished() {
    if (_videoController == null) return;
    final value = _videoController!.value;
    if (value.isInitialized &&
        value.duration > Duration.zero &&
        value.position >= value.duration) {
      _videoController!.removeListener(_onSongFinished);
      PlayerService().next();
    }
  }

  Future<void> _toggleLike() async {
    setState(() => _isLiked = !_isLiked);
    try {
      final sId = int.tryParse(widget.songId);
      if (sId == null) return;

      bool success;
      if (_isLiked) {
        success = await _apiUserService.follow(sId, 'Song');
      } else {
        success = await _apiUserService.unfollow(sId, 'Song');
      }

      if (!success && mounted) {
        setState(() => _isLiked = !_isLiked);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    PlayerService().removeListener(_onPlayerStateChange);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Spotify-like dark theme colors
    const bgColor = Color(0xFF121212);
    const primaryColor = Colors.white;
    const secondaryColor = Colors.white70;

    // --- MINI PLAYER UI ---
    if (widget.isMini) {
      return _buildMiniPlayer(bgColor, primaryColor, secondaryColor);
    }

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1DB954)),
        ),
      );
    }

    if (_songDetail == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(
          child: Text('Song not found', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final song = _songDetail!.song;
    final artist = _songDetail!.artist;

    // --- FULL PLAYER UI ---
    return GestureDetector(
      onVerticalDragEnd: (details) {
        // Vuốt xuống để thu nhỏ
        if (details.primaryVelocity != null && details.primaryVelocity! > 500) {
          widget.onMinimize?.call();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 30,
            ),
            onPressed: widget.onMinimize, // Nút mũi tên cũng thu nhỏ
          ),
          centerTitle: true,
          title: Column(
            children: [
              const Text(
                'PLAYING FROM ARTIST',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  color: Colors.white70,
                ),
              ),
              Text(
                artist.username,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) =>
                      AddToPlaylistSheet(songId: widget.songId),
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            // 1. Video Background Layer
            if (_videoController != null &&
                _videoController!.value.isInitialized)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              )
            else
              // Fallback background nếu video chưa load
              Container(color: const Color(0xFF121212)),

            // 2. Gradient Overlay Layer (để chữ dễ đọc hơn trên nền video)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black12, // Trên cùng hơi tối nhẹ
                    Colors.black26,
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(
                      0.9,
                    ), // Dưới cùng tối hẳn để hiện controls
                  ],
                  stops: const [0.0, 0.5, 0.8, 1.0],
                ),
              ),
            ),

            // 3. Content Layer (Controls)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Đẩy nội dung xuống dưới, để khoảng trống cho video
                  const Spacer(),

                  // Title and Artist
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: const TextStyle(
                                color: primaryColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              artist.username,
                              style: const TextStyle(
                                color: secondaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked
                              ? const Color(0xFF1DB954)
                              : Colors.white,
                          size: 28,
                        ),
                        onPressed: _toggleLike,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Progress Bar
                  if (_videoController != null)
                    ValueListenableBuilder(
                      valueListenable: _videoController!,
                      builder: (context, value, child) {
                        final duration = value.duration;
                        final position = value.position;

                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.white,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: Colors.white,
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 12,
                                ),
                              ),
                              child: Slider(
                                min: 0.0,
                                max: duration.inMilliseconds.toDouble() > 0
                                    ? duration.inMilliseconds.toDouble()
                                    : 1.0,
                                value: position.inMilliseconds.toDouble().clamp(
                                  0,
                                  duration.inMilliseconds.toDouble() > 0
                                      ? duration.inMilliseconds.toDouble()
                                      : 1.0,
                                ),
                                onChanged: (val) {
                                  _videoController?.seekTo(
                                    Duration(milliseconds: val.toInt()),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(position),
                                    style: const TextStyle(
                                      color: secondaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(duration),
                                    style: const TextStyle(
                                      color: secondaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 10),

                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shuffle, color: Colors.white),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.skip_previous,
                          color: Colors.white,
                          size: 36,
                        ),
                        onPressed: () {
                          PlayerService().previous();
                        },
                      ),
                      if (_videoController != null)
                        ValueListenableBuilder(
                          valueListenable: _videoController!,
                          builder: (context, value, child) {
                            final isPlaying = value.isPlaying;
                            return IconButton(
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_fill,
                                color: Colors.white,
                                size: 72,
                              ),
                              onPressed: () {
                                if (isPlaying) {
                                  _videoController?.pause();
                                  PlayerService().pause();
                                } else {
                                  _videoController?.play();
                                  PlayerService().play();
                                }
                              },
                            );
                          },
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.skip_next,
                          color: Colors.white,
                          size: 36,
                        ),
                        onPressed: () {
                          PlayerService().next();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.repeat, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayer(Color bgColor, Color primary, Color secondary) {
    final song = _songDetail?.song;
    final artist = _songDetail?.artist;

    return GestureDetector(
      onTap: widget.onMiniTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: const Color(
              0xFF282828,
            ).withOpacity(0.8), // Màu nền bán trong suốt
            height: 60,
            child: Stack(
              children: [
                // Giữ VideoPlayer kích thước 1x1 để duy trì kết nối buffer,
                // giúp nhạc không bị ngắt và tránh lỗi "Unable to acquire a buffer item".
                if (_videoController != null &&
                    _videoController!.value.isInitialized)
                  SizedBox(
                    width: 1,
                    height: 1,
                    child: VideoPlayer(_videoController!),
                  ),
                Row(
                  children: [
                    // Video/Image nhỏ
                    if (song != null && song.imageUrl.isNotEmpty)
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: Image.network(song.imageUrl, fit: BoxFit.cover),
                      )
                    else
                      Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                        ),
                      ),
                    const SizedBox(width: 12),
                    // Title
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song?.title ?? 'Loading...',
                            style: TextStyle(
                              color: primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            artist?.username ?? '',
                            style: TextStyle(color: secondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Play/Pause Button
                    if (_videoController != null)
                      ValueListenableBuilder(
                        valueListenable: _videoController!,
                        builder: (context, value, child) {
                          return IconButton(
                            icon: Icon(
                              value.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              if (value.isPlaying) {
                                _videoController?.pause();
                                PlayerService().pause();
                              } else {
                                _videoController?.play();
                                PlayerService().play();
                              }
                            },
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
