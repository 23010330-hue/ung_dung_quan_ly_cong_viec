import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todoapp/models/sync_documents.dart';
import 'package:todoapp/models/user_profile.dart';

void main() {
  group('UserProfile <-> Document users/{uid}', () {
    test('toMap rồi fromMap giữ nguyên dữ liệu', () {
      final profile = UserProfile(
        username: 'huy',
        email: 'huy@gmail.com',
        viaSocial: true,
        createdAt: DateTime(2026, 1, 2),
      );
      final back = UserProfile.fromMap(profile.toMap());
      expect(back.username, 'huy');
      expect(back.email, 'huy@gmail.com');
      expect(back.viaSocial, isTrue);
      expect(back.createdAt, DateTime(2026, 1, 2));
    });

    test('toMap không có createdAt khi chưa có (Firestore tự điền giờ máy chủ)', () {
      const profile = UserProfile(username: 'a', email: '');
      expect(profile.toMap().containsKey('createdAt'), isFalse);
    });

    test('fromMap đọc được Timestamp của Firestore và chuỗi ISO', () {
      expect(
        UserProfile.fromMap({
          'username': 'a',
          'createdAt': Timestamp.fromDate(DateTime(2026, 10, 31, 8, 30)),
        }).createdAt,
        DateTime(2026, 10, 31, 8, 30),
      );
      expect(
        UserProfile.fromMap({'username': 'a', 'createdAt': '2026-05-06T00:00:00'}).createdAt,
        DateTime(2026, 5, 6),
      );
    });

    test('fromMap với dữ liệu thiếu hoặc sai kiểu không báo lỗi', () {
      final p = UserProfile.fromMap({'username': 5, 'viaSocial': 'có'});
      expect(p.username, '');
      expect(p.hasUsername, isFalse);
      expect(p.viaSocial, isFalse);
      expect(p.createdAt, isNull);
    });
  });

  group('UsernameEntry <-> Document usernames/{tên}', () {
    test('toMap có đúng ba trường mà Firestore Rules cho phép', () {
      const entry = UsernameEntry(uid: 'u1', email: 'a@b.c');
      expect(entry.toMap().keys.toSet(), {'uid', 'email', 'viaSocial'});
    });

    test('toMap rồi fromMap', () {
      const entry = UsernameEntry(uid: 'u1', email: 'a@b.c', viaSocial: true);
      final back = UsernameEntry.fromMap(entry.toMap());
      expect(back.uid, 'u1');
      expect(back.email, 'a@b.c');
      expect(back.viaSocial, isTrue);
    });

    test('fromMap rỗng cho giá trị mặc định', () {
      final e = UsernameEntry.fromMap({});
      expect(e.uid, '');
      expect(e.viaSocial, isFalse);
    });
  });

  group('Các Document đồng bộ khác', () {
    test('FocusPreference', () {
      expect(FocusPreference.fromMap(const FocusPreference('lofi').toMap()).selected, 'lofi');
      expect(FocusPreference.fromMap({}).selected, '');
    });

    test('AppSettings', () {
      const s = AppSettings(theme: 'xanh', vietnamese: false);
      final back = AppSettings.fromMap(s.toMap());
      expect(back.theme, 'xanh');
      expect(back.vietnamese, isFalse);
      final empty = AppSettings.fromMap({});
      expect(empty.theme, isNull);
      expect(empty.vietnamese, isNull);
    });

    test('AvatarDocument mã hóa base64 rồi giải mã lại đúng byte', () {
      final doc = AvatarDocument(Uint8List.fromList([1, 2, 3, 250]));
      final map = doc.toMap();
      expect(map['b64'], base64Encode([1, 2, 3, 250]));
      expect(AvatarDocument.fromMap(map)!.bytes, [1, 2, 3, 250]);
    });

    test('AvatarDocument từ chối dữ liệu sai', () {
      expect(AvatarDocument.fromMap({}), isNull);
      expect(AvatarDocument.fromMap({'b64': ''}), isNull);
      expect(AvatarDocument.fromMap({'b64': '***không phải base64***'}), isNull);
    });
  });
}
