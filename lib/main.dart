import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:todoapp/firebase_options.dart';
import 'package:todoapp/pages/home_page.dart';
import 'package:todoapp/pages/login_page.dart';
import 'package:todoapp/services/auth_service.dart';
import 'package:todoapp/services/firebase_auth_service.dart';

void main() async {
  // khởi tạo Hive
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  await Hive.openBox('box_v3');

  // nối Firebase (firebase_options.dart do `flutterfire configure` tạo ra)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final auth = FirebaseAuthService();
    await auth.restore();
    AuthService.instance = auth;
  } catch (e) {
    runApp(_FirebaseErrorApp(error: e));
    return;
  }

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

/// Hiện khi đã cấu hình Firebase nhưng không khởi tạo được (sai cấu hình, mất mạng...).
class _FirebaseErrorApp extends StatelessWidget {
  final Object error;

  const _FirebaseErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SelectableText(
              'Không kết nối được Firebase.\n\n'
              'Kiểm tra lại các giá trị trong lib/firebase_options.dart '
              'và kết nối mạng.\n\nChi tiết: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}