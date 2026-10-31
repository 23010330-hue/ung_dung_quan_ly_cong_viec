import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todoapp/services/auth_service.dart';

typedef _Json = Map<String, dynamic>;

/// Một nhóm dữ liệu được đồng bộ: nằm ở users/{uid}/data/{name} trên Firestore
/// và ở các khóa [keys] trong Hive.
class _Item {
  _Item(this.name, this.keys, this.read, this.write);

  final String name;
  final List<String> Function(String user) keys;
  final _Json? Function(Box box, String user) read;
  final Future<void> Function(Box box, String user, _Json data) write;
}

/// Đồng bộ dữ liệu của tài khoản đang đăng nhập giữa Hive (trên máy) và Firestore.
///
/// - [start]: kéo dữ liệu từ Firestore về Hive. Chưa có trên Firestore thì đẩy dữ liệu trên máy lên.
/// - Sau đó mọi thay đổi trong Hive được đẩy lên sau 2 giây (gộp nhiều thay đổi liên tiếp).
/// - [stop]: đẩy nốt phần còn chờ rồi ngừng. Gọi TRƯỚC khi đăng xuất.
///
/// Phần còn lại của app không cần biết gì: vẫn đọc và ghi Hive như trước.
class CloudSync {
  CloudSync._();
  static final CloudSync instance = CloudSync._();

  static const _pushDelay = Duration(seconds: 2);
  static const _netTimeout = Duration(seconds: 6);

  Box get _box => Hive.box('box_v3');

  final List<_Item> _items = [
    _Item('tasks', (u) => ['TODOLIST_$u'], _readTasks, _writeTasks),
    _Item('focus', (u) => ['FOCUS_SOUND_$u'], _readFocus, _writeFocus),
    _Item('avatar', (u) => ['AVATAR_$u'], _readAvatar, _writeAvatar),
    // màu giao diện và ngôn ngữ là khóa chung của máy, nhưng đi theo tài khoản
    _Item(
      'settings',
      (_) => ['APP_COLOR_THEME', 'IS_VIETNAMESE'],
      _readSettings,
      _writeSettings,
    ),
  ];

  String _user = '';
  String _uid = '';
  StreamSubscription<BoxEvent>? _sub;
  final Map<String, Timer> _timers = {};

  /// Dấu vân tay (JSON) của dữ liệu cuối cùng đã khớp với Firestore.
  /// Dùng để bỏ qua các sự kiện Hive do chính việc kéo dữ liệu về gây ra.
  final Map<String, String> _known = {};

  /// Các nhóm có thay đổi chưa đẩy lên được (mất mạng, đóng tab...).
  /// Lưu trong Hive: lần mở sau dữ liệu trên máy được ưu tiên, không bị bản cũ trên Firestore ghi đè.
  final Set<String> _dirty = {};

  Future<void> start() async {
    await stop();
    final username = AuthService.instance.currentUsername;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (username == null || uid == null) return;

    _user = username.toLowerCase();
    _uid = uid;
    final saved = _box.get('SYNC_DIRTY_$_user');
    if (saved is List) _dirty.addAll(saved.map((e) => '$e'));

    await Future.wait(_items.map(_reconcile));
    _sub = _box.watch().listen(_onEvent);
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    final pending = [
      for (final item in _items)
        if (_timers.containsKey(item.name)) item,
    ];
    await Future.wait(pending.map(_push));
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _known.clear();
    _dirty.clear();
    _user = '';
    _uid = '';
  }

  DocumentReference<_Json> _docOf(_Item item) => FirebaseFirestore.instance
      .collection('users')
      .doc(_uid)
      .collection('data')
      .doc(item.name);

  String _fingerprint(_Item item) => jsonEncode(item.read(_box, _user));

  Future<void> _reconcile(_Item item) async {
    try {
      if (_dirty.contains(item.name)) {
        await _push(item);
        return;
      }
      final snap = await _docOf(item).get().timeout(_netTimeout);
      final data = snap.data();
      if (data != null) {
        await item.write(_box, _user, data);
        _known[item.name] = _fingerprint(item);
      } else if (item.read(_box, _user) == null) {
        _known[item.name] = _fingerprint(item);
      } else {
        await _push(item);
      }
    } catch (e) {
      debugPrint('Không kéo được "${item.name}" từ Firestore: $e');
    }
  }

  void _onEvent(BoxEvent event) {
    for (final item in _items) {
      if (item.keys(_user).contains(event.key)) _changed(item);
    }
  }

