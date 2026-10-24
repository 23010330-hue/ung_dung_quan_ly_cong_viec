import 'package:flutter/material.dart';

/// Ô nhập tìm kiếm hiển thị trên thanh tiêu đề (AppBar).
class TaskSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const TaskSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      cursorColor: Colors.black87,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.black54,
        ),
        border: InputBorder.none,
      ),
    );
  }
}