import 'dart:convert';
import 'dart:typed_data';

/// Document `users/{uid}/data/focus`: đĩa nhạc đã chọn.
class FocusPreference {
  final String selected;

  const FocusPreference(this.selected);

  static FocusPreference fromMap(Map map) {
    if (map['selected'] is String) {
      return FocusPreference(map['selected']);
    }
    return const FocusPreference('');
  }

  Map<String, dynamic> toMap() {
    return {'selected': selected};
  }
}

/// Document `users/{uid}/data/settings`: màu giao diện và ngôn ngữ.
class AppSettings {
  final String? theme;
  final bool? vietnamese;

  const AppSettings({this.theme, this.vietnamese});

  static AppSettings fromMap(Map map) {
    String? theme;
    if (map['theme'] is String) {
      theme = map['theme'];
    }

    bool? vietnamese;
    if (map['vi'] is bool) {
      vietnamese = map['vi'];
    }

    return AppSettings(theme: theme, vietnamese: vietnamese);
  }

  Map<String, dynamic> toMap() {
    return {'theme': theme, 'vi': vietnamese};
  }
}

/// Document `users/{uid}/data/avatar`: ảnh đại diện (đã thu nhỏ) mã hóa base64.
class AvatarDocument {
  final Uint8List bytes;

  const AvatarDocument(this.bytes);

  /// Trả về null nếu không có dữ liệu ảnh hợp lệ.
  static AvatarDocument? fromMap(Map map) {
    final text = map['b64'];
    if (text is! String || text.isEmpty) {
      return null;
    }
    try {
      return AvatarDocument(base64Decode(text));
    } on FormatException {
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {'b64': base64Encode(bytes)};
  }
}
