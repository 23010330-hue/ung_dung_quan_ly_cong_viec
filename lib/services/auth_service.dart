import 'package:hive_flutter/hive_flutter.dart';

/// Các cách đăng nhập bằng tài khoản bên thứ ba.
enum SocialProvider { google, facebook }

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Kết quả đăng nhập bằng Google/Facebook.
/// [username] == null nghĩa là tài khoản mới, cần người dùng chọn tên đăng nhập.
class SocialSignInResult {
  final String? username;
  const SocialSignInResult({this.username});

  bool get needsUsername => username == null;
}

/// Giao diện chung cho phần xác thực.
/// Hiện dùng [FakeAuthService]; khi nối Firebase chỉ cần viết
/// FirebaseAuthService và đổi dòng `instance` bên dưới.
abstract class AuthService {
  static AuthService instance = FakeAuthService();

  String? get currentUsername;

  Future<void> signInWithUsername(String username, String password);

  Future<void> signUp({
    required String username,
    required String email,
    required String password,
  });

  Future<SocialSignInResult> signInWithSocial(SocialProvider provider);

  /// Gọi sau [signInWithSocial] khi tài khoản mới cần đặt tên đăng nhập.
  Future<void> completeSocialProfile(String username);

  Future<void> signOut();
}

/// Bản giả để thử giao diện: lưu tài khoản trong Hive trên máy.
/// Mật khẩu lưu dạng chữ thường CHỈ để test, bản Firebase sẽ thay thế hoàn toàn.
class FakeAuthService extends AuthService {
  static const _usersKey = 'FAKE_USERS';
  static const _socialKey = 'FAKE_SOCIAL_LINKS';
  static const _currentKey = 'CURRENT_USER';

  Box get _box => Hive.box('box_v3');
  SocialProvider? _pendingProvider;

  String _key(String username) => username.trim().toLowerCase();

  Future<void> _fakeDelay() =>
      Future.delayed(const Duration(milliseconds: 700));

  Map<String, Map<String, String>> _readUsers() {
    final raw = _box.get(_usersKey);
    final result = <String, Map<String, String>>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is Map) {
          result[key.toString()] = value.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          );
        }
      });
    }
    return result;
  }

  Map<String, String> _readSocialLinks() {
    final raw = _box.get(_socialKey);
    final result = <String, String>{};
    if (raw is Map) {
      raw.forEach((key, value) => result[key.toString()] = value.toString());
    }
    return result;
  }

  @override
  String? get currentUsername => _box.get(_currentKey) as String?;

  @override
  Future<void> signInWithUsername(String username, String password) async {
    await _fakeDelay();
    final user = _readUsers()[_key(username)];
    if (user == null) {
      throw const AuthException('Sai tên đăng nhập hoặc mật khẩu');
    }
    if ((user['password'] ?? '').isEmpty) {
      throw const AuthException(
        'Tài khoản này đăng nhập bằng Google hoặc Facebook',
      );
    }
    if (user['password'] != password) {
      throw const AuthException('Sai tên đăng nhập hoặc mật khẩu');
    }
    await _box.put(_currentKey, user['username']);
  }

  @override
  Future<void> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    await _fakeDelay();
    final users = _readUsers();
    if (users.containsKey(_key(username))) {
      throw const AuthException('Tên đăng nhập đã tồn tại');
    }
    final emailTaken = users.values.any(
      (u) => (u['email'] ?? '').toLowerCase() == email.trim().toLowerCase(),
    );
    if (emailTaken) {
      throw const AuthException('Email đã được sử dụng');
    }
    users[_key(username)] = {
      'username': username.trim(),
      'email': email.trim(),
      'password': password,
    };
    await _box.put(_usersKey, users);
    await _box.put(_currentKey, username.trim());
  }

  @override
  Future<SocialSignInResult> signInWithSocial(SocialProvider provider) async {
    await _fakeDelay();
    final existing = _readSocialLinks()[provider.name];
    if (existing != null) {
      await _box.put(_currentKey, existing);
      return SocialSignInResult(username: existing);
    }
    _pendingProvider = provider;
    return const SocialSignInResult();
  }

  @override
  Future<void> completeSocialProfile(String username) async {
    await _fakeDelay();
    final provider = _pendingProvider;
    if (provider == null) {
      throw const AuthException('Phiên đăng nhập đã hết hạn, hãy thử lại');
    }
    final users = _readUsers();
    if (users.containsKey(_key(username))) {
      throw const AuthException('Tên đăng nhập đã tồn tại');
    }
    users[_key(username)] = {
      'username': username.trim(),
      'email': '',
      'password': '',
    };
    final links = _readSocialLinks();
    links[provider.name] = username.trim();
    await _box.put(_usersKey, users);
    await _box.put(_socialKey, links);
    await _box.put(_currentKey, username.trim());
    _pendingProvider = null;
  }

  @override
  Future<void> signOut() async {
    await _box.delete(_currentKey);
  }
}