import 'package:flutter/material.dart';

/// Ô chọn dùng chung cho mọi kiểu dữ liệu [T] (String, int, enum, ...).
///
/// Ví dụ:
///   AppDropdown<String>(value: 'Ngày', items: ['Ngày', 'Tuần'], ...)
///   AppDropdown<int>(value: 1, items: [1, 2, 3], labelBuilder: (n) => 'Mức $n', ...)
class AppDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;

  /// Chuyển một phần tử kiểu T thành chữ hiển thị (ví dụ dịch sang tiếng Anh).
  final String Function(T item) labelBuilder;
  final ValueChanged<T?> onChanged;
  final Color? dropdownColor;
  final Widget? icon;
  final TextStyle? textStyle;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    this.dropdownColor,
    this.icon,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        dropdownColor: dropdownColor,
        borderRadius: BorderRadius.circular(12),
        icon: icon ?? const Icon(Icons.arrow_drop_down),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(labelBuilder(item), style: textStyle),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}