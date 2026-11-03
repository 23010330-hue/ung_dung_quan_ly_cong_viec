import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todoapp/repositories/user_repository.dart';
import 'package:todoapp/services/auth_service.dart';

/// Bản Firebase của AuthService
class FirebaseAuthService extends AuthService {
  static const String _currentKey = 'CURRENT_USER';
  static const String _uidKey = 'CURRENT_UID';
  static final RegExp _nameOk = RegExp(r'^[a-z0-9][a-z0-9_.]{2,19}$');
  static const String _wrongLogin = 'Sai tên đăng nhập hoặc mật khẩu';
  static const String _socialOnly = 'Tài khoản này đăng nhập bằng Google hoặc Facebook';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRepository _users = UserRepository(FirebaseFirestore.instance);

  Box get _box => Hive.box('box_v3');

  String _key(String username) {
    return UserRepository.nameKey(username);
  }

  bool _validName(String username) {
    return _nameOk.hasMatch(_key(username));
  }

  @override
  String? get currentUsername => _box.get(_currentKey) as String?;
  Future<void> restore() async {
    // chờ Firebase báo trạng thái đăng nhập, tối đa 8 giây
    final user = await _auth.authStateChanges().first.timeout(
          const Duration(seconds: 8),
          onTimeout: () => _auth.currentUser,
        );
    if (user == null) {
      await _clearCache();
      return;
    }
    if (_box.get(_uidKey) == user.uid && currentUsername != null) {
      return;
    }

    try {
      final profile = await _users.getProfile(user.uid);
      if (profile != null) {
        await _cache(user.uid, profile.username);
        return;
      }
    } catch (_) {
      // mất mạng hoặc Firestore lỗi: coi như chưa đăng nhập, người dùng đăng nhập lại
    }
    await _clearCache();
  }

  @override
  Future<void> signInWithUsername(String username, String password) async {
    try {
      final input = username.trim();
      String email;
      if (input.contains('@')) {
        // cho phép gõ thẳng email vào ô tên đăng nhập
        email = input;
      } else {
        if (!_validName(input)) {
          throw const AuthException(_wrongLogin);
        }
        final entry = await _users.getUsername(input);
        if (entry == null) {
          throw const AuthException(_wrongLogin);
        }
        if (entry.viaSocial) {
          throw const AuthException(_socialOnly);
        }
        email = entry.email;
        if (email.isEmpty) {
          throw const AuthException(_wrongLogin);
        }
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _loadProfile(credential.user!);
    } catch (e) {
      throw _toAuthException(e);
    }
  }

  /// Đọc tên đăng nhập của tài khoản vừa đăng nhập bằng email và nhớ lại.
  Future<void> _loadProfile(User user) async {
    final profile = await _users.getProfile(user.uid);
    if (profile == null) {
      await _auth.signOut();
      throw const AuthException(
        'Tài khoản này chưa có hồ sơ trong app. Hãy tạo tài khoản mới.',
      );
    }
    await _cache(user.uid, profile.username);
  }

  @override
  Future<void> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final name = username.trim();
      final cleanEmail = email.trim();
      if (!_validName(name)) {
        throw const AuthException('Tên đăng nhập không hợp lệ');
      }

      // báo sớm nếu tên đã có người dùng (chưa tạo gì cả)
      if (await _users.usernameExists(name)) {
        throw const AuthException('Tên đăng nhập đã tồn tại');
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final user = credential.user!;

      try {
        await _claimUsername(user, name, cleanEmail, viaSocial: false);
      } catch (e) {
        // không để lại tài khoản Firebase mà không có tên đăng nhập
        try {
          await user.delete();
        } catch (_) {
          // không xóa được cũng không sao, lỗi chính bên dưới mới quan trọng
        }
        rethrow;
      }
      await _cache(user.uid, name);
    } catch (e) {
      throw _toAuthException(e);
    }
  }

  /// Giữ chỗ tên đăng nhập và tạo hồ sơ (một giao dịch trong [UserRepository]).
  Future<void> _claimUsername(
    User user,
    String username,
    String email, {
    required bool viaSocial,
  }) async {
    final ok = await _users.claimUsername(
      uid: user.uid,
      username: username,
      email: email,
      viaSocial: viaSocial,
    );
    if (!ok) {
      throw const AuthException('Tên đăng nhập đã tồn tại');
    }
  }

  // ------------------------------------------------------------------- Google

