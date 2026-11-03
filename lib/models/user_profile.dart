import 'package:cloud_firestore/cloud_firestore.dart';

/// Document `users/{uid}`: hồ sơ của một tài khoản.
class UserProfile {
  final String username;
  final String email;
  final bool viaSocial;

  /// null khi chưa có; Firestore điền giờ máy chủ lúc tạo (xem UserRepository).
  final DateTime? createdAt;

  const UserProfile({
    required this.username,
    required this.email,
    this.viaSocial = false,
    this.createdAt,
  });

  bool get hasUsername => username.isNotEmpty;

  static UserProfile fromMap(Map map) {
    String username = '';
    if (map['username'] is String) {
      username = map['username'];
    }

    String email = '';
    if (map['email'] is String) {
      email = map['email'];
    }

    return UserProfile(
      username: username,
      email: email,
      viaSocial: map['viaSocial'] == true,
      createdAt: _toDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'username': username,
      'email': email,
      'viaSocial': viaSocial,
    };
    if (createdAt != null) {
      map['createdAt'] = createdAt;
    }
    return map;
  }

  /// Chấp nhận DateTime, Timestamp của Firestore hoặc chuỗi ngày giờ.
  static DateTime? _toDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Document `usernames/{tên viết thường}`: bảng tra tên đăng nhập sang email.
class UsernameEntry {
  final String uid;
  final String email;
  final bool viaSocial;

  const UsernameEntry({
    required this.uid,
    required this.email,
    this.viaSocial = false,
  });

  static UsernameEntry fromMap(Map map) {
    String uid = '';
    if (map['uid'] is String) {
      uid = map['uid'];
    }

    String email = '';
    if (map['email'] is String) {
      email = map['email'];
    }

    return UsernameEntry(
      uid: uid,
      email: email,
      viaSocial: map['viaSocial'] == true,
    );
  }

  /// Đúng ba trường mà Firestore Rules cho phép tạo.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'viaSocial': viaSocial,
    };
  }
}
