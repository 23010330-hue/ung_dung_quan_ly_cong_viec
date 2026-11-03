import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todoapp/services/auth_service.dart';
import 'package:todoapp/until/auth_widgets.dart';

void main() {
  group('AuthValidators.username (US01)', () {
    test('để trống', () {
      expect(AuthValidators.username(''), 'Vui lòng nhập tên đăng nhập');
      expect(AuthValidators.username(null), 'Vui lòng nhập tên đăng nhập');
      expect(AuthValidators.username('   '), 'Vui lòng nhập tên đăng nhập');
    });

    test('quá ngắn hoặc quá dài', () {
      const msg = 'Tên đăng nhập dài từ 3 đến 20 ký tự';
      expect(AuthValidators.username('ab'), msg);
      expect(AuthValidators.username('a' * 21), msg);
    });

    test('ký tự không cho phép', () {
      const msg = 'Chỉ gồm chữ không dấu, số, dấu _ và .';
      expect(AuthValidators.username('ab cd'), msg);
      expect(AuthValidators.username('ánh'), msg);
      expect(AuthValidators.username('a@b'), msg);
    });

    test('không được bắt đầu bằng _ hoặc .', () {
      const msg = 'Tên đăng nhập phải bắt đầu bằng chữ hoặc số';
      expect(AuthValidators.username('_abc'), msg);
      expect(AuthValidators.username('.abc'), msg);
    });

    test('tên hợp lệ', () {
      expect(AuthValidators.username('huy_01'), isNull);
      expect(AuthValidators.username('a.b'), isNull);
      expect(AuthValidators.username('  huy  '), isNull);
      expect(AuthValidators.username('a' * 20), isNull);
    });
  });

  group('AuthValidators.email (US01)', () {
    test('để trống', () {
      expect(AuthValidators.email(''), 'Vui lòng nhập email');
      expect(AuthValidators.email(null), 'Vui lòng nhập email');
    });

    test('sai định dạng', () {
      expect(AuthValidators.email('abc'), 'Email không hợp lệ');
      expect(AuthValidators.email('a@b'), 'Email không hợp lệ');
      expect(AuthValidators.email('a b@c.d'), 'Email không hợp lệ');
      expect(AuthValidators.email('@c.d'), 'Email không hợp lệ');
    });

    test('hợp lệ', () {
      expect(AuthValidators.email('a@b.c'), isNull);
      expect(AuthValidators.email(' huy@gmail.com '), isNull);
    });
  });

  group('AuthValidators.password (US01)', () {
    test('để trống và quá ngắn', () {
      expect(AuthValidators.password(''), 'Vui lòng nhập mật khẩu');
      expect(AuthValidators.password('12345'), 'Mật khẩu tối thiểu 6 ký tự');
    });

    test('đủ 6 ký tự', () {
      expect(AuthValidators.password('123456'), isNull);
    });
  });

  group('AuthValidators.confirmPassword (US01)', () {
    test('trống, khác nhau và khớp', () {
      final original = TextEditingController(text: 'matkhau1');
      addTearDown(original.dispose);
      final check = AuthValidators.confirmPassword(original);
      expect(check(''), 'Vui lòng nhập lại mật khẩu');
      expect(check('matkhau2'), 'Mật khẩu xác nhận không khớp');
      expect(check('matkhau1'), isNull);
    });
  });

  group('AuthValidators.required (US02)', () {
    test('trống thì trả về thông báo, có chữ thì null', () {
      expect(AuthValidators.required(null, 'thiếu'), 'thiếu');
      expect(AuthValidators.required('   ', 'thiếu'), 'thiếu');
      expect(AuthValidators.required('x', 'thiếu'), isNull);
    });
  });

  group('maskEmail (US04)', () {
    test('che phần giữa của tên', () {
      expect(maskEmail('huy.tran@gmail.com'), 'h***n@gmail.com');
    });

    test('tên ngắn chỉ giữ chữ đầu', () {
      expect(maskEmail('ab@x.com'), 'a***@x.com');
      expect(maskEmail('a@x.com'), 'a***@x.com');
    });

    test('không có @ thì giữ nguyên', () {
      expect(maskEmail('khongcoat'), 'khongcoat');
      expect(maskEmail('@x.com'), '@x.com');
    });
  });
}
