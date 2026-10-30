import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todoapp/services/auth_service.dart';
import 'package:todoapp/theme/app_colors.dart';

/// Tên app hiển thị cạnh logo. Đổi ở đây là đổi cho cả hai trang.
const String kAppName = 'Việc Cần Làm';

/// Đường dẫn ảnh logo (tự thêm vào thư mục assets/images/).
const String kLogoAsset = 'assets/images/logo.jpg';

const Color kAuthTextColor = Color(0xFF2D2A26);

/// Lấy bảng màu người dùng đã chọn (lưu trong Hive).
AppColorTheme currentColorTheme() {
  final id = Hive.box('box_v3').get('APP_COLOR_THEME') as String?;
  return AppColorTheme.fromId(id);
}

class AuthValidators {
  static String? username(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Vui lòng nhập tên đăng nhập';
    if (value.length < 3 || value.length > 20) {
      return 'Tên đăng nhập dài từ 3 đến 20 ký tự';
    }
    if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(value)) {
      return 'Chỉ gồm chữ không dấu, số, dấu _ và .';
    }
    // tên đăng nhập được dùng làm id trên Firestore nên không được bắt đầu bằng _ hoặc .
    if (!RegExp(r'^[a-zA-Z0-9]').hasMatch(value)) {
      return 'Tên đăng nhập phải bắt đầu bằng chữ hoặc số';
    }
    return null;
  }

  static String? email(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Vui lòng nhập email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  static String? password(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (value.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
    return null;
  }

  static String? Function(String?) confirmPassword(
    TextEditingController original,
  ) {
    return (String? v) {
      if ((v ?? '').isEmpty) return 'Vui lòng nhập lại mật khẩu';
      if (v != original.text) return 'Mật khẩu xác nhận không khớp';
      return null;
    };
  }

  static String? required(String? v, String message) {
    if ((v ?? '').trim().isEmpty) return message;
    return null;
  }
}

/// Khung nền chung của các trang đăng nhập/đăng ký.
class AuthScaffold extends StatelessWidget {
  final AppColorTheme colorTheme;
  final Widget child;

  const AuthScaffold({
    super.key,
    required this.colorTheme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorTheme.light,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo bên trái, tên app bên phải.
class AuthHeader extends StatelessWidget {
  final AppColorTheme colorTheme;

  const AuthHeader({super.key, required this.colorTheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorTheme.dark.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              kLogoAsset,
              fit: BoxFit.cover,
              // chưa có ảnh logo thì hiện icon tạm
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.task_alt,
                size: 32,
                color: colorTheme.dark,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            kAppName,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: kAuthTextColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// Thẻ trắng bo góc chứa form.
class AuthCard extends StatelessWidget {
  final AppColorTheme colorTheme;
  final Widget child;

  const AuthCard({super.key, required this.colorTheme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorTheme.dark.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final AppColorTheme colorTheme;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final TextInputType keyboardType;
  final VoidCallback? onSubmitted;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.colorTheme,
    this.isPassword = false,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.keyboardType = TextInputType.text,
    this.onSubmitted,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscure = widget.isPassword;

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.colorTheme;
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      keyboardType: widget.keyboardType,
      onFieldSubmitted: (_) => widget.onSubmitted?.call(),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(color: Colors.grey[700]),
        floatingLabelStyle: TextStyle(color: theme.dark),
        prefixIcon: Icon(widget.icon, color: theme.dark),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[600],
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: _border(theme.primary),
        enabledBorder: _border(theme.primary),
        focusedBorder: _border(theme.dark, 1.5),
        errorBorder: _border(const Color(0xFFE57373)),
        focusedErrorBorder: _border(const Color(0xFFE57373), 1.5),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final AppColorTheme colorTheme;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.colorTheme,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorTheme.dark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colorTheme.dark.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

/// Hàng nút tròn Google / Facebook nằm dưới thẻ form.
class SocialButtonsRow extends StatelessWidget {
  final String caption;
  final bool enabled;
  final AppColorTheme colorTheme;
  final void Function(SocialProvider provider) onPressed;

  const SocialButtonsRow({
    super.key,
    required this.caption,
    required this.colorTheme,
    required this.onPressed,
    this.enabled = true,
  });

  Widget _circle({
    required SocialProvider provider,
    required String letter,
    required Color color,
    required String tooltip,
    double fontSize = 24,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? () => onPressed(provider) : null,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: colorTheme.primary, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            letter,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: enabled ? color : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(color: colorTheme.dark.withValues(alpha: 0.3)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                caption,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ),
            Expanded(
              child: Divider(color: colorTheme.dark.withValues(alpha: 0.3)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _circle(
              provider: SocialProvider.google,
              letter: 'G',
              color: const Color(0xFFDB4437),
              tooltip: 'Google',
            ),
            const SizedBox(width: 18),
            _circle(
              provider: SocialProvider.facebook,
              letter: 'f',
              color: const Color(0xFF1877F2),
              tooltip: 'Facebook',
              fontSize: 28,
            ),
          ],
        ),
      ],
    );
  }
}

/// Hộp thoại bắt đặt tên đăng nhập cho tài khoản Google/Facebook mới.
/// [onSubmit] trả về chuỗi lỗi (hộp thoại giữ nguyên) hoặc null nếu thành công.
Future<String?> showUsernameDialog(
  BuildContext context, {
  required AppColorTheme colorTheme,
  required Future<String?> Function(String username) onSubmit,
}) {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String? serverError;
  bool busy = false;

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: colorTheme.light,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Chọn tên đăng nhập',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: kAuthTextColor,
              ),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đây là lần đầu bạn dùng tài khoản này. '
                    'Hãy đặt một tên đăng nhập cho app.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: controller,
                    label: 'Tên đăng nhập',
                    icon: Icons.person_outline,
                    colorTheme: colorTheme,
                    validator: AuthValidators.username,
                    textInputAction: TextInputAction.done,
                  ),
                  if (serverError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        serverError!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.of(dialogContext).pop(),
                child: Text('Hủy', style: TextStyle(color: colorTheme.dark)),
              ),
              ElevatedButton(
                onPressed: busy
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final name = controller.text.trim();
                        setDialogState(() {
                          busy = true;
                          serverError = null;
                        });
                        final error = await onSubmit(name);
                        if (error == null) {
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop(name);
                          }
                        } else {
                          setDialogState(() {
                            busy = false;
                            serverError = error;
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorTheme.dark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Xác nhận'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Xử lý trọn quy trình đăng nhập/đăng ký bằng Google hoặc Facebook:
/// tài khoản đã có thì vào luôn, chưa có thì hỏi tên đăng nhập.
/// Trả về true nếu đã đăng nhập xong. Có thể ném [AuthException].
Future<bool> runSocialSignIn(
  BuildContext context,
  SocialProvider provider,
  AppColorTheme colorTheme,
) async {
  final result = await AuthService.instance.signInWithSocial(provider);
  if (!result.needsUsername) return true;
  if (!context.mounted) return false;

  final chosen = await showUsernameDialog(
    context,
    colorTheme: colorTheme,
    onSubmit: (name) async {
      try {
        await AuthService.instance.completeSocialProfile(name);
        return null;
      } on AuthException catch (e) {
        return e.message;
      }
    },
  );
  // bấm Hủy: đăng xuất luôn để không bị kẹt ở trạng thái đăng nhập dở dang
  if (chosen == null) await AuthService.instance.signOut();
  return chosen != null;
}

/// Hộp thoại "Quên mật khẩu": nhập tên đăng nhập hoặc email, app gửi thư đặt lại mật khẩu.
Future<void> showForgotPasswordDialog(
  BuildContext context, {
  required AppColorTheme colorTheme,
  String initialValue = '',
}) {
  final controller = TextEditingController(text: initialValue);
  final formKey = GlobalKey<FormState>();
  String? error;
  String? sentTo;
  bool busy = false;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> submit() async {
            if (!formKey.currentState!.validate()) return;
            setDialogState(() {
              busy = true;
              error = null;
            });
            try {
              final masked = await AuthService.instance.sendPasswordReset(
                controller.text.trim(),
              );
              setDialogState(() {
                busy = false;
                sentTo = masked;
              });
            } on AuthException catch (e) {
              setDialogState(() {
                busy = false;
                error = e.message;
              });
            }
          }

          final sent = sentTo != null;
          return AlertDialog(
            backgroundColor: colorTheme.light,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Quên mật khẩu',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: kAuthTextColor,
              ),
            ),
            content: sent
                ? Text(
                    'Đã gửi thư đặt lại mật khẩu tới $sentTo.\n\n'
                    'Mở thư, bấm vào đường link rồi đặt mật khẩu mới. '
                    'Nếu không thấy thư, hãy kiểm tra cả thư rác (spam).',
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  )
                : Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nhập tên đăng nhập hoặc email, app sẽ gửi thư '
                          'đặt lại mật khẩu cho bạn.',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 14),
                        AuthTextField(
                          controller: controller,
                          label: 'Tên đăng nhập hoặc email',
                          icon: Icons.person_outline,
                          colorTheme: colorTheme,
                          textInputAction: TextInputAction.done,
                          onSubmitted: submit,
                          validator: (v) => AuthValidators.required(
                            v,
                            'Vui lòng nhập tên đăng nhập hoặc email',
                          ),
                        ),
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              error!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFD32F2F),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
            actions: sent
                ? [
                    ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorTheme.dark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Đóng'),
                    ),
                  ]
                : [
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => Navigator.of(dialogContext).pop(),
                      child: Text(
                        'Hủy',
                        style: TextStyle(color: colorTheme.dark),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: busy ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorTheme.dark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Gửi thư'),
                    ),
                  ],
          );
        },
      );
    },
  );
}