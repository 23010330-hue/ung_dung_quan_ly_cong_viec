import 'package:flutter/material.dart';
import 'package:todoapp/pages/home_page.dart';
import 'package:todoapp/pages/register_page.dart';
import 'package:todoapp/services/auth_service.dart';
import 'package:todoapp/until/auth_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _colorTheme = currentColorTheme();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.signInWithUsername(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      _goHome();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _socialSignIn(SocialProvider provider) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ok = await runSocialSignIn(context, provider, _colorTheme);
      if (!mounted) return;
      if (ok) {
        _goHome();
      } else {
        setState(() => _loading = false);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      colorTheme: _colorTheme,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuthHeader(colorTheme: _colorTheme),
          const SizedBox(height: 28),
          AuthCard(
            colorTheme: _colorTheme,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đăng nhập',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kAuthTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: _usernameController,
                    label: 'Tên đăng nhập',
                    icon: Icons.person_outline,
                    colorTheme: _colorTheme,
                    validator: (v) => AuthValidators.required(
                      v,
                      'Vui lòng nhập tên đăng nhập',
                    ),
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _passwordController,
                    label: 'Mật khẩu',
                    icon: Icons.lock_outline,
                    colorTheme: _colorTheme,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: _login,
                    validator: (v) => AuthValidators.required(
                      v,
                      'Vui lòng nhập mật khẩu',
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  AuthPrimaryButton(
                    label: 'Đăng nhập',
                    loading: _loading,
                    colorTheme: _colorTheme,
                    onPressed: _login,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          SocialButtonsRow(
            caption: 'hoặc đăng nhập bằng',
            colorTheme: _colorTheme,
            enabled: !_loading,
            onPressed: _socialSignIn,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Chưa có tài khoản?',
                style: TextStyle(color: Colors.grey[800]),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RegisterPage(),
                        ),
                      ),
                child: Text(
                  'Tạo tài khoản',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _colorTheme.dark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}