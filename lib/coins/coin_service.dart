import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todoapp/coins/coin_rules.dart';
import 'package:todoapp/services/auth_service.dart';

enum CoinKind { focus, task, spend }

/// Một dòng trong sổ coin.
class CoinEntry {
  final CoinKind kind;

  /// Dương = nhận coin, âm = tiêu coin.
  final int amount;

  /// focus: số phút; task: tên việc; spend: ghi chú (ví dụ tên đĩa nhạc đã mua).
  final String detail;
  final DateTime time;

  const CoinEntry({
    required this.kind,
    required this.amount,
    required this.detail,
    required this.time,
  });

  Map<String, dynamic> toMap() => {
        'kind': kind.name,
        'amount': amount,
        'detail': detail,
        'time': time.millisecondsSinceEpoch,
      };

  static CoinEntry? fromMap(Object? raw) {
    if (raw is! Map) return null;
    try {
      final kind = CoinKind.values.firstWhere((k) => k.name == raw['kind']);
      return CoinEntry(
        kind: kind,
        amount: raw['amount'] as int,
        detail: (raw['detail'] ?? '').toString(),
        time: DateTime.fromMillisecondsSinceEpoch(raw['time'] as int),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Kết quả một lần xét thưởng: [requested] là mức đáng ra được, [granted] là mức thực nhận.
class CoinAward {
  final int requested;
  final int granted;

  const CoinAward({required this.requested, required this.granted});

  /// Bị cắt bớt (hoặc mất hết) vì chạm giới hạn trong ngày.
  bool get capped => granted < requested;
}

/// Ví coin của tài khoản đang đăng nhập.
///
/// Giống AuthService: giao diện dùng [CoinService.instance]; hiện là bản lưu trong Hive
/// trên máy ([LocalCoinService]). Khi nối Firebase chỉ cần viết bản mới và gán vào [instance],
/// việc cộng coin nên chuyển sang server để không ai tự sửa được số dư hay đồng hồ máy.
abstract class CoinService extends ChangeNotifier {
  static CoinService instance = LocalCoinService();

  int get balance;

  /// Sổ giao dịch, mới nhất ở đầu.
  List<CoinEntry> get entries;

  /// Coin tập trung đã nhận hôm nay.
  int get focusEarnedToday;

  /// Số việc đúng hạn đã được thưởng hôm nay.
  int get tasksRewardedToday;

  /// Nạp dữ liệu của tài khoản đang đăng nhập (gọi khi vào màn hình chính).
  Future<void> load();

  Future<CoinAward> awardFocus({required int minutes});

  Future<CoinAward> awardTask({required String taskName});

  /// Trừ coin (dùng cho cửa hàng). Trả về false nếu không đủ coin.
  Future<bool> spend({required int amount, required String detail});
}

class LocalCoinService extends CoinService {
  static const int _maxEntries = 300;

  final DateTime Function() _clock;
  int _balance = 0;
  List<CoinEntry> _entries = [];

  LocalCoinService({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static Box get _box => Hive.box('box_v3');

  static String get _user =>
      (AuthService.instance.currentUsername ?? '').toLowerCase();
  static String get _balanceKey => 'COIN_BALANCE_$_user';
  static String get _ledgerKey => 'COIN_LEDGER_$_user';

  @override
  int get balance => _balance;

  @override
  List<CoinEntry> get entries => List.unmodifiable(_entries);

  bool _isToday(DateTime t) {
    final now = _clock();
    return t.year == now.year && t.month == now.month && t.day == now.day;
  }

  @override
  int get focusEarnedToday => _entries
      .where((e) => e.kind == CoinKind.focus && _isToday(e.time))
      .fold(0, (sum, e) => sum + e.amount);

  @override
  int get tasksRewardedToday => _entries
      .where((e) => e.kind == CoinKind.task && _isToday(e.time))
      .length;

  @override
  Future<void> load() async {
    final rawBalance = _box.get(_balanceKey);
    _balance = rawBalance is int ? rawBalance : 0;

    final rawLedger = _box.get(_ledgerKey);
    _entries = [];
    if (rawLedger is List) {
      for (final item in rawLedger) {
        final entry = CoinEntry.fromMap(item);
        if (entry != null) _entries.add(entry);
      }
    }
    notifyListeners();
  }

  Future<void> _add(CoinEntry entry) async {
    _balance += entry.amount;
    _entries.insert(0, entry);
    if (_entries.length > _maxEntries) {
      _entries = _entries.sublist(0, _maxEntries);
    }
    await _box.put(_balanceKey, _balance);
    await _box.put(_ledgerKey, _entries.map((e) => e.toMap()).toList());
    notifyListeners();
  }

  @override
  Future<CoinAward> awardFocus({required int minutes}) async {
    final requested = CoinRules.focusReward(minutes: minutes);
    final granted = CoinRules.focusGrant(
      minutes: minutes,
      earnedToday: focusEarnedToday,
    );
    if (granted > 0) {
      await _add(CoinEntry(
        kind: CoinKind.focus,
        amount: granted,
        detail: '$minutes',
        time: _clock(),
      ));
    }
    return CoinAward(requested: requested, granted: granted);
  }

  @override
  Future<CoinAward> awardTask({required String taskName}) async {
    final granted = CoinRules.taskGrant(rewardedToday: tasksRewardedToday);
    if (granted > 0) {
      await _add(CoinEntry(
        kind: CoinKind.task,
        amount: granted,
        detail: taskName,
        time: _clock(),
      ));
    }
    return CoinAward(requested: CoinRules.taskCoins, granted: granted);
  }

  @override
  Future<bool> spend({required int amount, required String detail}) async {
    if (amount <= 0 || amount > _balance) return false;
    await _add(CoinEntry(
      kind: CoinKind.spend,
      amount: -amount,
      detail: detail,
      time: _clock(),
    ));
    return true;
  }
}