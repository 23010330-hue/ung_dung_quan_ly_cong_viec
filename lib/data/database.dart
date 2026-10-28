import 'package:hive_flutter/hive_flutter.dart';
import 'package:todoapp/services/auth_service.dart';

class ToDoDaTaBase {
  List toDoList = [];
  final _myBox = Hive.box('box_v3');

  /// Mỗi tài khoản có một danh sách việc riêng: TODOLIST_<tên đăng nhập>.
  String get _listKey {
    final user = AuthService.instance.currentUsername;
    return user == null ? 'TODOLIST' : 'TODOLIST_${user.toLowerCase()}';
  }

  /// Tài khoản hiện tại đã có dữ liệu lưu chưa.
  bool get hasSavedData => _myBox.get(_listKey) != null;

  String getToday() {
    return formatDate(DateTime.now());
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  DateTime? parseDate(String date) {
    try {
      final parts = date.split('/');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      return null;
    }
  }

  bool isSameWeek(String date1, String date2) {
    final d1 = parseDate(date1);
    final d2 = parseDate(date2);
    if (d1 == null || d2 == null) return false;
    final monday1 = DateTime(d1.year, d1.month, d1.day - (d1.weekday - 1));
    final monday2 = DateTime(d2.year, d2.month, d2.day - (d2.weekday - 1));
    return monday1.year == monday2.year &&
        monday1.month == monday2.month &&
        monday1.day == monday2.day;
  }

  bool isSameMonth(String taskDate, String viewDate) {
    if (taskDate.length < 10 || viewDate.length < 10) return false;
    return taskDate.substring(3) == viewDate.substring(3);
  }

  bool isSameYear(String taskDate, String viewDate) {
    if (taskDate.length < 10 || viewDate.length < 10) return false;
    return taskDate.substring(6) == viewDate.substring(6);
  }

  bool taskMatchesPeriod(String taskCategory, String taskDate, String viewDate) {
    switch (taskCategory) {
      case 'Ngày':
        return taskDate == viewDate;
      case 'Tuần':
        return isSameWeek(taskDate, viewDate);
      case 'Tháng':
        return isSameMonth(taskDate, viewDate);
      case 'Năm':
        return isSameYear(taskDate, viewDate);
      default:
        return false;
    }
  }

  /// Tài khoản mới bắt đầu với danh sách trống.
  void createInitialData() {
    toDoList = [];
  }

  void ensureTaskFields(List task) {
    final today = getToday();
    if (task.length < 3) task.add("Ngày");
    if (task.length < 4) task.add(today);
    if (task.length < 5) {
      task.add(task[1] == true ? today : null);
    }
  }

  String? getCompletedDate(List task) {
    if (task.length < 5 || task[4] == null) return null;
    return task[4] as String;
  }

  void setTaskCompleted(List task, bool completed) {
    ensureTaskFields(task);
    task[1] = completed;
    task[4] = completed ? getToday() : null;
  }

  List<int> getCompletedTaskIndices() {
    final indices = <int>[];
    for (int i = 0; i < toDoList.length; i++) {
      ensureTaskFields(toDoList[i]);
      if (toDoList[i][1] == true) {
        indices.add(i);
      }
    }
    indices.sort((a, b) {
      final dateA = parseDate(getCompletedDate(toDoList[a]) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = parseDate(getCompletedDate(toDoList[b]) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });
    return indices;
  }

  void loadData() {
    toDoList = _myBox.get(_listKey);
    for (int i = 0; i < toDoList.length; i++) {
      ensureTaskFields(toDoList[i]);
    }
  }

  void updateData() {
    _myBox.put(_listKey, toDoList);
  }
}