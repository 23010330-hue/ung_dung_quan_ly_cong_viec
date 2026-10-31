import 'package:flutter/material.dart';

/// Chữ một dòng: vừa khung thì đứng yên, dài hơn khung thì chạy ngang liên tục
/// như bảng biển báo (hai bản chữ nối nhau nên không bị giật khi quay lại đầu).
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  /// Căn lề khi chữ vừa khung.
  final TextAlign textAlign;

  /// Tốc độ chạy (điểm ảnh mỗi giây) và khoảng trống giữa hai lần lặp.
  final double speed;
  final double gap;

  const MarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.center,
    this.speed = 34,
    this.gap = 32,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  double _cycleWidth = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Chạy một vòng = đi hết một bản chữ cộng khoảng trống.
  void _run(double cycleWidth) {
    if (cycleWidth == _cycleWidth && _controller.isAnimating) return;
    _cycleWidth = cycleWidth;
    _controller.duration = Duration(
      milliseconds: (cycleWidth / widget.speed * 1000).round(),
    );
    _controller.repeat();
  }

  void _halt() {
    if (_controller.isAnimating) _controller.stop();
    _cycleWidth = 0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final textWidth = painter.width;
        final textHeight = painter.height;
        painter.dispose();

        if (textWidth <= constraints.maxWidth) {
          _halt();
          return Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
            softWrap: false,
            textAlign: widget.textAlign,
          );
        }

        final cycle = textWidth + widget.gap;
        _run(cycle);
        Widget line() => Text(
              widget.text,
              style: widget.style,
              maxLines: 1,
              softWrap: false,
            );
        return ClipRect(
          child: SizedBox(
            height: textHeight,
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: 0,
              maxWidth: double.infinity,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Transform.translate(
                  offset: Offset(-_controller.value * cycle, 0),
                  child: child,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [line(), SizedBox(width: widget.gap), line()],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}