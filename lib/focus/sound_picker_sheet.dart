import 'package:flutter/material.dart';
import 'package:todoapp/focus/focus_audio.dart';
import 'package:todoapp/focus/focus_sound.dart';
import 'package:todoapp/theme/app_colors.dart';
import 'package:todoapp/until/marquee_text.dart';
import 'package:todoapp/until/sound_disc.dart';

/// Bảng chọn đĩa nhạc cho phiên tập trung, trượt từ dưới lên.
/// Bấm vào đĩa là chọn ngay (lúc chưa tập trung sẽ nghe thử vài giây).
Future<void> showSoundPicker({
  required BuildContext context,
  required FocusAudio audio,
  required AppColorTheme colorTheme,
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
      translate: translate,
    ),
  ).whenComplete(audio.stopPreview);
}

class _SoundPickerSheet extends StatefulWidget {
  final FocusAudio audio;
  final AppColorTheme colorTheme;
  final String Function(String) translate;

  const _SoundPickerSheet({
    required this.audio,
    required this.colorTheme,
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
    final spinning = selected && sound.hasCover;
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
                        child: SoundDisc(sound: sound, spin: spinning ? _spin : null),
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
          MarqueeText(
            text: translate(sound.name),
            style: TextStyle(
              fontSize: 13,
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
            final sounds = [...kFocusSounds, kNoSound];
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
                      for (final sound in sounds) _tile(sound, sound.id == selectedId),
                    ],
                  ),
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