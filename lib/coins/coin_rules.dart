import 'dart:math';

/// Luật kiếm coin. Toàn bộ là hằng số và hàm thuần: không dùng Flutter, Hive hay Firebase,
/// nên sau này đặt y nguyên lên server (Cloud Functions) hoặc viết test rất dễ.
/// Muốn đổi mức thưởng: chỉ sửa các hằng số ở đây.
class CoinRules {
  const CoinRules._();

  /// Tập trung: cứ mỗi [focusBlockMinutes] phút (chạy trọn mốc đã chọn) được [focusCoinsPerBlock] coin.
  static const int focusBlockMinutes = 30;
  static const int focusCoinsPerBlock = 5;

  /// Trần coin nhận từ tập trung mỗi ngày (80 coin = 16 khối = 8 giờ).
  static const int focusDailyCap = 80;

  /// Hoàn thành việc đúng hạn: số coin mỗi việc và số việc tối đa được thưởng mỗi ngày.
  static const int taskCoins = 2;
  static const int taskDailyLimit = 5;

  /// Coin của một phiên tập trung chạy hết [minutes] phút (chưa tính trần ngày).
  static int focusReward({required int minutes}) {
    return (minutes ~/ focusBlockMinutes) * focusCoinsPerBlock;
  }

  /// Coin thực nhận sau khi áp trần ngày; [earnedToday] là số coin tập trung đã nhận hôm nay.
  static int focusGrant({required int minutes, required int earnedToday}) {
    final room = max(0, focusDailyCap - earnedToday);
    return min(focusReward(minutes: minutes), room);
  }

  /// Coin cho một việc đúng hạn; [rewardedToday] là số việc đã được thưởng hôm nay.
  static int taskGrant({required int rewardedToday}) {
    return rewardedToday >= taskDailyLimit ? 0 : taskCoins;
  }

  /// Hoàn thành đúng hạn = ngày hoàn thành không muộn hơn ngày đã hẹn (chỉ so ngày, bỏ giờ).
  static bool isOnTime({required DateTime scheduled, required DateTime completed}) {
    final s = DateTime(scheduled.year, scheduled.month, scheduled.day);
    final c = DateTime(completed.year, completed.month, completed.day);
    return !c.isAfter(s);
  }
}