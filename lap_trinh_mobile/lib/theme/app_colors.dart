import 'package:flutter/material.dart';

class AppColorTheme {
  final String id;
  final String labelVi;
  final String labelEn;
  final Color primary;
  final Color light;
  final Color dark;

  const AppColorTheme({
    required this.id,
    required this.labelVi,
    required this.labelEn,
    required this.primary,
    required this.light,
    required this.dark,
  });

  String label(bool isVietnamese) => isVietnamese ? labelVi : labelEn;

  static const String defaultId = 'yellow';

  static const List<AppColorTheme> themes = [
    AppColorTheme(
      id: 'yellow',
      labelVi: 'Vàng',
      labelEn: 'Yellow',
      primary: Color(0xFFFFEB3B),
      light: Color(0xFFFFF9C4),
      dark: Color(0xFFF9A825),
    ),
    AppColorTheme(
      id: 'blue',
      labelVi: 'Xanh dương',
      labelEn: 'Blue',
      primary: Color(0xFF42A5F5),
      light: Color(0xFFE3F2FD),
      dark: Color(0xFF1565C0),
    ),
    AppColorTheme(
      id: 'purple',
      labelVi: 'Tím',
      labelEn: 'Purple',
      primary: Color(0xFFAB47BC),
      light: Color(0xFFF3E5F5),
      dark: Color(0xFF6A1B9A),
    ),
    AppColorTheme(
      id: 'green',
      labelVi: 'Xanh lá',
      labelEn: 'Green',
      primary: Color(0xFF66BB6A),
      light: Color(0xFFE8F5E9),
      dark: Color(0xFF2E7D32),
    ),
    AppColorTheme(
      id: 'orange',
      labelVi: 'Cam',
      labelEn: 'Orange',
      primary: Color(0xFFFF9800),
      light: Color(0xFFFFF3E0),
      dark: Color(0xFFE65100),
    ),
    AppColorTheme(
      id: 'pink',
      labelVi: 'Hồng',
      labelEn: 'Pink',
      primary: Color(0xFFEC407A),
      light: Color(0xFFFCE4EC),
      dark: Color(0xFFC2185B),
    ),
    AppColorTheme(
      id: 'teal',
      labelVi: 'Xanh ngọc',
      labelEn: 'Teal',
      primary: Color(0xFF26A69A),
      light: Color(0xFFE0F2F1),
      dark: Color(0xFF00695C),
    ),
  ];

  static AppColorTheme fromId(String? id) {
    return themes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => themes.first,
    );
  }
}
