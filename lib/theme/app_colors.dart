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
      primary: Color(0xFFF5D76E), // vàng bơ
      light: Color(0xFFFFF8E1),
      dark: Color(0xFFB8892B),
    ),
    AppColorTheme(
      id: 'blue',
      labelVi: 'Xanh dương',
      labelEn: 'Blue',
      primary: Color(0xFF8DBBE0), // xanh da trời nhạt
      light: Color(0xFFEAF4FB),
      dark: Color(0xFF3F7CA8),
    ),
    AppColorTheme(
      id: 'purple',
      labelVi: 'Tím',
      labelEn: 'Purple',
      primary: Color(0xFFB9A6DE), // tím oải hương
      light: Color(0xFFF1ECF9),
      dark: Color(0xFF7561AD),
    ),
    AppColorTheme(
      id: 'green',
      labelVi: 'Xanh lá',
      labelEn: 'Green',
      primary: Color(0xFF9CCBA8), // xanh bạc hà
      light: Color(0xFFEDF6EF),
      dark: Color(0xFF4F8A63),
    ),
    AppColorTheme(
      id: 'orange',
      labelVi: 'Cam',
      labelEn: 'Orange',
      primary: Color(0xFFF2B98A), // cam đào
      light: Color(0xFFFDF1E5),
      dark: Color(0xFFC2763A),
    ),
    AppColorTheme(
      id: 'pink',
      labelVi: 'Hồng',
      labelEn: 'Pink',
      primary: Color(0xFFEBAEC0), // hồng phấn
      light: Color(0xFFFCEEF2),
      dark: Color(0xFFB5586F),
    ),
    AppColorTheme(
      id: 'teal',
      labelVi: 'Xanh ngọc',
      labelEn: 'Teal',
      primary: Color(0xFF8CCAC3), // xanh ngọc nhạt
      light: Color(0xFFE8F5F3),
      dark: Color(0xFF3F8F89),
    ),
  ];

  static AppColorTheme fromId(String? id) {
    return themes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => themes.first,
    );
  }
}