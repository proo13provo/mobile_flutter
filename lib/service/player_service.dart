import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PlayerService extends ChangeNotifier {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal() {
    _restoreState();
  }

  final _storage = const FlutterSecureStorage();

  String? _currentSongId;
  bool _showPlayer = false;
  bool _isModalOpen = false;
  bool _isExpanded = false;
  bool _isPlaying = false;

  List<String> _queue = [];
  int _currentIndex = -1;

  String? get currentSongId => _currentSongId;
  bool get showPlayer => _showPlayer;
  bool get isModalOpen => _isModalOpen;
  bool get isExpanded => _isExpanded;
  bool get isPlaying => _isPlaying;
  bool get hasNext => _queue.isNotEmpty && _currentIndex < _queue.length - 1;
  bool get hasPrevious => _queue.isNotEmpty && _currentIndex > 0;

  void setSong(String songId) {
    setQueue([songId], 0);
  }

  void setQueue(
    List<String> songIds,
    int initialIndex, {
    bool autoExpand = true,
    bool autoPlay = true,
  }) {
    _queue = List.from(songIds);
    _currentIndex = initialIndex;
    if (_currentIndex >= 0 && _currentIndex < _queue.length) {
      _currentSongId = _queue[_currentIndex];
      _showPlayer = true;
      _isExpanded = autoExpand;
      _isPlaying = autoPlay;
      notifyListeners();
      _saveState();
    }
  }

  void next() {
    if (hasNext) {
      _currentIndex++;
      _currentSongId = _queue[_currentIndex];
      _isPlaying = true;
      notifyListeners();
      _saveState();
    }
  }

  void previous() {
    if (hasPrevious) {
      _currentIndex--;
      _currentSongId = _queue[_currentIndex];
      _isPlaying = true;
      notifyListeners();
      _saveState();
    }
  }

  void hide() {
    _showPlayer = false;
    notifyListeners();
  }

  void setModalOpen(bool isOpen) {
    if (_isModalOpen != isOpen) {
      _isModalOpen = isOpen;
      notifyListeners();
    }
  }

  void setExpanded(bool expanded) {
    if (_isExpanded != expanded) {
      _isExpanded = expanded;
      notifyListeners();
    }
  }

  void play() {
    _isPlaying = true;
    notifyListeners();
  }

  void pause() {
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> _saveState() async {
    if (_currentSongId == null) return;
    try {
      await _storage.write(key: 'player_song_id', value: _currentSongId);
      await _storage.write(
        key: 'player_index',
        value: _currentIndex.toString(),
      );
      await _storage.write(key: 'player_queue', value: jsonEncode(_queue));
    } catch (e) {
      debugPrint('Error saving player state: $e');
    }
  }

  Future<void> _restoreState() async {
    try {
      final songId = await _storage.read(key: 'player_song_id');
      final indexStr = await _storage.read(key: 'player_index');
      final queueStr = await _storage.read(key: 'player_queue');

      if (songId != null && indexStr != null && queueStr != null) {
        final index = int.tryParse(indexStr);
        final List<dynamic> decodedQueue = jsonDecode(queueStr);
        final queue = decodedQueue.map((e) => e.toString()).toList();

        if (index != null && index >= 0 && index < queue.length) {
          // Gọi setQueue để khôi phục trạng thái và hiển thị Player
          setQueue(queue, index, autoExpand: false, autoPlay: false);
        }
      }
    } catch (e) {
      debugPrint('Error restoring player state: $e');
    }
  }
}
