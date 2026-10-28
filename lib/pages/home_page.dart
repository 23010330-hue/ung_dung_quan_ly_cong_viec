import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart' show Hive;
import 'package:todoapp/data/database.dart';
import 'package:todoapp/focus/focus_page.dart';
import 'package:todoapp/pages/account_page.dart';
import 'package:todoapp/pages/coming_soon_page.dart';
import 'package:todoapp/pages/login_page.dart';
import 'package:todoapp/pages/schedule_page.dart';
import 'package:todoapp/pages/stats_page.dart';
import 'package:todoapp/services/auth_service.dart';
import 'package:todoapp/theme/app_colors.dart';
import 'package:todoapp/until/app_strings.dart';
import 'package:todoapp/until/main_bottom_bar.dart';

/// Khung chính của app sau khi đăng nhập: giữ dữ liệu dùng chung
/// (danh sách việc, màu giao diện, ngôn ngữ) và thanh điều hướng dưới.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _myBox = Hive.box('box_v3');
  final ToDoDaTaBase db = ToDoDaTaBase();
  late AppColorTheme _colorTheme;
  bool _isVietnamese = true;
  AppTab _current = AppTab.schedule;
  bool _pickerOpen = false;

  String translate(String text) => translateText(text, _isVietnamese);

  @override
  void initState() {
    super.initState();
    _colorTheme = AppColorTheme.fromId(_myBox.get('APP_COLOR_THEME'));
    _isVietnamese = _myBox.get('IS_VIETNAMESE', defaultValue: true) as bool;
    // tính năng ảnh nền đã bỏ: dọn ảnh cũ cho nhẹ bộ nhớ
    _myBox.delete('BACKGROUND_IMAGE_BYTES');
    if (!db.hasSavedData) {
      db.createInitialData();
    } else {
      db.loadData();
    }
  }

  void _selectTab(AppTab tab) {
    setState(() {
      _current = tab;
      _pickerOpen = false;
    });
  }

  void _toggleMode() {
    setState(() {
      _pickerOpen = !_pickerOpen;
    });
  }

  void _selectColorTheme(AppColorTheme theme) {
    setState(() {
      _colorTheme = theme;
    });
    _myBox.put('APP_COLOR_THEME', theme.id);
  }

  void _setLanguage(bool vietnamese) {
    setState(() {
      _isVietnamese = vietnamese;
    });
    _myBox.put('IS_VIETNAMESE', vietnamese);
  }

  Future<void> _logout() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorTheme.light,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Thứ tự các trang khớp với enum AppTab.
          IndexedStack(
            index: _current.index,
            children: [
              ComingSoonPage(
                title: translate('Cửa hàng âm thanh'),
                badge: translate('Sắp ra mắt'),
                message: translate('Cửa hàng âm thanh sẽ mở ở bước tiếp theo.'),
                icon: Icons.storefront,
                colorTheme: _colorTheme,
              ),
              ComingSoonPage(
                title: translate('Kho của tôi'),
                badge: translate('Sắp ra mắt'),
                message: translate('Nơi cất các âm thanh bạn đã mua sẽ ở đây.'),
                icon: Icons.inventory_2,
                colorTheme: _colorTheme,
              ),
              SchedulePage(
                db: db,
                translate: translate,
                colorTheme: _colorTheme,
              ),
              FocusPage(
                colorTheme: _colorTheme,
                isVietnamese: _isVietnamese,
                translate: translate,
              ),
              StatsPage(
                db: db,
                translate: translate,
                colorTheme: _colorTheme,
              ),
              AccountPage(
                colorTheme: _colorTheme,
                isVietnamese: _isVietnamese,
                translate: translate,
                onColorSelected: _selectColorTheme,
                onLanguageChanged: _setLanguage,
                onLogout: _logout,
              ),
            ],
          ),
          // Hai bong bóng chọn chế độ khi bấm nút giữa
          Positioned.fill(
            child: ModePickerOverlay(
              open: _pickerOpen,
              current: _current,
              colorTheme: _colorTheme,
              translate: translate,
              onSelect: _selectTab,
              onDismiss: () => setState(() => _pickerOpen = false),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MainBottomBar(
        current: _current,
        pickerOpen: _pickerOpen,
        colorTheme: _colorTheme,
        translate: translate,
        onTabSelected: _selectTab,
        onCenterTap: _toggleMode,
      ),
    );
  }
}