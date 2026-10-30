import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:todoapp/focus/focus_sound.dart';

/// Nghe thử một đĩa trong cửa hàng (tự dừng sau [length]). Mỗi bảng chi tiết tạo một cái
/// riêng và [dispose] khi đóng bảng, nên đóng bảng là hết tiếng.
class SoundPreviewer extends ChangeNotifier {
  static const Duration length = Duration(seconds: 12);

  final AudioPlayer _player = AudioPlayer();
  Timer? _timer;
  String? _playingId;
  bool _ready = false;
  bool _disposed = false;

  String? get playingId => _playingId;

  bool isPlaying(String id) => _playingId == id;

  /// Bấm lần một: nghe thử; bấm lần hai: dừng.
  Future<void> toggle(FocusSound sound) async {
    if (isPlaying(sound.id)) {
      await stop();
      return;
    }
    final path = sound.sourcePath;
    if (path == null || _disposed) return;
    try {
      if (!_ready) {
        await _player.setReleaseMode(ReleaseMode.loop);
        _ready = true;
      }
      await _player.stop();
      await _player.play(AssetSource(path));
      if (_disposed) return;
      _playingId = sound.id;
      _timer?.cancel();
      _timer = Timer(length, () => stop());
      notifyListeners();
    } catch (e) {
      debugPrint('Không nghe thử được: $e');
    }
  }

  Future<void> stop() async {
    _timer?.cancel();
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('Không dừng được bản nghe thử: $e');
    }
    if (_playingId != null && !_disposed) {
      _playingId = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _player.stop().whenComplete(_player.dispose).catchError((Object e) {
      debugPrint('Lỗi đóng máy nghe thử: $e');
    });
    super.dispose();
  }
}