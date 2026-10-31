import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:todoapp/focus/focus_session.dart';

/// Vẽ máy đĩa than kiểu cổ bằng code, tỉ lệ khung hình rộng : cao = 1 : 1.12.
///
/// - [arm]: 0 = cần kim ở vị trí nghỉ, 1 = kim đã hạ xuống đĩa.
/// - [discAngle]: góc quay hiện tại của đĩa (radian).
/// - Khi phiên chạy, kim di chuyển dần từ rãnh ngoài vào rãnh trong theo tiến độ.
class RecordPlayerPainter extends CustomPainter {
  final FocusSession session;
  final Animation<double> arm;
  final ValueListenable<double> discAngle;

  /// Màu nhãn đĩa than đang đặt trên máy (đổi theo đĩa nhạc người dùng chọn).
  final Color labelColor;

  RecordPlayerPainter({
    required this.session,
    required this.arm,
    required this.discAngle,
    required this.labelColor,
  }) : super(repaint: Listenable.merge([session, arm, discAngle]));

  Color get _labelDark => Color.lerp(labelColor, Colors.black, 0.45)!;

  static const Color _ledOn = Color(0xFFFF5A36);
  static const Color _ledOff = Color(0xFF3A1712);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawBody(canvas, w, h);
    _drawLedPanel(canvas, w);