  void _changed(_Item item) {
    if (_fingerprint(item) == _known[item.name]) return;
    _dirty.add(item.name);
    _box.put('SYNC_DIRTY_$_user', _dirty.toList());
    _timers[item.name]?.cancel();
    _timers[item.name] = Timer(_pushDelay, () => _push(item));
  }

  Future<void> _push(_Item item) async {
    _timers.remove(item.name)?.cancel();
    final user = _user;
    if (user.isEmpty) return;

    final data = item.read(_box, user);
    final fingerprint = jsonEncode(data);
    if (fingerprint != _known[item.name]) {
      try {
        final ref = _docOf(item);
        if (data == null) {
          await ref.delete().timeout(_netTimeout);
        } else {
          await ref
              .set({...data, 'updatedAt': FieldValue.serverTimestamp()})
              .timeout(_netTimeout);
        }
      } catch (e) {
        debugPrint('Không đẩy được "${item.name}" lên Firestore: $e');
        return;
      }
      if (_user == user) _known[item.name] = fingerprint;
    }

    // đang chờ mạng mà dữ liệu lại đổi tiếp thì giữ cờ, lần đẩy sau sẽ gỡ
    if (_user == user && _fingerprint(item) == fingerprint) {
      _dirty.remove(item.name);
      _box.put('SYNC_DIRTY_$user', _dirty.toList());
    }
  }
}

// Firestore không cho mảng lồng mảng, nên mỗi việc được lưu thành một map.

_Json _taskToMap(List t) => {
      'n': t.isNotEmpty ? '${t[0]}' : '',
      'd': t.length > 1 && t[1] == true,
      'c': t.length > 2 ? t[2] : null,
      's': t.length > 3 ? t[3] : null,
      'f': t.length > 4 ? t[4] : null,
    };

List<dynamic> _taskFromMap(Map m) => <dynamic>[
      '${m['n'] ?? ''}',
      m['d'] == true,
      m['c'] is String ? m['c'] : 'Ngày',
      m['s'] is String ? m['s'] : _today(),
      m['f'] is String ? m['f'] : null,
    ];

String _today() {
  final n = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(n.day)}/${two(n.month)}/${n.year}';
}

_Json? _readTasks(Box box, String u) {
  final raw = box.get('TODOLIST_$u');
  if (raw is! List) return null;
  return {
    'items': [
      for (final t in raw)
        if (t is List) _taskToMap(t),
    ],
  };
}

Future<void> _writeTasks(Box box, String u, _Json data) {
  final items = data['items'];
  final list = <dynamic>[
    if (items is List)
      for (final m in items)
        if (m is Map) _taskFromMap(m),
  ];
  return box.put('TODOLIST_$u', list);
}

_Json? _readFocus(Box box, String u) {
  final selected = box.get('FOCUS_SOUND_$u');
  if (selected is! String) return null;
  return {'selected': selected};
}

Future<void> _writeFocus(Box box, String u, _Json data) async {
  final selected = data['selected'];
  if (selected is String) {
    await box.put('FOCUS_SOUND_$u', selected);
  } else {
    await box.delete('FOCUS_SOUND_$u');
  }
}

// Ảnh đại diện đã được thu về 256 px nên chỉ vài chục KB, lưu thẳng dạng base64 trong Firestore.

_Json? _readAvatar(Box box, String u) {
  final raw = box.get('AVATAR_$u');
  Uint8List? bytes;
  if (raw is Uint8List) {
    bytes = raw;
  } else if (raw is List) {
    bytes = Uint8List.fromList(List<int>.from(raw));
  }
  if (bytes == null || bytes.isEmpty) return null;
  return {'b64': base64Encode(bytes)};
}

Future<void> _writeAvatar(Box box, String u, _Json data) async {
  final b64 = data['b64'];
  if (b64 is! String) return;
  await box.put('AVATAR_$u', base64Decode(b64));
}

_Json? _readSettings(Box box, String u) {
  final theme = box.get('APP_COLOR_THEME');
  final vi = box.get('IS_VIETNAMESE');
  if (theme == null && vi == null) return null;
  return {
    'theme': theme is String ? theme : null,
    'vi': vi is bool ? vi : null,
  };
}

Future<void> _writeSettings(Box box, String u, _Json data) async {
  final theme = data['theme'];
  final vi = data['vi'];
  if (theme is String) await box.put('APP_COLOR_THEME', theme);
  if (vi is bool) await box.put('IS_VIETNAMESE', vi);
}