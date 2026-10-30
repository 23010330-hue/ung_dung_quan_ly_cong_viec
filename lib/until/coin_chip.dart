import 'package:flutter/material.dart';
import 'package:todoapp/coins/coin_rules.dart';
import 'package:todoapp/coins/coin_service.dart';
import 'package:todoapp/focus/focus_sound.dart';
import 'package:todoapp/theme/app_colors.dart';

const Color kCoinGold = Color(0xFFE0A526);

/// Viên thuốc nhỏ hiện số coin hiện có; bấm vào để xem lịch sử và cách kiếm coin.
class CoinChip extends StatelessWidget {
  final AppColorTheme colorTheme;
  final String Function(String) translate;

  const CoinChip({super.key, required this.colorTheme, required this.translate});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CoinService.instance,
      builder: (context, _) {
        return Material(
          color: Colors.white,
          shape: StadiumBorder(side: BorderSide(color: colorTheme.dark, width: 1.2)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => showCoinSheet(
              context: context,
              colorTheme: colorTheme,
              translate: translate,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, size: 20, color: kCoinGold),
                  const SizedBox(width: 4),
                  Text(
                    '${CoinService.instance.balance}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2A26),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Bảng trượt từ dưới lên: số dư, tiến độ trong ngày, cách kiếm coin và lịch sử.
Future<void> showCoinSheet({
  required BuildContext context,
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
    builder: (_) => _CoinSheet(colorTheme: colorTheme, translate: translate),
  );
}

class _CoinSheet extends StatelessWidget {
  static const _textColor = Color(0xFF2D2A26);

  final AppColorTheme colorTheme;
  final String Function(String) translate;

  const _CoinSheet({required this.colorTheme, required this.translate});

  String _two(int n) => n.toString().padLeft(2, '0');

  String _when(DateTime t) =>
      '${_two(t.day)}/${_two(t.month)} ${_two(t.hour)}:${_two(t.minute)}';

  String _labelOf(CoinEntry e) {
    switch (e.kind) {
      case CoinKind.focus:
        return '${translate('Phiên tập trung')} ${e.detail} ${translate('phút')}';
      case CoinKind.task:
        return '${translate('Việc đúng hạn')}: ${e.detail}';
      case CoinKind.spend:
        // detail là id của đĩa đã mua
        final sound = findSound(e.detail);
        return '${translate('Mua đĩa')}: ${translate(sound?.name ?? e.detail)}';
    }
  }

  IconData _iconOf(CoinKind kind) {
    switch (kind) {
      case CoinKind.focus:
        return Icons.album;
      case CoinKind.task:
        return Icons.task_alt;
      case CoinKind.spend:
        return Icons.shopping_bag_outlined;
    }
  }

  Widget _ruleLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(text, style: TextStyle(fontSize: 12.5, color: Colors.grey[800])),
    );
  }

  Widget _entryRow(CoinEntry e) {
    final gain = e.amount >= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(_iconOf(e.kind), size: 22, color: colorTheme.dark),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _labelOf(e),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                  ),
                  Text(
                    _when(e.time),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(
              gain ? '+${e.amount}' : '${e.amount}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: gain ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = CoinService.instance;
    return SafeArea(
      child: ListenableBuilder(
        listenable: service,
        builder: (context, _) {
          final entries = service.entries.take(50).toList();
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.monetization_on, size: 34, color: kCoinGold),
                    const SizedBox(width: 10),
                    Text(
                      '${service.balance}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      translate('Coin của tôi'),
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${translate('Hôm nay')}: ${service.focusEarnedToday}/${CoinRules.focusDailyCap} coin '
                        '(${translate('Tập trung')}) · ${service.tasksRewardedToday}/${CoinRules.taskDailyLimit} ${translate('việc')}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        translate('Cách kiếm coin'),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      _ruleLine(
                        '${translate('Tập trung')}: ${CoinRules.focusCoinsPerBlock} coin / '
                        '${CoinRules.focusBlockMinutes} ${translate('phút')}',
                      ),
                      _ruleLine(
                        '${translate('Việc đúng hạn')}: ${CoinRules.taskCoins} coin / ${translate('việc')}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  translate('Lịch sử coin'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 8),
                if (entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        translate('Chưa có giao dịch coin nào'),
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView(
                        shrinkWrap: true,
                        children: [for (final e in entries) _entryRow(e)],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}