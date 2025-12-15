import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/search_response.dart';
import '../../service/api/api_user.dart';
import '../widgets/album_card_search.dart';
import '../widgets/artist_card_search.dart';
import '../widgets/song_card_search.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _apiUserService = ApiUserService();

  Timer? _debounce;
  String _query = '';
  SearchResponse _results = const SearchResponse();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value;
      _error = null;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _performSearch);
  }

  Future<void> _performSearch() async {
    final keyword = _query.trim();
    if (!mounted) return;
    if (keyword.isEmpty) {
      setState(() {
        _loading = false;
        _results = const SearchResponse();
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final resp = await _apiUserService.searchAll(keyword);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _results = resp.results;
      _error = resp.ok ? null : 'Không thể tải kết quả';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildSearchBar(context),
            const SizedBox(height: 16),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFFBDBDBD), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: _onQueryChanged,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Bạn muốn nghe gì?',
                        hintStyle: TextStyle(
                          color: Color(0xFFBDBDBD),
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      cursorColor: Colors.white,
                    ),
                  ),
                  if (_query.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFFBDBDBD)),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _query = '';
                          _results = const SearchResponse();
                          _error = null;
                        });
                        _focusNode.requestFocus();
                      },
                    ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Hủy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_query.isEmpty) {
      return const _EmptySearchState();
    }
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (_error != null) {
      return _MessageState(text: _error!);
    }

    final hasAny =
        _results.songs.isNotEmpty ||
        _results.albums.isNotEmpty ||
        _results.artists.isNotEmpty;
    if (!hasAny) {
      return const _MessageState(text: 'Không tìm thấy kết quả');
    }

    final children = <Widget>[
      if (_results.songs.isNotEmpty) ...[
        const _SectionTitle(label: 'Nhạc'),
        ..._results.songs.map(
          (song) => SongCardSearch(
            songId: song.id.toString(),
            title: song.title,
            subtitle: song.author ?? song.username ?? '',
            imageUrl: song.imageUrl,
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (_results.albums.isNotEmpty) ...[
        const _SectionTitle(label: 'Album'),
        ..._results.albums.map(
          (album) => AlbumCardSearch(
            title: album.title,
            subtitle: 'Album',
            imageUrl: album.imageUrl,
          ),
        ),
        const SizedBox(height: 12),
      ],
      if (_results.artists.isNotEmpty) ...[
        const _SectionTitle(label: 'Nghệ sĩ'),
        ..._results.artists.map(
          (artist) =>
              ArtistCardSearch(name: artist.name, imageUrl: artist.imageUrl),
        ),
      ],
      const SizedBox(height: 80),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      children: children,
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Phát nội dung bạn thích',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Tìm kiếm nghệ sĩ, bài hát, podcast, v.v.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final String text;
  const _MessageState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
