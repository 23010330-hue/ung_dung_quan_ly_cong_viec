import 'package:flutter/material.dart';
import 'package:todoapp/focus/focus_audio.dart';
import 'package:todoapp/shop/sound_inventory.dart';
import 'package:todoapp/shop/sound_tile.dart';
import 'package:todoapp/theme/app_colors.dart';
import 'package:todoapp/until/coin_chip.dart';

/// Kho của tôi: các đĩa đã có. Bấm vào đĩa để dùng làm nhạc cho phiên tập trung.
class InventoryPage extends StatelessWidget {
  final AppColorTheme colorTheme;
  final String Function(String) translate;
  final FocusAudio audio;

  const InventoryPage({
    super.key,
    required this.colorTheme,
    required this.translate,
    required this.audio,
  });

  Widget _inUsePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: colorTheme.dark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        translate('Đang dùng'),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorTheme.light,
      appBar: AppBar(
        title: Text(
          translate('Kho của tôi'),
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
        listenable: Listenable.merge([SoundInventory.instance, audio]),
        builder: (context, _) {
          final sounds = SoundInventory.instance.ownedSounds;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Text(
                  translate('Chạm vào đĩa để dùng cho phiên tập trung.'),
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
                  itemCount: sounds.length,
                  itemBuilder: (context, index) {
                    final sound = sounds[index];
                    final inUse = sound.id == audio.selectedId;
                    return SoundTile(
                      sound: sound,
                      translate: translate,
                      colorTheme: colorTheme,
                      highlighted: inUse,
                      footer: inUse ? _inUsePill() : const SizedBox.shrink(),
                      onTap: () => audio.select(sound.id),
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