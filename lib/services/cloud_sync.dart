import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todoapp/models/sync_documents.dart';
import 'package:todoapp/models/task_item.dart';
import 'package:todoapp/services/auth_service.dart';

/// Đồng bộ dữ liệu của tài khoản đang đăng nhập giữa Hive (trên máy) và Firestore.
class CloudSync {
  CloudSync._();

  static final CloudSync instance = CloudSync._();

  static const Duration _pushDelay = Duration(seconds: 2);
  static const Duration _netTimeout = Duration(seconds: 6);
  static const List<String> _groups = ['tasks', 'focus', 'avatar', 'settings'];

  Box get _box => Hive.box('box_v3');

  String _user = '';
  String _uid = '';
  StreamSubscription<BoxEvent>? _subscription;

 
  final Map<String, Timer> _timers = {};
  final Map<String, String> _known = {};
  final Set<String> _dirty = {};

 

  Future<void> start() async {
    await stop();

    final username = AuthService.instance.currentUsername;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (username == null || uid == null) {
      return;
    }

    _user = username.toLowerCase();
    _uid = uid;

    final saved = _box.get('SYNC_DIRTY_$_user');
    if (saved is List) {
      for (final name in saved) {
        _dirty.add('$name');
      }
    }

    final jobs = <Future<void>>[];
    for (final group in _groups) {
      jobs.add(_reconcile(group));
    }
    await Future.wait(jobs);

    _subscription = _box.watch().listen(_onHiveEvent);
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;

    final jobs = <Future<void>>[];
    for (final group in _groups) {
      if (_timers.containsKey(group)) {
        jobs.add(_push(group));
      }
    }
    await Future.wait(jobs);

    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _known.clear();
    _dirty.clear();
    _user = '';
    _uid = '';
  }

