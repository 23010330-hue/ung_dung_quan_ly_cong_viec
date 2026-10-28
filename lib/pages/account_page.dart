import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:todoapp/services/auth_service.dart';
import 'package:todoapp/services/profile_service.dart';
import 'package:todoapp/theme/app_colors.dart';
import 'package:todoapp/until/user_avatar.dart';

/// Tài khoản: ảnh đại diện, màu giao diện, ngôn ngữ, đăng xuất.
class AccountPage extends StatefulWidget {
  final AppColorTheme colorTheme;
  final bool isVietnamese;
  final String Function(String) translate;
  final ValueChanged<AppColorTheme> onColorSelected;
  final ValueChanged<bool> onLanguageChanged;
  final Future<void> Function() onLogout;

  const AccountPage({
    super.key,
    required this.colorTheme,
    required this.isVietnamese,
    required this.translate,
    required this.onColorSelected,
    required this.onLanguageChanged,
    required this.onLogout,
  });

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  static const _textColor = Color(0xFF2D2A26);

  final _picker = ImagePicker();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  Uint8List? _avatar;

  AppColorTheme get _theme => widget.colorTheme;
  String Function(String) get translate => widget.translate;

  String get _username => AuthService.instance.currentUsername ?? '';

  @override
  void initState() {
    super.initState();
    _avatar = ProfileService.loadAvatar();
  }

  Future<void> _pickAvatar() async {
    try {
      // thu nhỏ ngay khi chọn để ảnh nhẹ (vài chục KB)
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 80,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      await ProfileService.saveAvatar(bytes);
      if (!mounted) return;
      setState(() => _avatar = bytes);
    } catch (_) {
      if (!mounted) return;
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(translate('Không thể chọn ảnh này'))),
      );
    }
  }

  Future<void> _removeAvatar() async {
    await ProfileService.removeAvatar();
    if (!mounted) return;
    setState(() => _avatar = null);
  }

  void _showAvatarOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _theme.light,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: _theme.dark),
                title: Text(
                  translate('Chọn ảnh mới'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickAvatar();
                },
              ),
              if (_avatar != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFD32F2F),
                  ),
                  title: Text(
                    translate('Xóa ảnh đại diện'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _removeAvatar();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _theme.light,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            translate('Đăng xuất'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          content: Text(translate('Bạn muốn đăng xuất khỏi tài khoản?')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                translate('Hủy'),
                style: TextStyle(color: _theme.dark),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE57373),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(translate('Đăng xuất')),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await widget.onLogout();
    }
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _theme.dark.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: _textColor,
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return _card(
      child: Column(
        children: [
          GestureDetector(
            onTap: _showAvatarOptions,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatar(
                  bytes: _avatar,
                  name: _username,
                  radius: 52,
                  colorTheme: _theme,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _theme.dark,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _username,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            translate('Chọn ảnh mới'),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildColorCard() {
    return _card(
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        alignment: WrapAlignment.center,
        children: AppColorTheme.themes.map((theme) {
          final isSelected = theme.id == _theme.id;
          return GestureDetector(
            onTap: () => widget.onColorSelected(theme),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: theme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? theme.dark : Colors.white,
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.dark.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? Icon(Icons.check, color: theme.dark)
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  theme.label(widget.isVietnamese),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLanguageCard() {
    Widget chip(String label, bool vietnamese) {
      final selected = widget.isVietnamese == vietnamese;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: _theme.primary,
        backgroundColor: Colors.white,
        side: BorderSide(color: _theme.primary),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: selected ? _theme.dark : _textColor,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (_) => widget.onLanguageChanged(vietnamese),
      );
    }

    return _card(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          chip('Tiếng Việt', true),
          const SizedBox(width: 12),
          chip('English', false),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: _theme.light,
        appBar: AppBar(
          title: Text(
            translate('Tài khoản'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: _theme.primary,
          foregroundColor: Colors.black,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _buildProfileCard(),
            _sectionTitle(translate('Đổi màu giao diện')),
            _buildColorCard(),
            _sectionTitle(translate('Ngôn ngữ')),
            _buildLanguageCard(),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout, color: Color(0xFFD32F2F)),
                label: Text(
                  translate('Đăng xuất'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD32F2F),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE57373)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}