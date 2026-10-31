import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todoapp/coins/coin_service.dart';
import 'package:todoapp/focus/focus_sound.dart';
import 'package:todoapp/services/auth_service.dart';

enum BuyResult { bought, alreadyOwned, notEnoughCoins }

/// Kho đĩa của tài khoản đang đăng nhập: đĩa tặng sẵn (giá 0) luôn có, đĩa khác phải mua.
///
/// Giống AuthService và CoinService: giao diện dùng [SoundInventory.instance]; hiện lưu trong
/// Hive trên máy. Khi nối Firebase, việc mua nên chạy trên server (trừ coin và thêm đĩa trong
/// một giao dịch) rồi gán bản mới vào [instance].
abstract class SoundInventory extends ChangeNotifier {
  static SoundInventory instance = LocalSoundInventory();

  bool isOwned(String id);

  /// Các đĩa đã có, theo thứ tự trong danh mục.
  List<FocusSound> get ownedSounds;

  /// Nạp kho của tài khoản đang đăng nhập (gọi khi vào màn hình chính).
  Future<void> load();

  /// Mua đĩa bằng coin.
  Future<BuyResult> buy(FocusSound sound);
}

class LocalSoundInventory extends SoundInventory {
  Set<String> _bought = {};

  static Box get _box => Hive.box('box_v3');

  static String get _key {
    final user = (AuthService.instance.currentUsername ?? '').toLowerCase();
    return 'OWNED_SOUNDS_$user';
  }

  @override
  bool isOwned(String id) {
    final sound = findSound(id);
    if (sound == null) return false;
    return sound.price == 0 || _bought.contains(id);
  }

  @override
  List<FocusSound> get ownedSounds =>
      kFocusSounds.where((s) => isOwned(s.id)).toList();

  @override
  Future<void> load() async {
    final raw = _box.get(_key);
    _bought = raw is List ? raw.map((e) => e.toString()).toSet() : <String>{};
    notifyListeners();
  }

  @override
  Future<BuyResult> buy(FocusSound sound) async {
    if (isOwned(sound.id)) return BuyResult.alreadyOwned;

    final paid = await CoinService.instance.spend(
      amount: sound.price,
      detail: sound.id,
    );
    if (!paid) return BuyResult.notEnoughCoins;

    _bought.add(sound.id);
    await _box.put(_key, _bought.toList());
    notifyListeners();
    return BuyResult.bought;
  }
}