  @override
  Future<SocialSignInResult> signInWithSocial(SocialProvider provider) async {
    try {
      if (provider != SocialProvider.google) {
        throw const AuthException(
          'Đăng nhập bằng Facebook chưa được bật. '
          'Hãy dùng Google hoặc tên đăng nhập.',
        );
      }

      final google = GoogleAuthProvider();
      UserCredential credential;
      if (kIsWeb) {
        credential = await _auth.signInWithPopup(google);
      } else {
        credential = await _auth.signInWithProvider(google);
      }
      final user = credential.user!;

      final profile = await _users.getProfile(user.uid);
      if (profile != null) {
        await _cache(user.uid, profile.username);
        return SocialSignInResult(username: profile.username);
      }
      // tài khoản mới: giữ nguyên trạng thái đã đăng nhập, chờ người dùng chọn tên
      return const SocialSignInResult();
    } catch (e) {
      throw _toAuthException(e);
    }
  }

  @override
  Future<void> completeSocialProfile(String username) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw const AuthException('Phiên đăng nhập đã hết hạn, hãy thử lại');
      }
      final name = username.trim();
      if (!_validName(name)) {
        throw const AuthException('Tên đăng nhập không hợp lệ');
      }
      await _claimUsername(user, name, user.email ?? '', viaSocial: true);
      await _cache(user.uid, name);
    } catch (e) {
      throw _toAuthException(e);
    }
  }

  // ------------------------------------------------------------ quên mật khẩu

  @override
  Future<String> sendPasswordReset(String usernameOrEmail) async {
    try {
      final input = usernameOrEmail.trim();
      String email;
      if (input.contains('@')) {
        email = input;
      } else {
        if (!_validName(input)) {
          throw const AuthException('Không tìm thấy tên đăng nhập này');
        }
        final entry = await _users.getUsername(input);
        if (entry == null) {
          throw const AuthException('Không tìm thấy tên đăng nhập này');
        }
        if (entry.viaSocial) {
          throw const AuthException(
            'Tài khoản này đăng nhập bằng Google hoặc Facebook, '
            'không có mật khẩu để đặt lại',
          );
        }
        email = entry.email;
        if (email.isEmpty) {
          throw const AuthException('Không tìm thấy tên đăng nhập này');
        }
      }

      try {
        await _auth.sendPasswordResetEmail(email: email);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          throw const AuthException('Không có tài khoản nào dùng email này');
        }
        rethrow;
      }
      return maskEmail(email);
    } catch (e) {
      throw _toAuthException(e);
    }
  }

  // ---------------------------------------------------------------- đăng xuất

  @override
  Future<void> signOut() async {
    await _clearCache();
    await _auth.signOut();
  }

  // ---------------------------------------------------------------- tiện ích

  Future<void> _cache(String uid, String username) async {
    await _box.put(_currentKey, username);
    await _box.put(_uidKey, uid);
  }

  Future<void> _clearCache() async {
    await _box.delete(_currentKey);
    await _box.delete(_uidKey);
  }

  /// Đổi mọi lỗi của Firebase thành [AuthException] có câu tiếng Việt dễ hiểu,
  /// để các trang đăng nhập không bao giờ bị kẹt ở trạng thái "đang tải".
  AuthException _toAuthException(Object error) {
    if (error is AuthException) {
      return error;
    }
    // FirebaseAuthException là con của FirebaseException nên phải kiểm tra trước
    if (error is FirebaseAuthException) {
      return AuthException(_authMessage(error));
    }
    if (error is FirebaseException) {
      return AuthException(_firestoreMessage(error));
    }
    return AuthException('Có lỗi xảy ra: $error');
  }

  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-login-credentials':
        return _wrongLogin;
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'email-already-in-use':
        return 'Email đã được sử dụng';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự)';
      case 'user-disabled':
        return 'Tài khoản này đã bị khóa';
      case 'too-many-requests':
        return 'Thử quá nhiều lần, hãy đợi một lúc rồi thử lại';
      case 'network-request-failed':
        return 'Không có kết nối mạng';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
      case 'web-context-canceled':
      case 'canceled':
        return 'Bạn đã hủy đăng nhập';
      case 'popup-blocked':
        return 'Trình duyệt đã chặn cửa sổ đăng nhập, hãy cho phép popup';
      case 'operation-not-allowed':
        return 'Cách đăng nhập này chưa được bật trong Firebase Console';
      case 'account-exists-with-different-credential':
        return 'Email này đã đăng ký bằng cách khác, hãy đăng nhập bằng tên đăng nhập';
      default:
        return 'Lỗi đăng nhập (${e.code})';
    }
  }

  String _firestoreMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Firestore từ chối truy cập. Hãy kiểm tra lại Rules trong Firebase Console';
      case 'unavailable':
        return 'Không kết nối được máy chủ, hãy kiểm tra mạng';
      default:
        return 'Lỗi Firestore (${e.code})';
    }
  }
}
