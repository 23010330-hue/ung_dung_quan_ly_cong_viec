import 'package:flutter/material.dart';
import 'package:todoapp/coins/coin_service.dart';
import 'package:todoapp/focus/focus_audio.dart';
import 'package:todoapp/focus/focus_sound.dart';
import 'package:todoapp/shop/sound_inventory.dart';
import 'package:todoapp/shop/sound_preview.dart';
import 'package:todoapp/theme/app_colors.dart';
import 'package:todoapp/until/coin_chip.dart';
import 'package:todoapp/until/marquee_text.dart';
import 'package:todoapp/until/sound_disc.dart';

/// Bảng chi tiết một đĩa trong cửa hàng: đĩa quay khi nghe thử, giá, nút nghe thử và nút mua.
Future<void> showSoundDetail({
  required BuildContext context,
  required FocusSound sound,
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
    builder: (_) => _SoundDetailSheet(
      sound: sound,
      colorTheme: colorTheme,
      translate: translate,
    ),
  );
}

class _SoundDetailSheet extends StatefulWidget {
  final FocusSound sound;
  final AppColorTheme colorTheme;
  final String Function(String) translate;

  const _SoundDetailSheet({
    required this.sound,
    required this.colorTheme,
    required this.translate,
  });

  @override
  State<_SoundDetailSheet> createState() => _SoundDetailSheetState();
}

class _SoundDetailSheetState extends State<_SoundDetailSheet>
    with SingleTickerProviderStateMixin {
  static const _textColor = Color(0xFF2D2A26);

  final SoundPreviewer _previewer = SoundPreviewer();
  late final AnimationController _spin;
  bool _buying = false;
  BuyResult? _result;

  FocusSound get _sound => widget.sound;
  AppColorTheme get _theme => widget.colorTheme;
  String Function(String) get translate => widget.translate;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _previewer.addListener(_syncSpin);
  }

  @override
  void dispose() {
    _previewer.removeListener(_syncSpin);
    _previewer.dispose(); // đóng bảng là hết tiếng nghe thử
    _spin.dispose();
    super.dispose();
  }

  /// Đĩa chỉ quay khi đang nghe thử.
  void _syncSpin() {
    if (_previewer.isPlaying(_sound.id)) {
      if (!_spin.isAnimating) _spin.repeat();
    } else {
      _spin.stop();
    }
  }

  Future<void> _buy() async {
    setState(() => _buying = true);
    final result = await SoundInventory.instance.buy(_sound);
    if (!mounted) return;
    setState(() {
      _buying = false;
      _result = result;
    });
  }

  ButtonStyle _filled() => ElevatedButton.styleFrom(
        backgroundColor: _theme.dark,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );

  ButtonStyle _outlined() => OutlinedButton.styleFrom(
        foregroundColor: _theme.dark,
        backgroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(color: _theme.dark, width: 1.5),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ListenableBuilder(
          listenable: Listenable.merge([
            _previewer,
            SoundInventory.instance,
            CoinService.instance,
            FocusAudio.sessionPlaying,
          ]),
          builder: (context, _) {
            final owned = SoundInventory.instance.isOwned(_sound.id);
            final balance = CoinService.instance.balance;
            final previewing = _previewer.isPlaying(_sound.id);
            final blocked = FocusAudio.sessionPlaying.value;

            final String buyLabel;
            VoidCallback? onBuy;
            if (owned) {
              buyLabel = translate('Đã sở hữu');
            } else if (balance < _sound.price) {
              buyLabel = '${translate('Cần thêm')} ${_sound.price - balance} coin';
            } else {
              buyLabel = '${translate('Mua')} · ${_sound.price} coin';
              if (!_buying) onBuy = _buy;
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SoundDisc(sound: _sound, spin: _spin),
                ),
                const SizedBox(height: 18),
                MarqueeText(
                  text: translate(_sound.name),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 8),
                if (owned)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 20, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 6),
                      Text(
                        translate('Đã có trong Kho'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.monetization_on, size: 22, color: kCoinGold),
                      const SizedBox(width: 6),
                      Text(
                        '${_sound.price} coin',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                    ],
                  ),
                if (blocked)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      translate('Đang tập trung nên chưa nghe thử được.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                if (_result == BuyResult.notEnoughCoins)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      translate('Chưa đủ coin'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFC62828),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: blocked ? null : () => _previewer.toggle(_sound),
                        style: _outlined(),
                        icon: Icon(previewing ? Icons.stop_rounded : Icons.play_arrow_rounded),
                        label: Text(translate(previewing ? 'Dừng' : 'Nghe thử')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onBuy,
                        style: _filled(),
                        child: Text(buyLabel, textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}