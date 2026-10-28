import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:todoapp/focus/focus_audio.dart';
import 'package:todoapp/focus/focus_session.dart';
import 'package:todoapp/focus/record_player_painter.dart';
import 'package:todoapp/focus/sound_picker_sheet.dart';
import 'package:todoapp/theme/app_colors.dart';

/// Chế độ tập trung: chọn mốc thời gian, chọn đĩa nhạc, bấm bắt đầu, máy đĩa than chạy.
class FocusPage extends StatefulWidget {
  final AppColorTheme colorTheme;
  final bool isVietnamese;
  final String Function(String) translate;

  const FocusPage({
    super.key,
    required this.colorTheme,
    required this.isVietnamese,
    required this.translate,
  });

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _textColor = Color(0xFF2D2A26);

  final _session = FocusSession();
  final _audio = FocusAudio();
  final ValueNotifier<double> _discAngle = ValueNotifier<double>(0);

  // cần kim: 0 = nằm nghỉ, 1 = đã hạ xuống đĩa
  late final AnimationController _arm = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  // đĩa quay: tăng tốc khi bắt đầu, giảm tốc dần khi dừng
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastTick = Duration.zero;
  double _spinSpeed = 0;
  double _spinTarget = 0;

  FocusPhase _lastPhase = FocusPhase.idle;
  DateTime? _leftAt;

  AppColorTheme get _theme => widget.colorTheme;
  String Function(String) get translate => widget.translate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session.removeListener(_onSessionChanged);
    _ticker.dispose();
    _arm.dispose();
    _discAngle.dispose();
    _audio.dispose();
    _session.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;

