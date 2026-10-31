import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todoapp/services/auth_service.dart';

/// Bản Firebase của [AuthService].
///
/// Cách hoạt động:
/// - Firebase Authentication chỉ biết email + mật khẩu, nên app tự giữ bảng tra
///   "tên đăng nhập -> email" trong Firestore (collection `usernames`, id là tên viết thường).
///   Đăng nhập bằng tên đăng nhập = tra email rồi đăng nhập bằng email.
/// - Hồ sơ mỗi người nằm ở `users/{uid}` (có trường `username`).
/// - Tên đăng nhập hiện tại được nhớ thêm trong Hive để [currentUsername] trả về ngay,
///   không phải chờ mạng. Mọi dữ liệu theo tên đăng nhập (việc, đĩa đã chọn, ảnh đại diện...) vẫn dùng như cũ.
class FirebaseAuthService extends AuthService {
  static const _currentKey = 'CURRENT_USER';
  static const _uidKey = 'CURRENT_UID';

  /// Tên đăng nhập hợp lệ khi đã viết thường: bắt đầu bằng chữ/số, dài 3-20 ký tự.
  /// (Cũng tránh các id Firestore cấm như `.`, `..` và `__abc__`.)
  static final _nameOk = RegExp(r'^[a-z0-9][a-z0-9_.]{2,19}$');

  static const _wrongLogin = 'Sai tên đăng nhập hoặc mật khẩu';
  static const _socialOnly = 'Tài khoản này đăng nhập bằng Google hoặc Facebook';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Box get _box => Hive.box('box_v3');

  String _key(String username) => username.trim().toLowerCase();

  bool _validName(String username) => _nameOk.hasMatch(_key(username));

  DocumentReference<Map<String, dynamic>> _nameDoc(String username) =>
      _db.collection('usernames').doc(_key(username));

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  @override
  String? get currentUsername => _box.get(_currentKey) as String?;

  // ---------------------------------------------------------------- khởi động

  /// Gọi một lần khi mở app (trước runApp): khôi phục phiên đăng nhập đã lưu.
  /// Sau hàm này [currentUsername] đúng với trạng thái đăng nhập thật của Firebase.
  Future<void> restore() async {
    final user = await _auth.authStateChanges().first.timeout(
      const Duration(seconds: 8),
      onTimeout: () => _auth.currentUser,
    );
    if (user == null) {
      await _clearCache();
      return;
    }

    // đã nhớ đúng người này rồi thì khỏi hỏi mạng
    if (_box.get(_uidKey) == user.uid && currentUsername != null) return;

    try {
      final snap = await _userDoc(user.uid).get();
      final name = snap.data()?['username'] as String?;
      if (name != null) {
        await _cache(user.uid, name);
        return;
      }
    } catch (_) {
      // mất mạng hoặc Firestore lỗi: coi như chưa đăng nhập, người dùng đăng nhập lại
    }
    await _clearCache();
  }

  // ----------------------------------------------------------------- đăng nhập

  @override
  Future<void> signInWithUsername(String username, String password) {
    return _guard(() async {
      final input = username.trim();
      final String email;
      if (input.contains('@')) {
        // cho phép gõ thẳng email vào ô tên đăng nhập
        email = input;
      } else {
        if (!_validName(input)) throw const AuthException(_wrongLogin);
        final data = (await _nameDoc(input).get()).data();
        if (data == null) throw const AuthException(_wrongLogin);
        if (data['viaSocial'] == true) throw const AuthException(_socialOnly);
        email = (data['email'] as String?) ?? '';
        if (email.isEmpty) throw const AuthException(_wrongLogin);
      }

      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _loadProfile(cred.user!);
    });
  }

  /// Đọc tên đăng nhập của tài khoản vừa đăng nhập bằng email và nhớ lại.
  Future<void> _loadProfile(User user) async {
    final snap = await _userDoc(user.uid).get();
    final name = snap.data()?['username'] as String?;
    if (name == null) {
      await _auth.signOut();
      throw const AuthException(
        'Tài khoản này chưa có hồ sơ trong app. Hãy tạo tài khoản mới.',
      );
    }
    await _cache(user.uid, name);
  }

