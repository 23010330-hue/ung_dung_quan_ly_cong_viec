import 'package:flutter/material.dart';
import 'package:todoapp/coins/coin_service.dart';
import 'package:todoapp/focus/focus_sound.dart';
import 'package:todoapp/shop/sound_detail_sheet.dart';
import 'package:todoapp/shop/sound_inventory.dart';
import 'package:todoapp/shop/sound_tile.dart';
import 'package:todoapp/theme/app_colors.dart';
import 'package:todoapp/until/coin_chip.dart';

/// Cửa hàng âm thanh: lưới đĩa than, bấm vào đĩa để nghe thử và mua bằng coin.
class ShopPage extends StatelessWidget {
  static const _textColor = Color(0xFF2D2A26);

  final AppColorTheme colorTheme;
  final String Function(String) translate;

  const ShopPage({super.key, required this.colorTheme, required this.translate});

  Widget _footer(FocusSound sound, bool owned) {
    if (owned) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF2E7D32)),
          const SizedBox(width: 4),
          Text(
            translate('Đã sở hữu'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.monetization_on, size: 18, color: kCoinGold),
        const SizedBox(width: 4),
        Text(
          '${sound.price}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorTheme.light,
      appBar: AppBar(
        title: Text(
          translate('Cửa hàng âm thanh'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorTheme.primary,
        foregroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: CoinChip(colorTheme: colorTheme, translate: translate)),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([SoundInventory.instance, CoinService.instance]),
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Text(
                  translate('Chạm vào đĩa để nghe thử và mua bằng coin.'),
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: kFocusSounds.length,
                  itemBuilder: (context, index) {
                    final sound = kFocusSounds[index];
                    final owned = SoundInventory.instance.isOwned(sound.id);
                    return SoundTile(
                      sound: sound,
                      translate: translate,
                      colorTheme: colorTheme,
                      footer: _footer(sound, owned),
                      badge: owned
                          ? Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                size: 22,
                                color: Color(0xFF2E7D32),
                              ),
                            )
                          : null,
                      onTap: () => showSoundDetail(
                        context: context,
                        sound: sound,
                        colorTheme: colorTheme,
                        translate: translate,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}