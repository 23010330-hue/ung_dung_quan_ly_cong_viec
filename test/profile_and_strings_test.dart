import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:todoapp/services/auth_service.dart';
import 'package:todoapp/services/profile_service.dart';
import 'package:todoapp/theme/app_colors.dart';
import 'package:todoapp/until/app_strings.dart';

import 'helpers/test_setup.dart';

void main() {
  setUpAll(setUpTestStorage);
  setUp(resetTestStorage);

  group('Ảnh đại diện (US25, US26)', () {
    Future<void> login(String name) => AuthService.instance.signUp(
          username: name,
          email: '$name@x.com',
          password: '123456',
        );

    test('chưa có ảnh thì loadAvatar trả về null', () async {
      await login('huy');
      expect(ProfileService.loadAvatar(), isNull);
    });

    test('lưu rồi đọc lại đúng byte', () async {
      await login('huy');
      await ProfileService.saveAvatar(Uint8List.fromList([9, 8, 7]));
      expect(ProfileService.loadAvatar(), [9, 8, 7]);
    });

    test('xóa ảnh', () async {
      await login('huy');
      await ProfileService.saveAvatar(Uint8List.fromList([1]));
      await ProfileService.removeAvatar();
      expect(ProfileService.loadAvatar(), isNull);
    });

    test('mỗi tài khoản một ảnh riêng', () async {
      await login('an');
      await ProfileService.saveAvatar(Uint8List.fromList([1, 1]));
      await AuthService.instance.signOut();
      await login('binh');
      expect(ProfileService.loadAvatar(), isNull);
    });
  });

  group('Màu giao diện (US27)', () {
    test('có ít nhất một bảng màu và id nào cũng tra ngược lại được', () {
      expect(AppColorTheme.themes, isNotEmpty);
      for (final t in AppColorTheme.themes) {
        expect(AppColorTheme.fromId(t.id).id, t.id);
      }
    });

    test('id rỗng hoặc lạ không làm app sập', () {
      expect(() => AppColorTheme.fromId(null), returnsNormally);
      expect(() => AppColorTheme.fromId('khong-co'), returnsNormally);
    });
  });

  group('Ngôn ngữ (US28)', () {
    test('tiếng Việt giữ nguyên câu gốc', () {
      expect(translateText('Lưu', true), 'Lưu');
    });

    test('tiếng Anh dịch theo bảng', () {
      expect(translateText('Lưu', false), 'Save');
      expect(translateText('Hoàn tác', false), 'Undo');
      expect(translateText('Ngày', false), 'Daily');
      expect(translateText('Tập trung', false), 'Focus');
    });

    test('câu chưa có bản dịch thì giữ nguyên', () {
      expect(translateText('Câu chưa có bản dịch', false), 'Câu chưa có bản dịch');
    });
  });
}
