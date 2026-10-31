import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:todoapp/theme/app_colors.dart';

/// Ảnh đại diện tròn. Chưa có ảnh thì hiện chữ cái đầu của tên đăng nhập.
class UserAvatar extends StatelessWidget {
  final Uint8List? bytes;
  final String name;
  final double radius;
  final AppColorTheme colorTheme;

  const UserAvatar({
    super.key,
    required this.bytes,
    required this.name,
    required this.colorTheme,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final data = bytes;
    if (data != null && data.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: colorTheme.light,
        backgroundImage: MemoryImage(data),
      );
    }
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: colorTheme.primary,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.9,
          fontWeight: FontWeight.bold,
          color: colorTheme.dark,
        ),
      ),
    );
  }
}