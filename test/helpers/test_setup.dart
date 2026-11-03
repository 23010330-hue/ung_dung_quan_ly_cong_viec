import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:todoapp/services/auth_service.dart';

/// Mở một Hive box tạm cho bài test và dùng tài khoản giả không chờ mạng.
Future<void> setUpTestStorage() async {
  final dir = Directory.systemTemp.createTempSync('todoapp_test_');
  Hive.init(dir.path);
  await Hive.openBox('box_v3');
  AuthService.instance = FakeAuthService(delay: Duration.zero);
}

/// Xóa sạch dữ liệu giữa hai bài test.
Future<void> resetTestStorage() async {
  await Hive.box('box_v3').clear();
  AuthService.instance = FakeAuthService(delay: Duration.zero);
}
