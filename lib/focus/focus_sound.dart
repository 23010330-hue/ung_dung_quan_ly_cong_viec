import 'package:audioplayers/audioplayers.dart' show AssetSource, Source;

/// Một đĩa nhạc: nhạc nền để nghe khi tập trung.
/// File nhạc nằm trong assets/sounds, ảnh bìa trong assets/covers.
class FocusSound {
  final String id;

  
  final String name;

  final String? asset;

  /// Ảnh bìa vuông. null = đĩa trơn (không phát nhạc).
  final String? cover;

  const FocusSound({
    required this.id,
    required this.name,
    required this.asset,
    required this.cover,
  });

  bool get hasCover => cover != null;

  /// Đường dẫn dạng AssetSource của audioplayers (bỏ tiền tố "assets/").
  String? get sourcePath => asset?.replaceFirst('assets/', '');

  /// Nguồn phát nhạc; null = không phát gì.
  Source? get audioSource {
    final path = sourcePath;
    return path == null ? null : AssetSource(path);
  }
}

const FocusSound kNoSound = FocusSound(
  id: 'none',
  name: 'Không phát nhạc',
  asset: null,
  cover: null,
);

const String kDefaultSoundId = 'lofi';

const List<FocusSound> kFocusSounds = [
  FocusSound(
    id: 'lofi',
    name: 'Lofi đĩa than',
    asset: 'assets/sounds/lofi.wav',
    cover: 'assets/covers/lofi.jpg',
  ),
  FocusSound(
    id: 'Breath',
    name: 'Điều chỉnh hơi thở',
    asset: 'assets/sounds/breath.mp3',
    cover: 'assets/covers/breath.jpg',
  ),
  FocusSound(
    id: 'Light',
    name: 'Ánh năng chiều tà',
    asset: 'assets/sounds/light.mp3',
    cover: 'assets/covers/light.jpg',
  ),
];

/// Tìm đĩa theo id; "không phát nhạc" trả về [kNoSound]; không có thì null.
FocusSound? findSound(String? id) {
  if (id == kNoSound.id) return kNoSound;
  for (final s in kFocusSounds) {
    if (s.id == id) return s;
  }
  return null;
}


FocusSound soundById(String? id) => findSound(id) ?? kFocusSounds.first;