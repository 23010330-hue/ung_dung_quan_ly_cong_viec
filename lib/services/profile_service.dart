import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todoapp/services/auth_service.dart';

/// Lưu hồ sơ của tài khoản đang đăng nhập (hiện là ảnh đại diện).
/// Hiện lưu trong Hive trên máy; khi nối Firebase sẽ chuyển lên Firestore.
class ProfileService {
  static Box get _box => Hive.box('box_v3');

  static String get _avatarKey {
    final user = AuthService.instance.currentUsername ?? '';
    return 'AVATAR_${user.toLowerCase()}';
  }

  static Uint8List? loadAvatar() {
    final raw = _box.get(_avatarKey);
    if (raw is Uint8List) return raw;
    if (raw is List) return Uint8List.fromList(List<int>.from(raw));
    return null;
  }

  static Future<void> saveAvatar(Uint8List bytes) =>
      _box.put(_avatarKey, bytes);

  static Future<void> removeAvatar() => _box.delete(_avatarKey);
}