import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todoapp/data/database.dart';
import 'package:todoapp/focus/focus_audio.dart';
import 'package:todoapp/focus/focus_page.dart';
import 'package:todoapp/pages/login_page.dart';
import 'package:todoapp/pages/register_page.dart';
import 'package:todoapp/pages/schedule_page.dart';
import 'package:todoapp/pages/stats_page.dart';
import 'package:todoapp/theme/app_colors.dart';
import 'package:todoapp/until/auth_widgets.dart';
import 'package:todoapp/until/main_bottom_bar.dart';

import 'helpers/test_setup.dart';

/// Màn hình điện thoại 390 x 844 (điểm logic), tỉ lệ 3x.
void useMobileScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

String keepText(String s) => s;

void main() {
  final theme = AppColorTheme.fromId(null);

  setUpAll(setUpTestStorage);
  setUp(resetTestStorage);

  group('Trang đăng nhập và đăng ký (US01, US02)', () {
    testWidgets('đăng nhập để trống thì báo lỗi từng ô', (tester) async {
      useMobileScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.ensureVisible(find.byType(AuthPrimaryButton));
      await tester.tap(find.byType(AuthPrimaryButton));
      await tester.pump();
      expect(find.text('Vui lòng nhập tên đăng nhập hoặc email'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    });

    testWidgets('đăng nhập sai thông tin thì hiện thông báo lỗi', (tester) async {
      useMobileScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'nobody');
      await tester.enterText(fields.at(1), 'matkhau');
      await tester.ensureVisible(find.byType(AuthPrimaryButton));
      await tester.tap(find.byType(AuthPrimaryButton));
      await tester.pumpAndSettle();
      expect(find.text('Sai tên đăng nhập hoặc mật khẩu'), findsOneWidget);
    });

    testWidgets('bấm "Tạo tài khoản" mở trang đăng ký', (tester) async {
      useMobileScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.ensureVisible(find.text('Tạo tài khoản'));
      await tester.tap(find.text('Tạo tài khoản'));
      await tester.pumpAndSettle();
      expect(find.text('Xác nhận mật khẩu'), findsOneWidget);
    });

    testWidgets('bấm "Quên mật khẩu?" mở hộp thoại', (tester) async {
      useMobileScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.ensureVisible(find.text('Quên mật khẩu?'));
      await tester.tap(find.text('Quên mật khẩu?'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('đăng ký: tên quá ngắn và mật khẩu xác nhận không khớp', (tester) async {
      useMobileScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'a');
      await tester.enterText(fields.at(1), 'a@b.com');
      await tester.enterText(fields.at(2), '123456');
      await tester.enterText(fields.at(3), '654321');
      await tester.ensureVisible(find.byType(AuthPrimaryButton));
      await tester.tap(find.byType(AuthPrimaryButton));
      await tester.pump();
      expect(find.text('Tên đăng nhập dài từ 3 đến 20 ký tự'), findsOneWidget);
      expect(find.text('Mật khẩu xác nhận không khớp'), findsOneWidget);
    });
  });

  group('Thanh điều hướng dưới (chuyển giữa các chế độ)', () {
    testWidgets('hiện 3 mục và nút giữa; bấm Thống kê thì báo đúng tab', (tester) async {
      useMobileScreen(tester);
      AppTab? picked;
      var centerTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MainBottomBar(
              current: AppTab.schedule,
              pickerOpen: false,
              colorTheme: theme,
              translate: keepText,
              onTabSelected: (t) => picked = t,
              onCenterTap: () => centerTaps++,
            ),
          ),
        ),
      );
      expect(AppTab.values.length, 4);
      expect(find.text('Thống kê'), findsOneWidget);
      expect(find.text('Tài khoản'), findsOneWidget);
      expect(find.text('Đặt lịch'), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);

      await tester.tap(find.text('Thống kê'));
      expect(picked, AppTab.stats);
      await tester.tap(find.text('Tài khoản'));
      expect(picked, AppTab.account);
      await tester.tap(find.byIcon(Icons.home));
      expect(centerTaps, 1);
    });

    testWidgets('nhãn giữa đổi thành Tập trung khi đang ở chế độ tập trung', (tester) async {
      useMobileScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MainBottomBar(
              current: AppTab.focus,
              pickerOpen: false,
              colorTheme: theme,
              translate: keepText,
              onTabSelected: (_) {},
              onCenterTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('Tập trung'), findsOneWidget);
    });

    testWidgets('lớp chọn chế độ: mở thì chọn được, đóng thì không', (tester) async {
      useMobileScreen(tester);
      AppTab? picked;
      Widget overlay(bool open) => MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(
                    child: ModePickerOverlay(
                      open: open,
                      current: AppTab.schedule,
                      colorTheme: theme,
                      translate: keepText,
                      onSelect: (t) => picked = t,
                      onDismiss: () {},
                    ),
                  ),
                ],
              ),
            ),
          );

      await tester.pumpWidget(overlay(false));
      await tester.tap(find.text('Tập trung'), warnIfMissed: false);
      expect(picked, isNull);

      await tester.pumpWidget(overlay(true));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tập trung'));
      expect(picked, AppTab.focus);
    });
  });

  group('Trang Đặt lịch (US05, US07)', () {
    Future<ToDoDaTaBase> openSchedule(WidgetTester tester) async {
      useMobileScreen(tester);
      final db = ToDoDaTaBase()..createInitialData();
      await tester.pumpWidget(
        MaterialApp(
          home: SchedulePage(db: db, translate: keepText, colorTheme: theme),
        ),
      );
      return db;
    }

    testWidgets('danh sách trống hiện lời nhắc', (tester) async {
      await openSchedule(tester);
      expect(find.text('Chưa có việc nào'), findsOneWidget);
    });

    testWidgets('thêm việc qua hộp thoại thì việc hiện trong danh sách', (tester) async {
      final db = await openSchedule(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Học Flutter');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(db.toDoList.length, 1);
      expect(find.text('Học Flutter'), findsOneWidget);
    });

    testWidgets('lưu với tên trống thì không thêm gì', (tester) async {
      final db = await openSchedule(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(db.toDoList, isEmpty);
    });

    testWidgets('tích ô hoàn thành thì việc đổi trạng thái và biến khỏi danh sách', (tester) async {
      final db = await openSchedule(tester);
      db.addTask('Đọc sách', 'Ngày', db.getToday());
      await tester.pumpWidget(
        MaterialApp(
          home: SchedulePage(db: db, translate: keepText, colorTheme: theme),
        ),
      );
      expect(find.text('Đọc sách'), findsOneWidget);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(db.toDoList[0][1], isTrue);
      expect(find.text('Đọc sách'), findsNothing);
    });
  });

  group('Trang Thống kê (US16)', () {
    testWidgets('hiện đúng tổng, đã xong, chưa xong và phần trăm', (tester) async {
      useMobileScreen(tester);
      final db = ToDoDaTaBase();
      final today = db.getToday();
      db.toDoList = [
        ['A', true, 'Ngày', today, today],
        ['B', false, 'Ngày', today, null],
        ['C', true, 'Tuần', today, today],
      ];
      await tester.pumpWidget(
        MaterialApp(home: StatsPage(db: db, translate: keepText, colorTheme: theme)),
      );
      expect(find.text('Tổng số việc'), findsOneWidget);
      expect(find.text('67%'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget); // phân loại Ngày
      expect(find.text('1/1'), findsOneWidget); // phân loại Tuần
      expect(find.text('0/0'), findsNWidgets(2)); // Tháng, Năm
    });
  });

  group('Trang Tập trung (US18, US19)', () {
    testWidgets('hiện bốn mốc thời gian và nút Bắt đầu; chọn 90 phút', (tester) async {
      useMobileScreen(tester);
      final audio = FocusAudio();
      addTearDown(audio.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: FocusPage(colorTheme: theme, translate: keepText, audio: audio),
        ),
      );
      for (final label in ['30 phút', '60 phút', '90 phút', '120 phút']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Bắt đầu'), findsOneWidget);
      expect(find.text('Sẵn sàng'), findsOneWidget);

      await tester.tap(find.text('90 phút'));
      await tester.pump();
      final chip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '90 phút'));
      expect(chip.selected, isTrue);
    });
  });
}
