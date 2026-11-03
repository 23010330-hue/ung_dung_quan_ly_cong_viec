
class TaskItem {
  static const List<String> categories = ['Ngày', 'Tuần', 'Tháng', 'Năm'];

  final String name;
  final bool completed;
  final String category;
  final String scheduledDate;
  final String? completedDate;

  const TaskItem({
    required this.name,
    this.completed = false,
    this.category = 'Ngày',
    required this.scheduledDate,
    this.completedDate,
  });

  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static String today() {
    return formatDate(DateTime.now());
  }

  
  static TaskItem fromList(List raw) {
    String name = '';
    if (raw.isNotEmpty) {
      name = '${raw[0]}';
    }

    bool completed = false;
    if (raw.length > 1 && raw[1] == true) {
      completed = true;
    }

    String category = 'Ngày';
    if (raw.length > 2 && categories.contains(raw[2])) {
      category = raw[2];
    }

    String scheduledDate = today();
    if (raw.length > 3 && raw[3] is String) {
      scheduledDate = raw[3];
    }

   
    String? completedDate;
    if (completed) {
      completedDate = scheduledDate;
      if (raw.length > 4 && raw[4] is String) {
        completedDate = raw[4];
      }
    }

    return TaskItem(
      name: name,
      completed: completed,
      category: category,
      scheduledDate: scheduledDate,
      completedDate: completedDate,
    );
  }

  List<dynamic> toList() {
    return [name, completed, category, scheduledDate, completedDate];
  }

  
  static TaskItem fromMap(Map map) {
    final name = _readField(map, 'name', 'n') ?? '';
    final completed = _readField(map, 'completed', 'd') == true;
    final category = _readField(map, 'category', 'c');
    final scheduledDate = _readField(map, 'scheduledDate', 's');
    final completedDate = _readField(map, 'completedDate', 'f');
    return fromList([name, completed, category, scheduledDate, completedDate]);
  }

  static dynamic _readField(Map map, String longName, String shortName) {
    if (map.containsKey(longName)) {
      return map[longName];
    }
    return map[shortName];
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'completed': completed,
      'category': category,
      'scheduledDate': scheduledDate,
      'completedDate': completedDate,
    };
  }
}


class TaskListDocument {
  final List<TaskItem> items;

  const TaskListDocument(this.items);

  
  static TaskListDocument fromLists(List raw) {
    final items = <TaskItem>[];
    for (final row in raw) {
      if (row is List) {
        items.add(TaskItem.fromList(row));
      }
    }
    return TaskListDocument(items);
  }

  static TaskListDocument fromMap(Map map) {
    final items = <TaskItem>[];
    final raw = map['items'];
    if (raw is List) {
      for (final row in raw) {
        if (row is Map) {
          items.add(TaskItem.fromMap(row));
        }
      }
    }
    return TaskListDocument(items);
  }

  Map<String, dynamic> toMap() {
    final rows = <Map<String, dynamic>>[];
    for (final item in items) {
      rows.add(item.toMap());
    }
    return {'items': rows};
  }

  List<List<dynamic>> toLists() {
    final rows = <List<dynamic>>[];
    for (final item in items) {
      rows.add(item.toList());
    }
    return rows;
  }
}
