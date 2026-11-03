import 'package:hive_flutter/hive_flutter.dart';
import 'package:todoapp/services/auth_service.dart';

class ToDoDaTaBase {
  List toDoList = [];
  final _myBox = Hive.box('box_v3');

  /// Mỗi tài khoản có một danh sách việc riêng
  String get _listKey {
    final user = AuthService.instance.currentUsername;
    return user == null ? 'TODOLIST' : 'TODOLIST_${user.toLowerCase()}';
  }
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

  /// Ngày hoàn thành của một việc; không có hoặc sai định dạng thì coi là ngày rất cũ.
  DateTime _completedDateOf(List task) {
    final date = parseDate(getCompletedDate(task) ?? '');
    if (date == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return date;
  }

  /// Vị trí các việc đã hoàn thành, việc hoàn thành gần nhất đứng đầu.
  List<int> getCompletedTaskIndices() {
    final indices = <int>[];
    for (int i = 0; i < toDoList.length; i++) {
      ensureTaskFields(toDoList[i]);
      if (toDoList[i][1] == true) {
        indices.add(i);
      }
    }
    indices.sort((a, b) {
      final dateA = _completedDateOf(toDoList[a]);
      final dateB = _completedDateOf(toDoList[b]);
      return dateB.compareTo(dateA);
    });
    return indices;
  }

  void loadData() {
    final raw = _myBox.get(_listKey);
    toDoList = [];
    if (raw is List) {
      for (final task in raw) {
        if (task is List) {
          toDoList.add(task);
        }
      }
    }
    for (int i = 0; i < toDoList.length; i++) {
      ensureTaskFields(toDoList[i]);
    }
  }

  Future<void> updateData() async {
    await _myBox.put(_listKey, toDoList);
  }
  bool addTask(String name, String category, String date) {
    final clean = name.trim();
    if (clean.isEmpty) return false;
    toDoList.add([clean, false, category, date, null]);
    return true;
  }
  bool editTask(
    int index, {
    required String name,
    required String category,
    required String date,
  }) {
    final clean = name.trim();
    if (index < 0 || index >= toDoList.length || clean.isEmpty) return false;
    final task = toDoList[index] as List;
    ensureTaskFields(task);
    task[0] = clean;
    task[2] = category;
    task[3] = date;
    return true;
  }
  List? removeTask(int index) {
    if (index < 0 || index >= toDoList.length) return null;
    return toDoList.removeAt(index) as List;
  }

  void restoreTask(int index, List task) {
    final at = index < 0
        ? 0
        : (index > toDoList.length ? toDoList.length : index);
    toDoList.insert(at, task);
  }
  bool shouldShowTask({
    required String name,
    required String category,
    required String date,
    required bool completed,
    required String viewDate,
    String filter = 'Tất cả',
    String query = '',
  }) {
    if (query.isNotEmpty) {
      return !completed && name.toLowerCase().contains(query.toLowerCase());
    }
    if (!taskMatchesPeriod(category, date, viewDate)) return false;
    if (filter == 'Tất cả') return !completed;
    return category == filter;
  }

  int get totalCount => toDoList.length;

  int get doneCount {
    int count = 0;
    for (final task in toDoList) {
      if (task[1] == true) {
        count++;
      }
    }
    return count;
  }

  int get pendingCount => totalCount - doneCount;

  
  int get completionPercent {
    if (totalCount == 0) {
      return 0;
    }
    return (doneCount * 100 / totalCount).round();
  }
  int completedCountOn(DateTime date) {
    final key = formatDate(date);
    int count = 0;
    for (final task in toDoList) {
      if (task[1] == true && getCompletedDate(task) == key) {
        count++;
      }
    }
    return count;
  }
  TaskProgress categoryProgress(String category) {
    int done = 0;
    int total = 0;
    for (final task in toDoList) {
      if (task[2] == category) {
        total++;
        if (task[1] == true) {
          done++;
        }
      }
    }
    return TaskProgress(done, total);
  }
}

class TaskProgress {
  final int done;
  final int total;
  const TaskProgress(this.done, this.total);

  double get ratio {
    if (total == 0) {
      return 0.0;
    }
    return done / total;
  }
}
