import 'package:flutter/material.dart';
import 'package:todoapp/focus/focus_audio.dart';
import 'package:todoapp/focus/focus_sound.dart';
import 'package:todoapp/theme/app_colors.dart';

/// Bảng chọn đĩa nhạc trượt từ dưới lên: mỗi âm thanh là một đĩa than.
/// Bấm vào đĩa là chọn ngay (lúc chưa tập trung sẽ nghe thử vài giây).
Future<void> showSoundPicker({
  required BuildContext context,
  required FocusAudio audio,
  required AppColorTheme colorTheme,
  required bool isVietnamese,
  required String Function(String) translate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: colorTheme.light,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _SoundPickerSheet(
      audio: audio,
      colorTheme: colorTheme,
      isVietnamese: isVietnamese,
      translate: translate,
    ),
  ).whenComplete(audio.stopPreview);
}

/// Màu nhãn đĩa hiển thị cho một âm thanh (đĩa "không phát nhạc" dùng màu giao diện).
Color soundLabelColor(FocusSound sound, AppColorTheme theme) =>
    sound.asset == null ? theme.primary : sound.color;

class _SoundPickerSheet extends StatefulWidget {
  final FocusAudio audio;
  final AppColorTheme colorTheme;
  final bool isVietnamese;
  final String Function(String) translate;

  const _SoundPickerSheet({
    required this.audio,
    required this.colorTheme,
    required this.isVietnamese,
    required this.translate,
  });

  @override
  State<_SoundPickerSheet> createState() => _SoundPickerSheetState();
}

class _SoundPickerSheetState extends State<_SoundPickerSheet>
    with SingleTickerProviderStateMixin {
  static const _textColor = Color(0xFF2D2A26);

  // đĩa đang chọn quay chầm chậm cho sinh động
  late final AnimationController _spin;

  AppColorTheme get _theme => widget.colorTheme;
  String Function(String) get translate => widget.translate;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  Widget _tile(FocusSound sound, bool selected) {
    final label = soundLabelColor(sound, _theme);
    final disc = CustomPaint(painter: _DiscPainter(label: label));
    final spinning = selected && sound.asset != null;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => widget.audio.select(sound.id),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: _theme.dark, width: 3)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(selected ? 3 : 0),
                        child: spinning
                            ? RotationTransition(turns: _spin, child: disc)
                            : disc,
                      ),
                    ),
                    Center(
                      child: Icon(
                        sound.icon,
                        size: 24,
                        color: Color.lerp(label, Colors.black, 0.55),
                      ),
                    ),
                    if (selected)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Icon(Icons.check_circle, size: 22, color: _theme.dark),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sound.name(widget.isVietnamese),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.2,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ListenableBuilder(
          listenable: widget.audio,
          builder: (context, _) {
            final selectedId = widget.audio.selectedId;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translate('Chọn âm thanh'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  translate('Chạm vào đĩa để nghe thử. Nhạc phát khi bạn bắt đầu tập trung.'),
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.82,
                    children: [
                      for (final sound in kFocusSounds)
                        _tile(sound, sound.id == selectedId),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  translate('Đĩa mới sẽ có ở Cửa hàng âm thanh.'),
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _theme.dark,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      elevation: 0,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(translate('Xong')),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Đĩa than thu nhỏ: mặt đĩa đen có rãnh, nhãn màu ở giữa kèm cung trang trí
/// (để thấy đĩa quay). Biểu tượng được đặt đứng yên phía trên bằng widget.
class _DiscPainter extends CustomPainter {
  final Color label;

  const _DiscPainter({required this.label});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF2E2E2E), Color(0xFF0E0E0E)],
          stops: [0.3, 1.0],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    var i = 0;
    for (double k = 0.5; k < 0.97; k += 0.06) {
      groove.color = Colors.white.withValues(alpha: i.isEven ? 0.12 : 0.05);
      canvas.drawCircle(c, r * k, groove);
      i++;
    }

    final lr = r * 0.46;
    canvas.drawCircle(c, lr, Paint()..color = label);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: lr * 0.80),
      0.3,
      1.6,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lr * 0.14
        ..strokeCap = StrokeCap.round
        ..color = Color.lerp(label, Colors.black, 0.35)!.withValues(alpha: 0.7),
    );
    canvas.drawCircle(
      c,
      lr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Color.lerp(label, Colors.black, 0.4)!.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(covariant _DiscPainter oldDelegate) =>
      oldDelegate.label != label;
}