import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart' show Hive;
import 'package:todoapp/data/database.dart';
import 'package:todoapp/focus/focus_audio.dart';
import 'package:todoapp/focus/focus_page.dart';
import 'package:todoapp/pages/account_page.dart';
import 'package:todoapp/pages/login_page.dart';
import 'package:todoapp/pages/schedule_page.dart';
import 'package:todoapp/pages/stats_page.dart';
import 'package:todoapp/services/auth_service.dart';
import 'package:todoapp/services/cloud_sync.dart';
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

  bool _ready = false;

  // Chỉ tạo sau khi đã đồng bộ xong, vì đĩa đang chọn được lưu theo tài khoản.
  FocusAudio? _audioOrNull;
  FocusAudio get _audio => _audioOrNull ??= FocusAudio();

  String translate(String text) => translateText(text, _isVietnamese);

  @override
  void initState() {
    super.initState();
    _colorTheme = AppColorTheme.fromId(_myBox.get('APP_COLOR_THEME'));
    _boot();
  }

  Future<void> _boot() async {
    await CloudSync.instance.start();
    if (!mounted) return;

    _colorTheme = AppColorTheme.fromId(_myBox.get('APP_COLOR_THEME'));
    _isVietnamese = _myBox.get('IS_VIETNAMESE', defaultValue: true) as bool;
    _myBox.delete('BACKGROUND_IMAGE_BYTES');
    if (!db.hasSavedData) {
      db.createInitialData();
    } else {
      db.loadData();
    }
    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _audioOrNull?.dispose();
    super.dispose();
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
    await CloudSync.instance.stop();
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
        backgroundColor: _colorTheme.light,
        body: Center(child: CircularProgressIndicator(color: _colorTheme.dark)),
      );
    }

    return Scaffold(
      backgroundColor: _colorTheme.light,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Thứ tự các trang khớp với enum AppTab.
          IndexedStack(
            index: _current.index,
            children: [
              SchedulePage(
                db: db,
                translate: translate,
                colorTheme: _colorTheme,
              ),
              FocusPage(
                colorTheme: _colorTheme,
                translate: translate,
                audio: _audio,
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