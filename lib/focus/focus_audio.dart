import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart' show Hive;
import 'package:todoapp/focus/focus_session.dart';
import 'package:todoapp/focus/focus_sound.dart';
import 'package:todoapp/services/auth_service.dart';
import 'package:todoapp/shop/sound_inventory.dart';

/// Phát âm thanh nền theo phiên tập trung và nhớ âm thanh đã chọn (mỗi tài khoản một lựa chọn).
///
/// - Đang chạy: phát lặp.   - Tạm dừng: dừng tạm, tiếp tục thì phát tiếp.
/// - Chờ / hoàn thành: tắt hẳn. Chọn đĩa lúc đang chờ thì nghe thử vài giây.
/// Lỗi âm thanh không bao giờ làm hỏng phiên tập trung (chỉ ghi log).
class FocusAudio extends ChangeNotifier {
  static const Duration _previewLength = Duration(seconds: 5);

  /// true khi một phiên tập trung đang phát nhạc. Cửa hàng dựa vào đây để không
  /// nghe thử đè lên nhạc đang tập trung.
  static final ValueNotifier<bool> sessionPlaying = ValueNotifier<bool>(false);

  FocusAudio() : _selectedId = _readSaved();

  String _selectedId;
  FocusPhase _phase = FocusPhase.idle;
  AudioPlayer? _player;
  String? _loadedId; // đĩa đang nằm trong máy phát
  bool _paused = false;
  Timer? _previewTimer;
  bool _disposed = false;

  String get selectedId => _selectedId;
  FocusSound get selected => soundById(_selectedId);

  static String get _key {
    final user = AuthService.instance.currentUsername?.toLowerCase() ?? '';
    return 'FOCUS_SOUND_$user';
  }

  static String _readSaved() {
    try {
      final saved = Hive.box('box_v3').get(_key) as String?;
      final sound = soundById(saved);
      if (sound.id == kNoSound.id) return sound.id;
      // đĩa đã chọn mà tài khoản không còn sở hữu thì quay về đĩa tặng sẵn
      return SoundInventory.instance.isOwned(sound.id) ? sound.id : kDefaultSoundId;
    } catch (_) {
      return kDefaultSoundId;
    }
  }

  /// Người dùng chọn một đĩa.
  Future<void> select(String id) async {
    final sound = soundById(id);
    // chỉ chọn được "không phát nhạc" hoặc đĩa đã có trong kho
    if (sound.id != kNoSound.id && !SoundInventory.instance.isOwned(sound.id)) return;
    final newId = sound.id;
    // đang tập trung mà bấm lại đúng đĩa đang phát: không làm gì
    if (newId == _selectedId && _phase != FocusPhase.idle) return;
    _selectedId = newId;
    try {
      await Hive.box('box_v3').put(_key, _selectedId);
    } catch (e) {
      debugPrint('Không lưu được âm thanh đã chọn: $e');
    }
    notifyListeners();

    switch (_phase) {
      case FocusPhase.running:
        await _playSelected(); // đổi đĩa ngay khi đang tập trung
      case FocusPhase.idle:
        await _preview();
      case FocusPhase.paused:
        // giữ nguyên trạng thái tạm dừng; đĩa mới sẽ phát khi bấm Tiếp tục
        await _safe(() async {
          await _player?.stop();
        });
        _loadedId = null;
        _paused = false;
      case FocusPhase.finished:
        break;
    }
  }

  /// Đóng bảng chọn đĩa: tắt đoạn nghe thử nếu chưa bắt đầu phiên tập trung.
  Future<void> stopPreview() async {
    if (_phase == FocusPhase.idle) await _stopPlayer();
  }

  /// Gọi mỗi khi phiên tập trung đổi trạng thái.
  Future<void> syncPhase(FocusPhase phase) async {
    _phase = phase;
    _previewTimer?.cancel();
    switch (phase) {
      case FocusPhase.running:
        await _playSelected();
      case FocusPhase.paused:
        await _safe(() async {
          await _player?.pause();
        });
        _paused = true;
        sessionPlaying.value = false;
      case FocusPhase.idle:
      case FocusPhase.finished:
        await _stopPlayer();
    }
  }

  Future<void> _playSelected() async {
    final sound = selected;
    final path = sound.sourcePath;
    if (path == null) {
      await _stopPlayer();
      return;
    }
    await _safe(() async {
      final player = await _ensurePlayer();
      if (_paused && _loadedId == sound.id) {
        await player.resume();
      } else {
        await player.play(AssetSource(path));
      }
    });
    _loadedId = sound.id;
    _paused = false;
    sessionPlaying.value = _phase == FocusPhase.running;
  }

  Future<void> _preview() async {
    _previewTimer?.cancel();
    if (selected.sourcePath == null) {
      await _stopPlayer();
      return;
    }
    await _playSelected();
    _previewTimer = Timer(_previewLength, () {
      if (_phase == FocusPhase.idle) _stopPlayer();
    });
  }

  Future<AudioPlayer> _ensurePlayer() async {
    final existing = _player;
    if (existing != null) return existing;
    final created = AudioPlayer();
    _player = created;
    await created.setReleaseMode(ReleaseMode.loop); // phát lặp
    await created.setVolume(0.8);
    return created;
  }

  Future<void> _stopPlayer() async {
    _previewTimer?.cancel();
    await _safe(() async {
      await _player?.stop();
    });
    _loadedId = null;
    _paused = false;
    sessionPlaying.value = false;
  }

  Future<void> _safe(Future<void> Function() action) async {
    if (_disposed) return;
    try {
      await action();
    } catch (e) {
      debugPrint('Lỗi phát âm thanh: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _previewTimer?.cancel();
    sessionPlaying.value = false;
    final player = _player;
    _player = null;
    if (player != null) {
      player.stop().whenComplete(player.dispose).catchError((Object e) {
        debugPrint('Lỗi đóng máy phát: $e');
      });
    }
    super.dispose();
  }
}