import 'package:flutter/material.dart';
import 'package:todoapp/pages/home_page.dart';
import 'package:todoapp/services/auth_service.dart';
import 'package:todoapp/until/auth_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _colorTheme = currentColorTheme();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.signUp(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
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
                    'Tạo tài khoản',
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
                    validator: AuthValidators.username,
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    colorTheme: _colorTheme,
                    keyboardType: TextInputType.emailAddress,
                    validator: AuthValidators.email,
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _passwordController,
                    label: 'Mật khẩu',
                    icon: Icons.lock_outline,
                    colorTheme: _colorTheme,
                    isPassword: true,
                    validator: AuthValidators.password,
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _confirmController,
                    label: 'Xác nhận mật khẩu',
                    icon: Icons.lock_reset,
                    colorTheme: _colorTheme,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: _register,
                    validator: AuthValidators.confirmPassword(
                      _passwordController,
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
                    label: 'Tạo tài khoản',
                    loading: _loading,
                    colorTheme: _colorTheme,
                    onPressed: _register,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          SocialButtonsRow(
            caption: 'hoặc đăng ký nhanh bằng',
            colorTheme: _colorTheme,
            enabled: !_loading,
            onPressed: _socialSignIn,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Đã có tài khoản?',
                style: TextStyle(color: Colors.grey[800]),
              ),
              TextButton(
                onPressed: _loading ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'Đăng nhập',
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