    final rate = _spinTarget > _spinSpeed ? 1.0 : 0.7; // đơn vị tốc độ / giây
    if (_spinSpeed < _spinTarget) {
      _spinSpeed = min(_spinTarget, _spinSpeed + rate * dt);
    } else if (_spinSpeed > _spinTarget) {
      _spinSpeed = max(_spinTarget, _spinSpeed - rate * dt);
    }
    if (_spinSpeed > 0) {
      // 0,55 vòng/giây ~ 33 vòng/phút như đĩa than thật
      _discAngle.value = (_discAngle.value + _spinSpeed * 2 * pi * 0.55 * dt) % (2 * pi);
    } else if (_spinTarget == 0) {
      // đĩa đã đứng yên: tắt ticker cho đỡ tốn pin, lần quay sau sẽ bật lại
      _ticker.stop();
      _lastTick = Duration.zero;
    }
  }

  void _onSessionChanged() {
    final phase = _session.phase;
    if (phase != _lastPhase) {
      _lastPhase = phase;
      _audio.syncPhase(phase); // nhạc chạy/dừng theo phiên tập trung
      final playing = phase == FocusPhase.running;
      _spinTarget = playing ? 1.0 : 0.0;
      if (playing) {
        if (!_ticker.isActive) {
          _lastTick = Duration.zero;
          _ticker.start();
        }
        _arm.forward();
      } else {
        _arm.reverse();
      }
    }
  }

  /// Rời app: tạm dừng ngay. Quay lại trong thời gian cho phép thì tự chạy tiếp.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden || state == AppLifecycleState.paused) {
      if (_session.phase == FocusPhase.running) {
        _leftAt = DateTime.now();
        _session.pause(byLeaving: true);
      }
    } else if (state == AppLifecycleState.resumed) {
      final left = _leftAt;
      _leftAt = null;
      if (left != null &&
          _session.phase == FocusPhase.paused &&
          _session.pausedByLeaving &&
          DateTime.now().difference(left) <= kFocusLeaveGrace) {
        _session.resume();
      }
    }
  }

  Future<void> _confirmStop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _theme.light,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            translate('Kết thúc phiên tập trung?'),
            style: const TextStyle(fontWeight: FontWeight.bold, color: _textColor),
          ),
          content: Text(translate('Thời gian đã chạy sẽ không được tính.')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(translate('Hủy'), style: TextStyle(color: _theme.dark)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE57373),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(translate('Kết thúc')),
            ),
          ],
        );
      },
    );
    if (confirmed == true) _session.stop();
  }

  // ------------------------------------------------------------- giao diện
  ButtonStyle _filledStyle() => ElevatedButton.styleFrom(
        backgroundColor: _theme.dark,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );

  ButtonStyle _outlinedStyle() => OutlinedButton.styleFrom(
        foregroundColor: _theme.dark,
        backgroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(color: _theme.dark, width: 1.5),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );

  Widget _buildDurationChips() {
    final enabled = _session.phase == FocusPhase.idle;
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: kFocusMinuteOptions.map((minutes) {
        final selected = _session.total.inMinutes == minutes;
        return ChoiceChip(
          label: Text('$minutes ${translate('phút')}'),
          selected: selected,
          showCheckmark: false,
          selectedColor: _theme.primary,
          backgroundColor: Colors.white,
          disabledColor: Colors.white.withValues(alpha: 0.6),
          side: BorderSide(color: _theme.primary),
          labelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? _theme.dark : _textColor,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          onSelected: enabled
              ? (_) => _session.selectDuration(Duration(minutes: minutes))
              : null,
        );
      }).toList(),
    );
  }

  void _openSoundPicker() {
    showSoundPicker(
      context: context,
      audio: _audio,
      colorTheme: _theme,
      isVietnamese: widget.isVietnamese,
      translate: translate,
    );
  }

  /// Nút dưới máy đĩa than: hiện đĩa đang chọn, bấm để mở bảng chọn đĩa.
  Widget _buildSoundButton() {
    final sound = _audio.selected;
    final label = soundLabelColor(sound, _theme);
    return Center(
      child: Material(
        color: Colors.white,
        shape: StadiumBorder(side: BorderSide(color: _theme.primary, width: 1.5)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: _openSoundPicker,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1E1E1E),
                  ),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: label),
                    child: Icon(
                      sound.icon,
                      size: 13,
                      color: Color.lerp(label, Colors.black, 0.55),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    sound.name(widget.isVietnamese),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.expand_more, color: _theme.dark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatus() {
    late final String text;
    late final IconData icon;
    switch (_session.phase) {
      case FocusPhase.idle:
        text = translate('Sẵn sàng');
        icon = Icons.album;
      case FocusPhase.running:
        text = translate('Đang tập trung');
        icon = Icons.headphones;
      case FocusPhase.paused:
        text = translate('Đã tạm dừng');
        icon = Icons.pause_circle_outline;
      case FocusPhase.finished:
        text = translate('Hoàn thành!');
        icon = Icons.emoji_events_outlined;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: _theme.dark),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _theme.dark,
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    switch (_session.phase) {
      case FocusPhase.idle:
        return ElevatedButton.icon(
          onPressed: _session.start,
          style: _filledStyle(),
          icon: const Icon(Icons.play_arrow_rounded, size: 26),
          label: Text(translate('Bắt đầu')),
        );
      case FocusPhase.running:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _session.pause,
                style: _outlinedStyle(),
                icon: const Icon(Icons.pause_rounded),
                label: Text(translate('Tạm dừng')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _confirmStop,
                style: _outlinedStyle(),
                icon: const Icon(Icons.stop_rounded),
                label: Text(translate('Kết thúc')),
              ),
            ),
          ],
        );
      case FocusPhase.paused:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _session.resume,
                style: _filledStyle(),
                icon: const Icon(Icons.play_arrow_rounded, size: 26),
                label: Text(translate('Tiếp tục')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _confirmStop,
                style: _outlinedStyle(),
                icon: const Icon(Icons.stop_rounded),
                label: Text(translate('Kết thúc')),
              ),
            ),
          ],
        );
      case FocusPhase.finished:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                translate('Bạn đã tập trung xong. Làm tốt lắm!'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _session.acknowledgeFinished,
                style: _filledStyle(),
                child: Text(translate('Xong')),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildNotice({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _theme.primary),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _theme.dark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _theme.light,
      appBar: AppBar(
        title: Text(
          translate('Chế độ tập trung'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _theme.primary,
        foregroundColor: Colors.black,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([_session, _audio]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _buildDurationChips(),
              if (kFocusTimeScale != 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Thử nhanh x$kFocusTimeScale',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AspectRatio(
                    aspectRatio: 1 / 1.12,
                    child: CustomPaint(
                      painter: RecordPlayerPainter(
                        session: _session,
                        arm: _arm,
                        discAngle: _discAngle,
                        labelColor: soundLabelColor(_audio.selected, _theme),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _buildSoundButton(),
              const SizedBox(height: 14),
              _buildStatus(),
              const SizedBox(height: 14),
              if (_session.phase == FocusPhase.paused && _session.pausedByLeaving)
                _buildNotice(
                  icon: Icons.info_outline,
                  text: translate('Đã tạm dừng vì bạn rời khỏi app'),
                ),
              _buildControls(),
              const SizedBox(height: 16),
              Text(
                translate(
                  'Nếu rời khỏi app, đồng hồ sẽ tạm dừng. Quay lại trong 1 phút thì tự chạy tiếp.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          );
        },
      ),
    );
  }
}