  // ------------------------------------------------------------------ đăng ký

  @override
  Future<void> signUp({
    required String username,
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final name = username.trim();
      final cleanEmail = email.trim();
      if (!_validName(name)) {
        throw const AuthException('Tên đăng nhập không hợp lệ');
      }

      // báo sớm nếu tên đã có người dùng (chưa tạo gì cả)
      if ((await _nameDoc(name).get()).exists) {
        throw const AuthException('Tên đăng nhập đã tồn tại');
      }

      final cred = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final user = cred.user!;
      try {
        await _claimUsername(user, name, cleanEmail, viaSocial: false);
      } catch (_) {
        // không để lại tài khoản Firebase mà không có tên đăng nhập
        try {
          await user.delete();
        } catch (_) {
          // không xóa được cũng không sao, lỗi chính bên dưới mới quan trọng
        }
        rethrow;
      }
      await _cache(user.uid, name);
    });
  }

  /// Giữ chỗ tên đăng nhập và tạo hồ sơ trong cùng một giao dịch:
  /// hai người cùng đăng ký một tên một lúc thì chỉ một người thành công.
  Future<void> _claimUsername(
    User user,
    String username,
    String email, {
    required bool viaSocial,
  }) async {
    final nameRef = _nameDoc(username);
    final userRef = _userDoc(user.uid);

    final ok = await _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(nameRef);
      if (snap.exists) return false;
      tx.set(nameRef, {
        'uid': user.uid,
        'email': email,
        'viaSocial': viaSocial,
      });
      tx.set(userRef, {
        'username': username,
        'email': email,
        'viaSocial': viaSocial,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
    if (!ok) throw const AuthException('Tên đăng nhập đã tồn tại');
  }

  // ------------------------------------------------------------------- Google

  @override
  Future<SocialSignInResult> signInWithSocial(SocialProvider provider) {
    return _guard(() async {
      if (provider != SocialProvider.google) {
        throw const AuthException(
          'Đăng nhập bằng Facebook chưa được bật. '
          'Hãy dùng Google hoặc tên đăng nhập.',
        );
      }

      final google = GoogleAuthProvider();
      final cred = kIsWeb
          ? await _auth.signInWithPopup(google)
          : await _auth.signInWithProvider(google);
      final user = cred.user!;

      final snap = await _userDoc(user.uid).get();
      final name = snap.data()?['username'] as String?;
      if (name != null) {
        await _cache(user.uid, name);
        return SocialSignInResult(username: name);
      }
      // tài khoản mới: giữ nguyên trạng thái đã đăng nhập, chờ người dùng chọn tên
      return const SocialSignInResult();
    });
  }

  @override
  Future<void> completeSocialProfile(String username) {
    return _guard(() async {
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
    });
  }

  // ------------------------------------------------------------ quên mật khẩu

  @override
  Future<String> sendPasswordReset(String usernameOrEmail) {
    return _guard(() async {
      final input = usernameOrEmail.trim();
      final String email;
      if (input.contains('@')) {
        email = input;
      } else {
        const notFound = AuthException('Không tìm thấy tên đăng nhập này');
        if (!_validName(input)) throw notFound;
        final data = (await _nameDoc(input).get()).data();
        if (data == null) throw notFound;
        if (data['viaSocial'] == true) {
          throw const AuthException(
            'Tài khoản này đăng nhập bằng Google hoặc Facebook, '
            'không có mật khẩu để đặt lại',
          );
        }
        email = (data['email'] as String?) ?? '';
        if (email.isEmpty) throw notFound;
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
    });
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

  /// Chuyển mọi lỗi của Firebase thành [AuthException] có câu tiếng Việt dễ hiểu,
  /// để các trang đăng nhập không bao giờ bị kẹt ở trạng thái "đang tải".
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_authMessage(e));
    } on FirebaseException catch (e) {
      throw AuthException(_firestoreMessage(e));
    } catch (e) {
      throw AuthException('Có lỗi xảy ra: $e');
    }
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