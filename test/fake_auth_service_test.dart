import 'package:flutter_test/flutter_test.dart';
import 'package:todoapp/services/auth_service.dart';

import 'helpers/test_setup.dart';

// Dùng để kiểm tra "việc này phải báo lỗi AuthException với đúng câu này".
// Ví dụ: expectLater(register(), authError('Email đã được sử dụng'));
Matcher authError(String message) {
  return throwsA(
    isA<AuthException>().having((e) => e.message, 'message', message),
  );
}

void main() {
  late FakeAuthService auth;

  setUpAll(setUpTestStorage);
  setUp(() async {
    await resetTestStorage();
    auth = AuthService.instance as FakeAuthService;
  });

  // Đăng ký nhanh một tài khoản
  Future<void> register([String name = 'huy', String email = 'huy@gmail.com']) async {
    await auth.signUp(username: name, email: email, password: '123456');
  }

  group('Đăng ký (US01)', () {
    test('đăng ký xong thì đã đăng nhập', () async {
      await register();
      expect(auth.currentUsername, 'huy');
    });

    test('tên đăng nhập trùng, không phân biệt hoa thường', () async {
      await register();
      await expectLater(register('HUY', 'khac@gmail.com'), authError('Tên đăng nhập đã tồn tại'));
    });

    test('email trùng', () async {
      await register();
      await expectLater(register('an', 'HUY@gmail.com'), authError('Email đã được sử dụng'));
    });
  });

  group('Đăng nhập (US02)', () {
    setUp(() async {
      await register();
      await auth.signOut();
    });

    test('đúng tên đăng nhập và mật khẩu', () async {
      await auth.signInWithUsername('huy', '123456');
      expect(auth.currentUsername, 'huy');
    });

    test('tên đăng nhập không phân biệt hoa thường', () async {
      await auth.signInWithUsername('HUY', '123456');
      expect(auth.currentUsername, 'huy');
    });

    test('sai mật khẩu', () async {
      await expectLater(
        auth.signInWithUsername('huy', 'sai'),
        authError('Sai tên đăng nhập hoặc mật khẩu'),
      );
      expect(auth.currentUsername, isNull);
    });

    test('tên đăng nhập không tồn tại', () async {
      await expectLater(
        auth.signInWithUsername('nobody', '123456'),
        authError('Sai tên đăng nhập hoặc mật khẩu'),
      );
    });
  });

  group('Đăng nhập Google (US03)', () {
    test('tài khoản mới phải đặt tên đăng nhập', () async {
      final result = await auth.signInWithSocial(SocialProvider.google);
      expect(result.needsUsername, isTrue);
      await auth.completeSocialProfile('gg_user');
      expect(auth.currentUsername, 'gg_user');
    });

    test('lần sau đăng nhập thẳng bằng tên đã đặt', () async {
      await auth.signInWithSocial(SocialProvider.google);
      await auth.completeSocialProfile('gg_user');
      await auth.signOut();
      final result = await auth.signInWithSocial(SocialProvider.google);
      expect(result.needsUsername, isFalse);
      expect(result.username, 'gg_user');
      expect(auth.currentUsername, 'gg_user');
    });

    test('đặt tên khi chưa đăng nhập Google thì báo hết phiên', () async {
      await expectLater(
        auth.completeSocialProfile('abc'),
        authError('Phiên đăng nhập đã hết hạn, hãy thử lại'),
      );
    });

    test('tên đăng nhập đã có người dùng', () async {
      await register('gg_user');
      await auth.signOut();
      await auth.signInWithSocial(SocialProvider.google);
      await expectLater(
        auth.completeSocialProfile('gg_user'),
        authError('Tên đăng nhập đã tồn tại'),
      );
    });

    test('tài khoản Google không đăng nhập bằng mật khẩu được', () async {
      await auth.signInWithSocial(SocialProvider.google);
      await auth.completeSocialProfile('gg_user');
      await auth.signOut();
      await expectLater(
        auth.signInWithUsername('gg_user', 'bat-ky'),
        authError('Tài khoản này đăng nhập bằng Google hoặc Facebook'),
      );
    });
  });

  group('Quên mật khẩu (US04)', () {
    setUp(() => register());

    test('theo tên đăng nhập trả về email đã che', () async {
      expect(await auth.sendPasswordReset('huy'), 'h***y@gmail.com');
    });

    test('theo email', () async {
      expect(await auth.sendPasswordReset('HUY@gmail.com'), 'h***y@gmail.com');
    });

    test('không tìm thấy tài khoản', () async {
      await expectLater(
        auth.sendPasswordReset('khongco'),
        authError('Không tìm thấy tài khoản này'),
      );
      await expectLater(
        auth.sendPasswordReset('khongco@x.com'),
        authError('Không tìm thấy tài khoản này'),
      );
    });
  });

  group('Đăng xuất (US29)', () {
    test('đăng xuất xóa người dùng hiện tại', () async {
      await register();
      expect(auth.currentUsername, 'huy');
      await auth.signOut();
      expect(auth.currentUsername, isNull);
    });
  });
}
