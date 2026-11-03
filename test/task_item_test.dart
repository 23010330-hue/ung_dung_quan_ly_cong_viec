import 'package:flutter_test/flutter_test.dart';
import 'package:todoapp/models/task_item.dart';

void main() {
  group('TaskItem: đổi qua lại giữa danh sách Hive và map Firestore', () {
    test('fromList đọc đủ năm phần tử', () {
      final t = TaskItem.fromList(['Học Flutter', true, 'Tuần', '05/11/2026', '06/11/2026']);
      expect(t.name, 'Học Flutter');
      expect(t.completed, isTrue);
      expect(t.category, 'Tuần');
      expect(t.scheduledDate, '05/11/2026');
      expect(t.completedDate, '06/11/2026');
    });

    test('fromList bỏ phần tử thứ 6 của dữ liệu cũ', () {
      final t = TaskItem.fromList(['A', false, 'Ngày', '01/01/2026', null, true]);
      expect(t.toList().length, 5);
      expect(t.completed, isFalse);
    });

    test('fromList thiếu phần tử thì dùng giá trị mặc định', () {
      final t = TaskItem.fromList(['Chỉ có tên']);
      expect(t.completed, isFalse);
      expect(t.category, 'Ngày');
      expect(t.scheduledDate, TaskItem.today());
      expect(t.completedDate, isNull);
    });

    test('fromList với phân loại lạ thì quay về Ngày', () {
      final t = TaskItem.fromList(['A', false, 'Thế kỷ', '01/01/2026', null]);
      expect(t.category, 'Ngày');
    });

    test('việc đã xong mà thiếu ngày hoàn thành thì lấy ngày thực hiện', () {
      final t = TaskItem.fromList(['A', true, 'Ngày', '02/03/2026']);
      expect(t.completedDate, '02/03/2026');
    });

    test('toList rồi fromList cho lại đúng việc ban đầu', () {
      const t = TaskItem(
        name: 'Đọc sách',
        completed: true,
        category: 'Tháng',
        scheduledDate: '10/10/2026',
        completedDate: '11/10/2026',
      );
      final back = TaskItem.fromList(t.toList());
      expect(back.toList(), t.toList());
    });

    test('toMap rồi fromMap cho lại đúng việc ban đầu', () {
      const t = TaskItem(name: 'Chạy bộ', scheduledDate: '10/10/2026');
      final back = TaskItem.fromMap(t.toMap());
      expect(back.toMap(), t.toMap());
    });

    test('fromMap đọc được tên trường ngắn của dữ liệu đã lưu trước đây', () {
      final t = TaskItem.fromMap({
        'n': 'Việc cũ',
        'd': true,
        'c': 'Năm',
        's': '01/01/2026',
        'f': '02/01/2026',
      });
      expect(t.name, 'Việc cũ');
      expect(t.completed, isTrue);
      expect(t.category, 'Năm');
      expect(t.completedDate, '02/01/2026');
    });

    test('fromMap với map rỗng không báo lỗi', () {
      final t = TaskItem.fromMap({});
      expect(t.name, '');
      expect(t.completed, isFalse);
    });

    test('formatDate thêm số 0 ở đầu', () {
      expect(TaskItem.formatDate(DateTime(2026, 3, 7)), '07/03/2026');
    });
  });

  group('TaskListDocument', () {
    test('fromLists bỏ phần tử không phải danh sách', () {
      final doc = TaskListDocument.fromLists([
        ['A', false, 'Ngày', '01/01/2026', null],
        'hỏng',
        42,
        ['B', true, 'Tuần', '01/01/2026', '01/01/2026'],
      ]);
      expect(doc.items.length, 2);
      expect(doc.items[0].name, 'A');
      expect(doc.items[1].name, 'B');
    });

    test('toMap rồi fromMap giữ nguyên thứ tự và nội dung', () {
      final doc = TaskListDocument.fromLists([
        ['A', false, 'Ngày', '01/01/2026', null],
        ['B', true, 'Năm', '02/02/2026', '03/02/2026'],
      ]);
      final back = TaskListDocument.fromMap(doc.toMap());
      expect(back.toMap(), doc.toMap());
      expect(back.toLists().length, 2);
    });

    test('fromMap không có trường items cho danh sách trống', () {
      expect(TaskListDocument.fromMap({}).items, isEmpty);
    });
  });
}
