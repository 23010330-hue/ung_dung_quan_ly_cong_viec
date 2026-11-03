import 'package:audioplayers/audioplayers.dart' show AssetSource;
import 'package:flutter_test/flutter_test.dart';
import 'package:todoapp/focus/focus_session.dart';
import 'package:todoapp/focus/focus_sound.dart';

void main() {
  group('FocusSession (US18 đến US22)', () {
    late FocusSession session;

    setUp(() {
      session = FocusSession();
      addTearDown(session.dispose);
    });

    test('lúc đầu: chờ, 60 phút, tiến độ 0', () {
      expect(session.phase, FocusPhase.idle);
      expect(session.total, const Duration(minutes: 60));
      expect(session.progress, 0);
    });

    test('chọn mốc thời gian (US18)', () {
      for (final minutes in kFocusMinuteOptions) {
        session.selectDuration(Duration(minutes: minutes));
        expect(session.total, Duration(minutes: minutes));
      }
    });

    test('đang chạy thì không đổi được mốc', () {
      session.start();
      session.selectDuration(const Duration(minutes: 30));
      expect(session.total, const Duration(minutes: 60));
    });

    test('bắt đầu phiên (US19)', () {
      var notified = 0;
      session.addListener(() => notified++);
      session.start();
      expect(session.phase, FocusPhase.running);
      expect(notified, 1);
      session.start();
      expect(notified, 1);
    });

    test('tạm dừng rồi tiếp tục (US20)', () {
      session.start();
      session.pause();
      expect(session.phase, FocusPhase.paused);
      expect(session.pausedByLeaving, isFalse);
      session.resume();
      expect(session.phase, FocusPhase.running);
    });

    test('tạm dừng vì rời app được đánh dấu và xóa dấu khi tiếp tục (US22)', () {
      session.start();
      session.pause(byLeaving: true);
      expect(session.pausedByLeaving, isTrue);
      session.resume();
      expect(session.pausedByLeaving, isFalse);
    });

    test('không tạm dừng hoặc tiếp tục được khi sai trạng thái', () {
      session.pause();
      expect(session.phase, FocusPhase.idle);
      session.resume();
      expect(session.phase, FocusPhase.idle);
      session.start();
      session.resume();
      expect(session.phase, FocusPhase.running);
    });

    test('kết thúc sớm đưa về trạng thái chờ (US21)', () {
      session.start();
      session.stop();
      expect(session.phase, FocusPhase.idle);
      expect(session.progress, 0);
    });

    test('kết thúc sớm cả khi đang tạm dừng', () {
      session.start();
      session.pause();
      session.stop();
      expect(session.phase, FocusPhase.idle);
    });

    test('acknowledgeFinished không làm gì khi chưa hoàn thành', () {
      session.start();
      session.acknowledgeFinished();
      expect(session.phase, FocusPhase.running);
    });

    test('tiến độ luôn nằm trong khoảng 0 đến 1', () {
      session.start();
      expect(session.progress, inInclusiveRange(0.0, 1.0));
      expect(session.remaining <= session.total, isTrue);
    });

    test('các mốc thời gian và hệ số tốc độ', () {
      expect(kFocusMinuteOptions, [30, 60, 90, 120]);
      expect(kFocusTimeScale, 1);
    });
  });

  group('Đĩa nhạc (US23, US24)', () {
    test('tìm đĩa theo id', () {
      expect(findSound('lofi')?.id, 'lofi');
      expect(findSound('none'), same(kNoSound));
      expect(findSound('khong-co'), isNull);
      expect(findSound(null), isNull);
    });

    test('soundById quay về đĩa mặc định khi id lạ', () {
      expect(soundById('khong-co').id, kDefaultSoundId);
      expect(soundById(null).id, kDefaultSoundId);
      expect(soundById('none').id, 'none');
    });

    test('id của các đĩa không trùng nhau và không trùng với "none"', () {
      final ids = [for (final s in kFocusSounds) s.id];
      expect(ids.toSet().length, ids.length);
      expect(ids.contains(kNoSound.id), isFalse);
    });

    test('đĩa có sẵn phát từ assets, "không phát nhạc" thì không phát gì', () {
      final lofi = soundById('lofi');
      expect(lofi.audioSource, isA<AssetSource>());
      expect((lofi.audioSource as AssetSource).path, 'sounds/lofi.wav');
      expect(lofi.hasCover, isTrue);
      expect(kNoSound.audioSource, isNull);
      expect(kNoSound.hasCover, isFalse);
    });
  });
}
