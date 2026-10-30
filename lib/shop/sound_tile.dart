import 'package:flutter/material.dart';
import 'package:todoapp/focus/focus_sound.dart';
import 'package:todoapp/theme/app_colors.dart';
import 'package:todoapp/until/marquee_text.dart';
import 'package:todoapp/until/sound_disc.dart';

/// Ô đĩa dùng chung cho Cửa hàng và Kho: đĩa ảnh bìa, tên chạy như biển báo, một dòng chân ô.
class SoundTile extends StatelessWidget {
  final FocusSound sound;
  final String Function(String) translate;
  final AppColorTheme colorTheme;

  /// Dòng dưới tên: giá, "Đã sở hữu", "Đang dùng"...
  final Widget footer;

  /// Viền nhấn quanh ô (ví dụ đĩa đang dùng).
  final bool highlighted;

  /// Huy hiệu nhỏ ở góc trên phải của đĩa.
  final Widget? badge;

  final VoidCallback onTap;

  const SoundTile({
    super.key,
    required this.sound,
    required this.translate,
    required this.colorTheme,
    required this.footer,
    required this.onTap,
    this.highlighted = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: highlighted ? colorTheme.dark : Colors.transparent,
              width: 2,
            ),
          ),
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.22),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: SoundDisc(sound: sound),
                        ),
                        if (badge != null) Positioned(right: 0, top: 0, child: badge!),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              MarqueeText(
                text: translate(sound.name),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2A26),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(height: 24, child: Center(child: footer)),
            ],
          ),
        ),
      ),
    );
  }
}