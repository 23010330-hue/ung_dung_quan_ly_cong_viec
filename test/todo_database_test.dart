import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todoapp/data/database.dart';

import 'helpers/test_setup.dart';

/// Tên của tất cả các việc trong danh sách, theo thứ tự.
List<String> namesOf(ToDoDaTaBase db) {
  final names = <String>[];
  for (final task in db.toDoList) {
    names.add(task[0]);
  }
  return names;
}

void main() {
  late ToDoDaTaBase db;

  setUpAll(setUpTestStorage);
  setUp(() async {
    await resetTestStorage();
    db = ToDoDaTaBase();
    db.createInitialData();
  });

  group('Ngày tháng', () {
    test('formatDate thêm số 0 và parseDate đọc lại đúng', () {
      expect(db.formatDate(DateTime(2026, 1, 5)), '05/01/2026');
      expect(db.parseDate('05/01/2026'), DateTime(2026, 1, 5));
    });

    test('parseDate trả về null khi sai định dạng', () {
      expect(db.parseDate(''), isNull);
      expect(db.parseDate('2026-01-05'), isNull);
      expect(db.parseDate('aa/bb/cccc'), isNull);
    });

    test('isSameWeek: thứ hai và chủ nhật cùng tuần, thứ hai kế tiếp thì không', () {
      expect(db.isSameWeek('02/11/2026', '08/11/2026'), isTrue);
      expect(db.isSameWeek('02/11/2026', '09/11/2026'), isFalse);
      expect(db.isSameWeek('rác', '08/11/2026'), isFalse);
    });

    test('isSameMonth và isSameYear', () {
      expect(db.isSameMonth('01/11/2026', '30/11/2026'), isTrue);
      expect(db.isSameMonth('01/11/2026', '01/12/2026'), isFalse);
      expect(db.isSameYear('01/01/2026', '31/12/2026'), isTrue);
      expect(db.isSameYear('01/01/2026', '01/01/2027'), isFalse);
      expect(db.isSameMonth('', '01/11/2026'), isFalse);
    });

    test('taskMatchesPeriod theo từng phân loại', () {
      const view = '10/11/2026';
      expect(db.taskMatchesPeriod('Ngày', '10/11/2026', view), isTrue);
      expect(db.taskMatchesPeriod('Ngày', '11/11/2026', view), isFalse);
      expect(db.taskMatchesPeriod('Tuần', '09/11/2026', view), isTrue);
      expect(db.taskMatchesPeriod('Tháng', '01/11/2026', view), isTrue);
      expect(db.taskMatchesPeriod('Năm', '31/12/2026', view), isTrue);
      expect(db.taskMatchesPeriod('Khác', '10/11/2026', view), isFalse);
    });
  });

  group('Thêm việc (US05)', () {
    test('thêm việc hợp lệ', () {
      expect(db.addTask('Học Flutter', 'Ngày', '10/11/2026'), isTrue);
      expect(db.toDoList.length, 1);
      expect(db.toDoList[0], ['Học Flutter', false, 'Ngày', '10/11/2026', null]);
    });

    test('tên có khoảng trắng hai đầu được cắt bớt', () {
      db.addTask('  Đọc sách  ', 'Tuần', '10/11/2026');
      expect(db.toDoList[0][0], 'Đọc sách');
    });

    test('tên trống không được thêm', () {
      expect(db.addTask('   ', 'Ngày', '10/11/2026'), isFalse);
      expect(db.toDoList, isEmpty);
    });

    test('updateData ghi xuống Hive và loadData đọc lại đúng', () async {
      db.addTask('A', 'Ngày', '10/11/2026');
      await db.updateData();
      final other = ToDoDaTaBase()..loadData();
      expect(other.toDoList.length, 1);
      expect(other.toDoList[0][0], 'A');
    });
  });

  group('Sửa việc (US06)', () {
    setUp(() => db.addTask('Cũ', 'Ngày', '10/11/2026'));

    test('đổi tên, phân loại, ngày nhưng giữ trạng thái hoàn thành', () {
      db.setTaskCompleted(db.toDoList[0] as List, true);
      expect(
        db.editTask(0, name: 'Mới', category: 'Tháng', date: '01/12/2026'),
        isTrue,
      );
      final task = db.toDoList[0] as List;
      expect(task[0], 'Mới');
      expect(task[2], 'Tháng');
      expect(task[3], '01/12/2026');
      expect(task[1], isTrue);
    });

    test('vị trí sai hoặc tên trống thì không sửa', () {
      expect(db.editTask(5, name: 'X', category: 'Ngày', date: 'd'), isFalse);
      expect(db.editTask(-1, name: 'X', category: 'Ngày', date: 'd'), isFalse);
      expect(db.editTask(0, name: ' ', category: 'Ngày', date: 'd'), isFalse);
      expect(db.toDoList[0][0], 'Cũ');
    });
  });

  group('Xóa và hoàn tác (US08, US09)', () {
    setUp(() {
      db.addTask('A', 'Ngày', '10/11/2026');
      db.addTask('B', 'Ngày', '10/11/2026');
      db.addTask('C', 'Ngày', '10/11/2026');
    });

    test('removeTask trả về việc đã xóa', () {
      final removed = db.removeTask(1);
      expect(removed?[0], 'B');
      expect(namesOf(db), ['A', 'C']);
    });

    test('removeTask với vị trí sai trả về null và không đổi danh sách', () {
      expect(db.removeTask(9), isNull);
      expect(db.removeTask(-1), isNull);
      expect(db.toDoList.length, 3);
    });

    test('restoreTask đặt lại đúng chỗ cũ', () {
      final removed = db.removeTask(1)!;
      db.restoreTask(1, removed);
      expect(namesOf(db), ['A', 'B', 'C']);
    });

    test('restoreTask khi danh sách đã ngắn đi thì đặt ở cuối', () {
      final removed = db.removeTask(2)!;
      db.removeTask(1);
      db.restoreTask(2, removed);
      expect(namesOf(db), ['A', 'C']);
    });
  });

  group('Hoàn thành việc (US07)', () {
    test('tích hoàn thành ghi ngày hôm nay, bỏ tích thì xóa ngày', () {
      db.addTask('A', 'Ngày', db.getToday());
      final task = db.toDoList[0] as List;
      db.setTaskCompleted(task, true);
      expect(task[1], isTrue);
      expect(db.getCompletedDate(task), db.getToday());
      db.setTaskCompleted(task, false);
      expect(task[1], isFalse);
      expect(db.getCompletedDate(task), isNull);
    });

    test('ensureTaskFields bổ sung các trường còn thiếu của dữ liệu cũ', () {
      final old = <dynamic>['Việc cũ', true];
      db.ensureTaskFields(old);
      expect(old.length, 5);
      expect(old[2], 'Ngày');
      expect(old[4], db.getToday());
    });
  });

  group('Tìm kiếm, lọc, xem theo ngày (US10, US11, US12)', () {
    bool show(
      String name,
      String category,
      String date, {
      bool completed = false,
      String view = '10/11/2026',
      String filter = 'Tất cả',
      String query = '',
    }) =>
        db.shouldShowTask(
          name: name,
          category: category,
          date: date,
          completed: completed,
          viewDate: view,
          filter: filter,
          query: query,
        );

    test('bộ lọc Tất cả chỉ hiện việc chưa xong trong khoảng thời gian đang xem', () {
      expect(show('A', 'Ngày', '10/11/2026'), isTrue);
      expect(show('A', 'Ngày', '10/11/2026', completed: true), isFalse);
      expect(show('A', 'Ngày', '11/11/2026'), isFalse);
    });

    test('xem theo ngày khác: chỉ hiện việc thuộc ngày đó', () {
      expect(show('A', 'Ngày', '20/11/2026', view: '20/11/2026'), isTrue);
      expect(show('A', 'Ngày', '10/11/2026', view: '20/11/2026'), isFalse);
    });

    test('bộ lọc theo phân loại hiện đúng phân loại đó', () {
      expect(show('A', 'Tuần', '09/11/2026', filter: 'Tuần'), isTrue);
      expect(show('A', 'Ngày', '10/11/2026', filter: 'Tuần'), isFalse);
    });

    test('tìm kiếm không phân biệt hoa thường và bỏ qua ngày', () {
      expect(show('Học Flutter', 'Ngày', '01/01/2020', query: 'flutter'), isTrue);
      expect(show('Học Flutter', 'Ngày', '10/11/2026', query: 'java'), isFalse);
    });

    test('tìm kiếm không hiện việc đã xong', () {
      expect(show('Học', 'Ngày', '10/11/2026', completed: true, query: 'học'), isFalse);
    });
  });

  group('Lịch sử việc đã hoàn thành (US13)', () {
    test('getCompletedTaskIndices xếp việc mới hoàn thành lên trước', () {
      db.toDoList = [
        ['A', true, 'Ngày', '01/11/2026', '03/11/2026'],
        ['B', false, 'Ngày', '01/11/2026', null],
        ['C', true, 'Ngày', '01/11/2026', '05/11/2026'],
        ['D', true, 'Ngày', '01/11/2026', '04/11/2026'],
      ];
      expect(db.getCompletedTaskIndices(), [2, 3, 0]);
    });

    test('danh sách trống cho lịch sử trống', () {
      expect(db.getCompletedTaskIndices(), isEmpty);
    });
  });

  group('Thống kê (US16, US17)', () {
    setUp(() {
      final today = db.getToday();
      db.toDoList = [
        ['A', true, 'Ngày', today, today],
        ['B', false, 'Ngày', today, null],
        ['C', true, 'Tuần', today, today],
      ];
    });

    test('tổng, đã xong, chưa xong và phần trăm', () {
      expect(db.totalCount, 3);
      expect(db.doneCount, 2);
      expect(db.pendingCount, 1);
      expect(db.completionPercent, 67);
    });

    test('danh sách trống cho 0%', () {
      db.toDoList = [];
      expect(db.completionPercent, 0);
    });

    test('completedCountOn đếm đúng theo ngày hoàn thành', () {
      expect(db.completedCountOn(DateTime.now()), 2);
      expect(db.completedCountOn(DateTime.now().subtract(const Duration(days: 1))), 0);
    });

    test('categoryProgress theo từng phân loại', () {
      final day = db.categoryProgress('Ngày');
      expect(day.done, 1);
      expect(day.total, 2);
      expect(day.ratio, 0.5);
      expect(db.categoryProgress('Năm').ratio, 0.0);
    });
  });

  group('Bắt lỗi dữ liệu hỏng (8a)', () {
    test('loadData bỏ phần tử hỏng thay vì báo lỗi', () async {
      await Hive.box('box_v3').put('TODOLIST', [
        ['A', false, 'Ngày', '01/01/2026', null],
        'hỏng',
        7,
      ]);
      final other = ToDoDaTaBase()..loadData();
      expect(other.toDoList.length, 1);
    });

    test('loadData khi dữ liệu không phải danh sách cho danh sách trống', () async {
      await Hive.box('box_v3').put('TODOLIST', 'không phải danh sách');
      final other = ToDoDaTaBase()..loadData();
      expect(other.toDoList, isEmpty);
    });

    test('hasSavedData sai khi tài khoản chưa có dữ liệu', () {
      expect(ToDoDaTaBase().hasSavedData, isFalse);
    });
  });
}
