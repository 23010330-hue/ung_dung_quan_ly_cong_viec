import 'dart:async';
import 'package:flutter/foundation.dart';

/// Hệ số tăng tốc thời gian để thử nhanh khi phát triển.
/// 1 = bình thường. Đặt 60 thì 1 giây thật = 1 phút trên đồng hồ.
/// NHỚ đặt lại về 1 trước khi nộp bài.
const int kFocusTimeScale = 1;

/// Rời app trong khoảng này rồi quay lại thì đồng hồ tự chạy tiếp.
const Duration kFocusLeaveGrace = Duration(minutes: 1);

/// Các mốc thời gian được phép chọn (phút).
const List<int> kFocusMinuteOptions = [30, 60, 90, 120];

/// Cứ chạy được chừng này thì đồng hồ tạm dừng và hỏi "Bạn còn đó không?".
/// Không bấm xác nhận thì đồng hồ đứng yên, không tính thêm giờ và không có coin.
const Duration kFocusCheckInEvery = Duration(hours: 1);

enum FocusPhase { idle, running, paused, finished }

/// Một phiên tập trung: chọn mốc, bắt đầu, tạm dừng, tiếp tục, kết thúc.
///
/// Thời gian được tính bằng Stopwatch (không phụ thuộc đồng hồ máy và
/// không bị trình duyệt làm chậm khi tab ở nền), Timer chỉ để báo giao diện cập nhật.
/// Coin chỉ được cộng khi phiên chạy hết giờ ([FocusPhase.finished]); trang tập trung lo phần đó.
class FocusSession extends ChangeNotifier {
  FocusPhase phase = FocusPhase.idle;
  Duration total = const Duration(minutes: 60);

  /// true nếu phiên đang tạm dừng vì người dùng rời khỏi app.
  bool pausedByLeaving = false;

  /// true nếu phiên đang tạm dừng để hỏi "Bạn còn đó không?". Bấm [resume] là xác nhận.
  bool awaitingCheckIn = false;

  Duration _nextCheckIn = kFocusCheckInEvery;
  Duration _accumulated = Duration.zero;
  final Stopwatch _segment = Stopwatch();
  Timer? _timer;

  Duration get elapsed {
    final e = _accumulated + (_segment.elapsed * kFocusTimeScale);
    return e > total ? total : e;
  }

  Duration get remaining => total - elapsed;

  double get progress {
    if (total.inMilliseconds == 0) return 0;
    return (elapsed.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
  }

  void selectDuration(Duration value) {
    if (phase != FocusPhase.idle) return;
    total = value;
    notifyListeners();
  }

  void start() {
    if (phase != FocusPhase.idle) return;
    _accumulated = Duration.zero;
    _segment
      ..reset()
      ..start();
    pausedByLeaving = false;
    awaitingCheckIn = false;
    _nextCheckIn = kFocusCheckInEvery;
    phase = FocusPhase.running;
    _startTimer();
    notifyListeners();
  }

  void pause({bool byLeaving = false}) {
    if (phase != FocusPhase.running) return;
    _accumulated += _segment.elapsed * kFocusTimeScale;
    _segment
      ..stop()
      ..reset();
    pausedByLeaving = byLeaving;
    phase = FocusPhase.paused;
    _stopTimer();
    notifyListeners();
  }

  void resume() {
    if (phase != FocusPhase.paused) return;
    pausedByLeaving = false;
    if (awaitingCheckIn) {
      // bấm tiếp tục = xác nhận "tôi còn đây"; mốc hỏi kế tiếp là 1 giờ nữa
      awaitingCheckIn = false;
      _nextCheckIn += kFocusCheckInEvery;
    }
    _segment
      ..reset()
      ..start();
    phase = FocusPhase.running;
    _startTimer();
    notifyListeners();
  }

  /// Kết thúc sớm: bỏ phiên hiện tại, về trạng thái chờ.
  void stop() {
    _stopTimer();
    _segment
      ..stop()
      ..reset();
    _accumulated = Duration.zero;
    pausedByLeaving = false;
    awaitingCheckIn = false;
    _nextCheckIn = kFocusCheckInEvery;
    phase = FocusPhase.idle;
    notifyListeners();
  }

  /// Người dùng đã xem xong thông báo hoàn thành.
  void acknowledgeFinished() {
    if (phase != FocusPhase.finished) return;
    stop();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (elapsed >= total) {
        _finish();
      } else if (elapsed >= _nextCheckIn) {
        awaitingCheckIn = true;
        pause(); // đứng đồng hồ cho đến khi người dùng xác nhận còn đó
      } else {
        notifyListeners();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _finish() {
    _stopTimer();
    _segment
      ..stop()
      ..reset();
    _accumulated = total;
    phase = FocusPhase.finished;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}