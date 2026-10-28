import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:todoapp/pages/home_page.dart';
import 'package:todoapp/pages/login_page.dart';
import 'package:todoapp/services/auth_service.dart';

void main() async {
  // khởi tạo Hive
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  await Hive.openBox('box_v3');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // đã đăng nhập thì vào thẳng danh sách việc, chưa thì vào trang đăng nhập
    final loggedIn = AuthService.instance.currentUsername != null;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Việc Cần Làm',
      home: loggedIn ? const HomePage() : const LoginPage(),
      theme: ThemeData(
        useMaterial3: true,
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}