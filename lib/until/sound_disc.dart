import 'package:flutter/material.dart';
import 'package:todoapp/focus/focus_sound.dart';

/// Đĩa than của một âm thanh: ảnh bìa lấp đầy mặt đĩa, rãnh mờ và TÂM CHUNG cho mọi đĩa.
/// Không có chữ hay biểu tượng riêng trên đĩa, nên thêm âm thanh mới chỉ cần thêm ảnh.
///
/// Widget tự co giãn theo khung chứa (luôn hình tròn); bọc trong SizedBox để đặt cỡ.
/// Truyền [spin] (turns 0..1, lặp) nếu muốn đĩa quay.
class SoundDisc extends StatelessWidget {
  final FocusSound sound;
  final Animation<double>? spin;

  const SoundDisc({super.key, required this.sound, this.spin});

  Widget _placeholder({required IconData icon, required Color color}) {
    return Container(
      color: color,
      alignment: Alignment.center,
      child: FractionallySizedBox(
        widthFactor: 0.4,
        heightFactor: 0.4,
        child: FittedBox(child: Icon(icon, color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cover = sound.cover;

    // "Không phát nhạc": đĩa trơn màu xám, không có tâm.
    if (cover == null) {
      return AspectRatio(
        aspectRatio: 1,
        child: ClipOval(
          child: _placeholder(icon: Icons.volume_off, color: const Color(0xFFB9B4AC)),
        ),
      );
    }

    final disc = Stack(
      fit: StackFit.expand,
      children: [
        ClipOval(
          child: Image.asset(
            cover,
            fit: BoxFit.cover,
            // thiếu ảnh thì hiện đĩa xám thay vì báo lỗi đỏ
            errorBuilder: (_, __, ___) =>
                _placeholder(icon: Icons.album, color: const Color(0xFF6E6A63)),
          ),
        ),
        const CustomPaint(painter: _DiscOverlayPainter()),
      ],
    );

    return AspectRatio(
      aspectRatio: 1,
      child: spin == null ? disc : RotationTransition(turns: spin!, child: disc),
    );
  }
}

/// Lớp phủ giống hệt nhau cho mọi đĩa: rãnh mờ, viền mép và tâm đĩa.
class _DiscOverlayPainter extends CustomPainter {
  const _DiscOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // rãnh đĩa: các vòng tròn rất mờ, xen kẽ sáng/tối
    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.006;
    var i = 0;
    for (double k = 0.34; k < 0.97; k += 0.045) {
      groove.color = (i.isEven ? Colors.black : Colors.white).withValues(alpha: 0.10);
      canvas.drawCircle(c, r * k, groove);
      i++;
    }

    // viền mép đĩa
    canvas.drawCircle(
      c,
      r * 0.985,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.03
        ..color = Colors.black.withValues(alpha: 0.35),
    );

    // tâm chung: nhãn kem nhỏ + lỗ trục
    canvas.drawCircle(c, r * 0.20, Paint()..color = const Color(0xFFEFE7D2));
    canvas.drawCircle(
      c,
      r * 0.20,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.015
        ..color = Colors.black.withValues(alpha: 0.45),
    );
    canvas.drawCircle(c, r * 0.055, Paint()..color = const Color(0xFF1B1B1B));
  }

  @override
  bool shouldRepaint(covariant _DiscOverlayPainter oldDelegate) => false;
}