    final center = Offset(w * 0.47, w * 0.60);
    final r = w * 0.30;
    _drawPlatter(canvas, center, r);
    _drawVinyl(canvas, center, r);
    _drawTonearm(canvas, w, center, r);
    _drawKnobs(canvas, w, h);
  }

  // ---------------------------------------------------------------- thân gỗ
  void _drawBody(Canvas canvas, double w, double h) {
    final rect = Rect.fromLTWH(0, 0, w, h);
    final body = RRect.fromRectAndRadius(rect, Radius.circular(w * 0.05));

    canvas.drawShadow(Path()..addRRect(body), Colors.black, 10, false);
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF93502C), Color(0xFF6E3722), Color(0xFF4F2616)],
        ).createShader(rect),
    );

    // vân gỗ
    canvas.save();
    canvas.clipRRect(body);
    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.003;
    for (int i = 0; i < 16; i++) {
      final y = h * (i + 0.5) / 16 + sin(i * 12.9898) * w * 0.012;
      grain.color = (i.isEven ? Colors.black : Colors.white).withValues(
        alpha: i.isEven ? 0.10 : 0.05,
      );
      canvas.drawLine(Offset(0, y), Offset(w, y + sin(i * 3.1) * w * 0.01), grain);
    }
    canvas.restore();

    // viền vát
    canvas.drawRRect(
      body.deflate(w * 0.006),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.008
        ..color = Colors.white.withValues(alpha: 0.14),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.004
        ..color = Colors.black.withValues(alpha: 0.5),
    );
  }

  // -------------------------------------------------------- đồng hồ LED trên
  void _drawLedPanel(Canvas canvas, double w) {
    final panel = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.20, w * 0.05, w * 0.60, w * 0.17),
      Radius.circular(w * 0.025),
    );
    // viền đồng
    canvas.drawRRect(panel.inflate(w * 0.008), Paint()..color = const Color(0xFFC9A24A));
    canvas.drawRRect(
      panel,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF120A08), Color(0xFF2A1812)],
        ).createShader(panel.outerRect),
    );

    // chữ số
    final remainingSeconds = (session.remaining.inMilliseconds / 1000).ceil();
    final hours = remainingSeconds ~/ 3600;
    final minutes = (remainingSeconds % 3600) ~/ 60;
    final seconds = remainingSeconds % 60;
    final text =
        '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final colonOn = session.phase == FocusPhase.running
        ? session.elapsed.inSeconds.isEven
        : true;
    final digitsArea = Rect.fromLTWH(
      panel.left + w * 0.04,
      panel.top + w * 0.02,
      panel.width - w * 0.08,
      panel.height * 0.62,
    );
    _drawLedText(canvas, digitsArea, text, colonOn);

    // thanh tiến độ
    final bar = Rect.fromLTWH(
      panel.left + w * 0.05,
      panel.bottom - w * 0.04,
      panel.width - w * 0.10,
      w * 0.012,
    );
    final barRadius = Radius.circular(w * 0.006);
    canvas.drawRRect(RRect.fromRectAndRadius(bar, barRadius), Paint()..color = _ledOff);
    if (session.progress > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bar.left, bar.top, bar.width * session.progress, bar.height),
          barRadius,
        ),
        Paint()..color = _ledOn,
      );
    }

    // đèn báo: phải = đang chạy (đỏ), trái = tạm dừng (vàng)
    _drawLamp(
      canvas,
      Offset(w * 0.875, w * 0.135),
      w,
      session.phase == FocusPhase.running,
      _ledOn,
      const Color(0xFF4A1F18),
    );
    _drawLamp(
      canvas,
      Offset(w * 0.125, w * 0.135),
      w,
      session.phase == FocusPhase.paused,
      const Color(0xFFFFC04D),
      const Color(0xFF4A3A18),
    );
  }

  void _drawLamp(
    Canvas canvas,
    Offset at,
    double w,
    bool on,
    Color onColor,
    Color offColor,
  ) {
    if (on) {
      canvas.drawCircle(
        at,
        w * 0.032,
        Paint()
          ..color = onColor.withValues(alpha: 0.55)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.012),
      );
    }
    canvas.drawCircle(at, w * 0.016, Paint()..color = const Color(0xFFC9A24A));
    canvas.drawCircle(at, w * 0.012, Paint()..color = on ? onColor : offColor);
  }

  static const List<String> _digitSegments = [
    'abcdef', // 0
    'bc', // 1
    'abdeg', // 2
    'abcdg', // 3
    'bcfg', // 4
    'acdfg', // 5
    'acdefg', // 6
    'abc', // 7
    'abcdefg', // 8
    'abcdfg', // 9
  ];

  void _drawLedText(Canvas canvas, Rect area, String text, bool colonOn) {
    final dh = area.height;
    final dw = dh * 0.52;
    final gap = dw * 0.22;
    final colonW = dw * 0.34;

    double total = 0;
    for (final ch in text.split('')) {
      total += (ch == ':' ? colonW : dw) + gap;
    }
    total -= gap;
    final scale = total > area.width ? area.width / total : 1.0;

    final sdw = dw * scale;
    final sdh = dh * scale;
    final sgap = gap * scale;
    final scolon = colonW * scale;
    final t = sdw * 0.20;

    var x = area.center.dx - total * scale / 2;
    final y = area.center.dy - sdh / 2;

    final onPath = Path();
    final offPath = Path();

    for (final ch in text.split('')) {
      if (ch == ':') {
        final cx = x + scolon / 2;
        final dotR = t * 0.55;
        for (final dy in [0.33, 0.67]) {
          (colonOn ? onPath : offPath).addOval(
            Rect.fromCircle(center: Offset(cx, y + sdh * dy), radius: dotR),
          );
        }
        x += scolon + sgap;
      } else {
        final lit = _digitSegments[int.parse(ch)];
        final segments = _segmentPaths(x, y, sdw, sdh, t);
        for (final key in 'abcdefg'.split('')) {
          (lit.contains(key) ? onPath : offPath).addPath(segments[key]!, Offset.zero);
        }
        x += sdw + sgap;
      }
    }

    canvas.drawPath(offPath, Paint()..color = _ledOff);
    canvas.drawPath(
      onPath,
      Paint()
        ..color = _ledOn.withValues(alpha: 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, t * 0.9),
    );
    canvas.drawPath(onPath, Paint()..color = _ledOn);
  }

  Path _hSeg(double x1, double x2, double yc, double t) {
    return Path()
      ..moveTo(x1, yc)
      ..lineTo(x1 + t / 2, yc - t / 2)
      ..lineTo(x2 - t / 2, yc - t / 2)
      ..lineTo(x2, yc)
      ..lineTo(x2 - t / 2, yc + t / 2)
      ..lineTo(x1 + t / 2, yc + t / 2)
      ..close();
  }

  Path _vSeg(double xc, double y1, double y2, double t) {
    return Path()
      ..moveTo(xc, y1)
      ..lineTo(xc + t / 2, y1 + t / 2)
      ..lineTo(xc + t / 2, y2 - t / 2)
      ..lineTo(xc, y2)
      ..lineTo(xc - t / 2, y2 - t / 2)
      ..lineTo(xc - t / 2, y1 + t / 2)
      ..close();
  }

  Map<String, Path> _segmentPaths(double x, double y, double w, double h, double t) {
    final g = t * 0.12;
    final left = x + t / 2;
    final right = x + w - t / 2;
    final mid = y + h / 2;
    return {
      'a': _hSeg(x + t / 2 + g, x + w - t / 2 - g, y + t / 2, t),
      'g': _hSeg(x + t / 2 + g, x + w - t / 2 - g, mid, t),
      'd': _hSeg(x + t / 2 + g, x + w - t / 2 - g, y + h - t / 2, t),
      'f': _vSeg(left, y + t / 2 + g, mid - g, t),
      'b': _vSeg(right, y + t / 2 + g, mid - g, t),
      'e': _vSeg(left, mid + g, y + h - t / 2 - g, t),
      'c': _vSeg(right, mid + g, y + h - t / 2 - g, t),
    };
  }

  // ------------------------------------------------------------ mâm và đĩa
  void _drawPlatter(Canvas canvas, Offset c, double r) {
    // lòng máy hõm xuống
    canvas.drawCircle(c, r * 1.16, Paint()..color = const Color(0xFF1E100A));
    canvas.drawCircle(
      c,
      r * 1.16,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.03
        ..color = Colors.black.withValues(alpha: 0.6),
    );
    // viền kim loại của mâm
    canvas.drawCircle(
      c,
      r * 1.07,
      Paint()
        ..shader = const SweepGradient(
          colors: [
            Color(0xFFB9B4AA),
            Color(0xFF6E6A63),
            Color(0xFFD8D3C8),
            Color(0xFF6E6A63),
            Color(0xFFB9B4AA),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 1.07)),
    );
  }

  void _drawVinyl(Canvas canvas, Offset c, double r) {
    final disc = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF0E0E0E)],
          stops: [0.3, 1.0],
        ).createShader(disc),
    );

    // rãnh đĩa
    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(0.5, r * 0.004);
    int index = 0;
    for (double k = 0.36; k < 0.97; k += 0.028) {
      groove.color = Colors.white.withValues(alpha: index % 5 == 0 ? 0.13 : 0.045);
      canvas.drawCircle(c, r * k, groove);
      index++;
    }

    // vệt phản chiếu đứng yên (ánh sáng cố định, đĩa quay bên dưới)
    const clear = Color(0x00FFFFFF);
    const shine = Color(0x1AFFFFFF);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const SweepGradient(
          colors: [clear, shine, clear, clear, shine, clear, clear],
          stops: [0.0, 0.08, 0.16, 0.5, 0.58, 0.66, 1.0],
          transform: GradientRotation(-0.7),
        ).createShader(disc),
    );

    // nhãn đĩa quay
    final lr = r * 0.32;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(discAngle.value);
    canvas.drawCircle(Offset.zero, lr, Paint()..color = labelColor);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: lr * 0.70),
      0,
      pi * 0.9,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lr * 0.30
        ..strokeCap = StrokeCap.round
        ..color = _labelDark.withValues(alpha: 0.85),
    );
    for (final a in [pi * 1.15, pi * 1.4, pi * 1.65]) {
      canvas.drawCircle(
        Offset(cos(a), sin(a)) * lr * 0.70,
        lr * 0.07,
        Paint()..color = _labelDark,
      );
    }
    canvas.drawCircle(
      Offset.zero,
      lr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(0.8, lr * 0.04)
        ..color = _labelDark.withValues(alpha: 0.6),
    );
    canvas.restore();

    // trục giữa
    canvas.drawCircle(c, r * 0.035, Paint()..color = const Color(0xFFD9D4C9));
    canvas.drawCircle(
      c,
      r * 0.035,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(0.6, r * 0.01)
        ..color = Colors.black.withValues(alpha: 0.5),
    );
  }

  // --------------------------------------------------------------- cần kim
  /// Góc cần kim để mũi kim chạm đúng vòng bán kính [rr] quanh tâm đĩa.
  double _angleForRadius(Offset pivot, Offset center, double armLen, double rr) {
    final v = center - pivot;
    final d = v.distance;
    final cosPhi = ((armLen * armLen + d * d - rr * rr) / (2 * armLen * d)).clamp(-1.0, 1.0);
    return atan2(v.dy, v.dx) - acos(cosPhi);
  }

  void _drawTonearm(Canvas canvas, double w, Offset c, double r) {
    final pivot = Offset(c.dx + 1.18 * r, c.dy - 0.55 * r);
    final armLen = r * 1.0;
    final drop = Curves.easeInOutCubic.transform(arm.value.clamp(0.0, 1.0));
    final lift = 1 - drop;

    final aStart = _angleForRadius(pivot, c, armLen, r * 0.95);
    final aEnd = _angleForRadius(pivot, c, armLen, r * 0.42);
    final aRest = aStart - 0.58;

    final playAngle = aStart + (aEnd - aStart) * session.progress;
    final angle = aRest + (playAngle - aRest) * drop;

    final u = Offset(cos(angle), sin(angle));
    final tip = pivot + u * armLen; // điểm mũi kim chạm đĩa
    final shellStart = tip - u * (w * 0.06);

    // bóng đổ: cần càng nhấc cao thì bóng càng xa và nhạt
    final shadowOffset = Offset(w * (0.012 + 0.03 * lift), w * (0.016 + 0.04 * lift));
    canvas.drawLine(
      pivot + shadowOffset,
      tip + shadowOffset,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28 - 0.10 * lift)
        ..strokeWidth = w * 0.02
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * (0.006 + 0.012 * lift)),
    );

    // đối trọng phía sau trục
    canvas.drawLine(
      pivot,
      pivot - u * (w * 0.07),
      Paint()
        ..strokeWidth = w * 0.034
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF3B3B3B),
    );

    // thân cần
    canvas.drawLine(
      pivot,
      shellStart,
      Paint()
        ..strokeWidth = w * 0.016
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFCFC9BD),
    );
    final side = Offset(-u.dy, u.dx) * (w * 0.004);
    canvas.drawLine(
      pivot + side,
      shellStart + side,
      Paint()
        ..strokeWidth = w * 0.004
        ..color = Colors.black.withValues(alpha: 0.25),
    );

    // đầu kim
    canvas.drawLine(
      shellStart,
      tip,
      Paint()
        ..strokeWidth = w * 0.03
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF2A2623),
    );
    canvas.drawCircle(tip, w * 0.006, Paint()..color = const Color(0xFFE8E2D4));

    // đế trục
    canvas.drawCircle(
      pivot,
      w * 0.05,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFE9D9A6), Color(0xFF9B7B2E)],
        ).createShader(Rect.fromCircle(center: pivot, radius: w * 0.05)),
    );
    canvas.drawCircle(pivot, w * 0.022, Paint()..color = const Color(0xFF3A2E12));
  }

  // ------------------------------------------------------------ núm xoay
  void _drawKnobs(Canvas canvas, double w, double h) {
    final y = h - w * 0.075;
    // núm trái xoay theo tiến độ như một mặt số
    _drawKnob(canvas, Offset(w * 0.14, y), w * 0.04, -2.4 + session.progress * 4.8);
    _drawKnob(canvas, Offset(w * 0.86, y), w * 0.04, -1.0);
  }

  void _drawKnob(Canvas canvas, Offset c, double rad, double angle) {
    canvas.drawCircle(
      c + Offset(0, rad * 0.15),
      rad,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rad * 0.25),
    );
    canvas.drawCircle(
      c,
      rad,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFF8A8478), Color(0xFF2E2B27)],
        ).createShader(Rect.fromCircle(center: c, radius: rad)),
    );
    final notch = Offset(cos(angle), sin(angle));
    canvas.drawLine(
      c + notch * (rad * 0.35),
      c + notch * (rad * 0.85),
      Paint()
        ..strokeWidth = rad * 0.16
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFEFE7D2),
    );
  }

  @override
  bool shouldRepaint(covariant RecordPlayerPainter oldDelegate) {
    return oldDelegate.labelColor != labelColor;
  }
}