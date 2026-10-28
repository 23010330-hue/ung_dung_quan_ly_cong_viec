import 'package:flutter/material.dart';
import 'package:todoapp/theme/app_colors.dart';

/// Trang tạm cho các tính năng đang được xây dựng (cửa hàng, kho, tập trung).
class ComingSoonPage extends StatelessWidget {
  final String title;
  final String badge;
  final String message;
  final IconData icon;
  final AppColorTheme colorTheme;

  const ComingSoonPage({
    super.key,
    required this.title,
    required this.badge,
    required this.message,
    required this.icon,
    required this.colorTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorTheme.light,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorTheme.primary,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorTheme.dark.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, size: 44, color: colorTheme.dark),
              ),
              const SizedBox(height: 18),
              Text(
                badge,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorTheme.dark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}