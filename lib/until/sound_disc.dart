import 'package:flutter/material.dart';
import 'package:todoapp/focus/focus_sound.dart';


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
    final coverAsset = sound.cover;

    if (coverAsset == null) {
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
            coverAsset,
            fit: BoxFit.cover,
            // thiếu ảnh thì hiện đĩa xám thay vì báo lỗi đỏ
            errorBuilder: (_, _, _) => _placeholder(
              icon: Icons.album,
              color: const Color(0xFF6E6A63),
            ),
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

class _DiscOverlayPainter extends CustomPainter {
  const _DiscOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.006;
    var i = 0;
    for (double k = 0.34; k < 0.97; k += 0.045) {
      groove.color = (i.isEven ? Colors.black : Colors.white).withValues(alpha: 0.10);
      canvas.drawCircle(c, r * k, groove);
      i++;
    }

    canvas.drawCircle(
      c,
      r * 0.985,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.03
        ..color = Colors.black.withValues(alpha: 0.35),
    );

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