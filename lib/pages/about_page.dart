import 'package:flutter/material.dart';
import 'package:todoapp/theme/app_colors.dart';

class AboutPage extends StatelessWidget {
  final String Function(String) translate;
  final AppColorTheme colorTheme;

  const AboutPage({
    super.key,
    required this.translate,
    required this.colorTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorTheme.light,
      appBar: AppBar(
        title: Text(translate('Giới thiệu')),
        backgroundColor: colorTheme.primary,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorTheme.primary.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group, size: 50, color: colorTheme.dark),
              const SizedBox(height: 10),
              Text(
                translate('Thông tin nhóm'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${translate('Tên nhóm:')} Nhóm 12',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${translate('Thành viên:')}\n1. Lê Văn Tuấn - 23010330',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}