/// Một đĩa nhạc: nhạc nền để nghe khi tập trung.
///
/// Muốn thêm đĩa mới chỉ cần 3 việc:
///   1. bỏ file nhạc vào assets/sounds/ (nên là .wav vòng lặp liền mạch),
///   2. bỏ ảnh bìa vuông vào assets/covers/ (đĩa tự cắt tròn và đặt tâm chung),
///   3. thêm một dòng vào [kFocusSounds] bên dưới + bản dịch tên trong app_strings.dart.
class FocusSound {
  final String id;

  /// Tên tiếng Việt; hiển thị qua translate() nên cần bản dịch trong app_strings.dart.
  final String name;

  /// File nhạc trong assets/ (null = không phát gì).
  final String? asset;

  /// Ảnh bìa vuông trong assets/ (null = đĩa trơn, chỉ dùng cho "không phát nhạc").
  final String? cover;

  /// Giá bằng coin. 0 = tặng sẵn cho mọi tài khoản.
  final int price;

  const FocusSound({
    required this.id,
    required this.name,
    required this.asset,
    required this.cover,
    this.price = 0,
  });

  /// Đường dẫn dạng AssetSource của audioplayers (bỏ tiền tố "assets/").
  String? get sourcePath => asset?.replaceFirst('assets/', '');
}

/// Lựa chọn "tắt nhạc". Không bán, không nằm trong cửa hàng.
const FocusSound kNoSound = FocusSound(
  id: 'none',
  name: 'Không phát nhạc',
  asset: null,
  cover: null,
);

/// Đĩa tặng sẵn, cũng là đĩa mặc định.
const String kDefaultSoundId = 'lofi';

/// Các đĩa có trong app (cửa hàng bán đúng danh sách này).
const List<FocusSound> kFocusSounds = [
  FocusSound(
    id: 'lofi',
    name: 'Lofi đĩa than',
    asset: 'assets/sounds/lofi.wav',
    cover: 'assets/covers/lofi.jpg',
  ),
  FocusSound(
    id: 'rain',
    name: 'Mưa rơi',
    asset: 'assets/sounds/rain.wav',
    cover: 'assets/covers/rain.jpg',
    price: 20,
  ),
  FocusSound(
    id: 'ocean',
    name: 'Sóng biển',
    asset: 'assets/sounds/ocean.wav',
    cover: 'assets/covers/ocean.jpg',
    price: 30,
  ),
  FocusSound(
    id: 'brown',
    name: 'Tiếng ồn nâu',
    asset: 'assets/sounds/brown.wav',
    cover: 'assets/covers/brown.jpg',
    price: 30,
  ),
  FocusSound(
    id: 'fire',
    name: 'Lửa trại',
    asset: 'assets/sounds/fire.wav',
    cover: 'assets/covers/fire.jpg',
    price: 40,
  ),
];

/// Tìm đĩa theo id; null nếu không có (kể cả "không phát nhạc" thì trả về [kNoSound]).
FocusSound? findSound(String? id) {
  if (id == kNoSound.id) return kNoSound;
  for (final s in kFocusSounds) {
    if (s.id == id) return s;
  }
  return null;
}

/// Như [findSound] nhưng không có thì dùng đĩa mặc định.
FocusSound soundById(String? id) => findSound(id) ?? kFocusSounds.first;