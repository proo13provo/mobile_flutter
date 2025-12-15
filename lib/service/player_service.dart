import 'package:flutter/foundation.dart';

class PlayerService extends ChangeNotifier {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();

  String? _currentSongId;
  bool _showPlayer = false;
  bool _isModalOpen = false;

  String? get currentSongId => _currentSongId;
  bool get showPlayer => _showPlayer;
  bool get isModalOpen => _isModalOpen;

  void setSong(String songId) {
    // Nếu chọn bài mới hoặc bài cũ thì đều hiện player lên
    _currentSongId = songId;
    _showPlayer = true;
    notifyListeners();
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
