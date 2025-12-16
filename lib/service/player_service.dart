import 'package:flutter/foundation.dart';

class PlayerService extends ChangeNotifier {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();

  String? _currentSongId;
  bool _showPlayer = false;
  bool _isModalOpen = false;

  List<String> _queue = [];
  int _currentIndex = -1;

  String? get currentSongId => _currentSongId;
  bool get showPlayer => _showPlayer;
  bool get isModalOpen => _isModalOpen;
  bool get hasNext => _queue.isNotEmpty && _currentIndex < _queue.length - 1;
  bool get hasPrevious => _queue.isNotEmpty && _currentIndex > 0;

  void setSong(String songId) {
    setQueue([songId], 0);
  }

  void setQueue(List<String> songIds, int initialIndex) {
    _queue = List.from(songIds);
    _currentIndex = initialIndex;
    if (_currentIndex >= 0 && _currentIndex < _queue.length) {
      _currentSongId = _queue[_currentIndex];
      _showPlayer = true;
      notifyListeners();
    }
  }

  void next() {
    if (hasNext) {
      _currentIndex++;
      _currentSongId = _queue[_currentIndex];
      notifyListeners();
    }
  }

  void previous() {
    if (hasPrevious) {
      _currentIndex--;
      _currentSongId = _queue[_currentIndex];
      notifyListeners();
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
}