  DocumentReference<Map<String, dynamic>> _docOf(String group) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('data')
        .doc(group);
  }

  String _fingerprint(String group) {
    return jsonEncode(_readFromHive(group, _user));
  }

  Future<void> _reconcile(String group) async {
    try {
      if (_dirty.contains(group)) {
        await _push(group);
        return;
      }

      final snapshot = await _docOf(group).get().timeout(_netTimeout);
      final data = snapshot.data();
      if (data != null) {
        await _writeToHive(group, _user, data);
        _known[group] = _fingerprint(group);
      } else if (_readFromHive(group, _user) == null) {
        _known[group] = _fingerprint(group);
      } else {
        await _push(group);
      }
    } catch (e) {
      debugPrint('Không kéo được "$group" từ Firestore: $e');
    }
  }

  void _onHiveEvent(BoxEvent event) {
    for (final group in _groups) {
      if (_hiveKeys(group, _user).contains(event.key)) {
        _onChanged(group);
      }
    }
  }

  void _onChanged(String group) {
    if (_fingerprint(group) == _known[group]) {
      return;
    }

    _dirty.add(group);
    _box.put('SYNC_DIRTY_$_user', _dirty.toList());
    _timers[group]?.cancel();
    _timers[group] = Timer(_pushDelay, () {
      _push(group);
    });
  }

  Future<void> _push(String group) async {
    _timers.remove(group)?.cancel();

    final user = _user;
    if (user.isEmpty) {
      return;
    }

    final data = _readFromHive(group, user);
    final fingerprint = jsonEncode(data);

    if (fingerprint != _known[group]) {
      try {
        final ref = _docOf(group);
        if (data == null) {
          await ref.delete().timeout(_netTimeout);
        } else {
          final toSave = Map<String, dynamic>.from(data);
          toSave['updatedAt'] = FieldValue.serverTimestamp();
          await ref.set(toSave).timeout(_netTimeout);
        }
      } catch (e) {
        debugPrint('Không đẩy được "$group" lên Firestore: $e');
        return;
      }
      if (_user == user) {
        _known[group] = fingerprint;
      }
    }

    if (_user == user && _fingerprint(group) == fingerprint) {
      _dirty.remove(group);
      _box.put('SYNC_DIRTY_$user', _dirty.toList());
    }
  }


  List<String> _hiveKeys(String group, String user) {
    if (group == 'tasks') return ['TODOLIST_$user'];
    if (group == 'focus') return ['FOCUS_SOUND_$user'];
    if (group == 'avatar') return ['AVATAR_$user'];
    return ['APP_COLOR_THEME', 'IS_VIETNAMESE'];
  }

  Map<String, dynamic>? _readFromHive(String group, String user) {
    if (group == 'tasks') return _readTasks(user);
    if (group == 'focus') return _readFocus(user);
    if (group == 'avatar') return _readAvatar(user);
    return _readSettings();
  }


  Future<void> _writeToHive(String group, String user, Map<String, dynamic> data) async {
    if (group == 'tasks') {
      await _writeTasks(user, data);
    } else if (group == 'focus') {
      await _writeFocus(user, data);
    } else if (group == 'avatar') {
      await _writeAvatar(user, data);
    } else {
      await _writeSettings(data);
    }
  }


  Map<String, dynamic>? _readTasks(String user) {
    final raw = _box.get('TODOLIST_$user');
    if (raw is! List) {
      return null;
    }
    return TaskListDocument.fromLists(raw).toMap();
  }

  Future<void> _writeTasks(String user, Map<String, dynamic> data) async {
    final document = TaskListDocument.fromMap(data);
    await _box.put('TODOLIST_$user', document.toLists());
  }

  Map<String, dynamic>? _readFocus(String user) {
    final selected = _box.get('FOCUS_SOUND_$user');
    if (selected is! String) {
      return null;
    }
    return FocusPreference(selected).toMap();
  }

  Future<void> _writeFocus(String user, Map<String, dynamic> data) async {
    final preference = FocusPreference.fromMap(data);
    if (preference.selected.isEmpty) {
      await _box.delete('FOCUS_SOUND_$user');
    } else {
      await _box.put('FOCUS_SOUND_$user', preference.selected);
    }
  }

  // Ảnh đại diện đã được thu về 256 px nên chỉ vài chục KB, lưu thẳng dạng base64 trong Firestore.

  Map<String, dynamic>? _readAvatar(String user) {
    final raw = _box.get('AVATAR_$user');
    Uint8List? bytes;
    if (raw is Uint8List) {
      bytes = raw;
    } else if (raw is List) {
      bytes = Uint8List.fromList(List<int>.from(raw));
    }
    if (bytes == null || bytes.isEmpty) {
      return null;
    }
    return AvatarDocument(bytes).toMap();
  }

  Future<void> _writeAvatar(String user, Map<String, dynamic> data) async {
    final avatar = AvatarDocument.fromMap(data);
    if (avatar == null) {
      return;
    }
    await _box.put('AVATAR_$user', avatar.bytes);
  }

  // Màu giao diện và ngôn ngữ là khóa chung của máy, nhưng đi theo tài khoản.

  Map<String, dynamic>? _readSettings() {
    final theme = _box.get('APP_COLOR_THEME');
    final vi = _box.get('IS_VIETNAMESE');
    if (theme == null && vi == null) {
      return null;
    }

    String? themeId;
    if (theme is String) {
      themeId = theme;
    }
    bool? vietnamese;
    if (vi is bool) {
      vietnamese = vi;
    }
    return AppSettings(theme: themeId, vietnamese: vietnamese).toMap();
  }

  Future<void> _writeSettings(Map<String, dynamic> data) async {
    final settings = AppSettings.fromMap(data);
    if (settings.theme != null) {
      await _box.put('APP_COLOR_THEME', settings.theme);
    }
    if (settings.vietnamese != null) {
      await _box.put('IS_VIETNAMESE', settings.vietnamese);
    }
  }
}
