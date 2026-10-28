import 'package:flutter/material.dart';

/// Một âm thanh có thể phát trong lúc tập trung.
///
/// Về sau cửa hàng dùng chung danh mục này: [price] = 0 là miễn phí,
/// lớn hơn 0 là phải mua bằng coin.
class FocusSound {
  final String id;
  final String nameVi;
  final String nameEn;

  /// Đường dẫn file trong thư mục assets/ (null = không phát gì).
  final String? asset;
  final IconData icon;

  /// Màu nhãn đĩa than khi chọn âm thanh này.
  final Color color;
  final int price;

  const FocusSound({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.asset,
    required this.icon,
    required this.color,
    this.price = 0,
  });

  String name(bool vietnamese) => vietnamese ? nameVi : nameEn;

  /// Đường dẫn dạng AssetSource của audioplayers (bỏ tiền tố "assets/").
  String? get sourcePath => asset?.replaceFirst('assets/', '');
}

const String kDefaultSoundId = 'lofi';

const List<FocusSound> kFocusSounds = [
  FocusSound(
    id: 'lofi',
    nameVi: 'Lofi đĩa than',
    nameEn: 'Lofi vinyl',
    asset: 'assets/sounds/lofi.wav',
    icon: Icons.album,
    color: Color(0xFFB39DDB),
  ),
  FocusSound(
    id: 'rain',
    nameVi: 'Mưa rơi',
    nameEn: 'Rain',
    asset: 'assets/sounds/rain.wav',
    icon: Icons.water_drop,
    color: Color(0xFF8EC5E8),
  ),
  FocusSound(
    id: 'ocean',
    nameVi: 'Sóng biển',
    nameEn: 'Ocean waves',
    asset: 'assets/sounds/ocean.wav',
    icon: Icons.waves,
    color: Color(0xFF6FC2B8),
  ),
  FocusSound(
    id: 'fire',
    nameVi: 'Lửa trại',
    nameEn: 'Campfire',
    asset: 'assets/sounds/fire.wav',
    icon: Icons.local_fire_department,
    color: Color(0xFFF2A65A),
  ),
  FocusSound(
    id: 'brown',
    nameVi: 'Tiếng ồn nâu',
    nameEn: 'Brown noise',
    asset: 'assets/sounds/brown.wav',
    icon: Icons.graphic_eq,
    color: Color(0xFFC79D7A),
  ),
  FocusSound(
    id: 'none',
    nameVi: 'Không phát nhạc',
    nameEn: 'No sound',
    asset: null,
    icon: Icons.volume_off,
    color: Color(0xFFB8B8B8),
  ),
];

FocusSound soundById(String? id) {
  for (final s in kFocusSounds) {
    if (s.id == id) return s;
  }
  return kFocusSounds.first;
}